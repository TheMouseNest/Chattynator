---@class addonTableChattynator
local addonTable = select(2, ...)

Chattynator = {
  API = {},
}

function Chattynator.API.GetHyperlinkHandler()
  return ChattynatorHyperlinkHandler
end

local dynamicModFuncToWrapper = {}
-- TODO: Test this
function Chattynator.API.AddDynamicFilter(func)
  local wrapper
  wrapper = function(data)
    local state = xpcall(function() func(data) end, CallErrorHandler)
    if not state then
      Chattynator.API.RemoveDynamicFilter(wrapper)
    end
  end
  dynamicModFuncToWrapper[func] = wrapper
  addonTable.Messages.AddLiveModifier(wrapper)
end

function Chattynator.API.RemoveDynamicFilter(func)
  if dynamicModFuncToWrapper[func] then
    addonTable.Messages.RemoveLiveModifier(dynamicModFuncToWrapper[func])
    dynamicModFuncToWrapper[func] = nil
  end
end

addonTable.API.RejectionFilters = {}

local rejectionFuncToWrapper = {}
function Chattynator.API.AddRejectionFilter(func, windowIndex, tabIndex)
  if not addonTable.API.RejectionFilters[windowIndex] then
    addonTable.API.RejectionFilters[windowIndex] = {}
    rejectionFuncToWrapper[windowIndex] = {}
  end
  if not addonTable.API.RejectionFilters[windowIndex][tabIndex] then
    addonTable.API.RejectionFilters[windowIndex][tabIndex] = {}
    rejectionFuncToWrapper[windowIndex][tabIndex] = {}
  end

  local wrapper = rejectionFuncToWrapper[windowIndex][tabIndex][func]
  if not wrapper then
    wrapper = function(data)
      local state, value = xpcall(function() return func(data) end, CallErrorHandler)
      if not state then
        Chattynator.API.RemoveRejectionFilter(func, windowIndex, tabIndex)
        return true
      else
        return value
      end
    end
    rejectionFuncToWrapper[windowIndex][tabIndex][func] = wrapper

    table.insert(addonTable.API.RejectionFilters[windowIndex][tabIndex], wrapper)

    addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
  end
end

function Chattynator.API.RemoveRejectionFilter(func, windowIndex, tabIndex)
  if not addonTable.API.RejectionFilters[windowIndex] then
    addonTable.API.RejectionFilters[windowIndex] = {}
  end
  if not addonTable.API.RejectionFilters[windowIndex][tabIndex] then
    addonTable.API.RejectionFilters[windowIndex][tabIndex] = {}
  end
  local wrapper = rejectionFuncToWrapper[windowIndex][tabIndex][func]
  if wrapper then
    local index = tIndexOf(addonTable.API.RejectionFilters[windowIndex][tabIndex], wrapper)
    if index then
      table.remove(addonTable.API.RejectionFilters[windowIndex][tabIndex], index)
      addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
    end
    rejectionFuncToWrapper[windowIndex][tabIndex][func] = nil
  end
end

function Chattynator.API.FilterTimePlayed(state)
  if state then
    addonTable.Messages:UnregisterEvent("TIME_PLAYED_MSG")
  else
    addonTable.Messages:RegisterEvent("TIME_PLAYED_MSG")
  end
end
