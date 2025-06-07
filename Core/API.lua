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

-- Permits non-destructive (ie backing data is unaffected) modification
-- of messages before display.
---@param func function(data)
function Chattynator.API.AddDynamicModifier(func)
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

---@param func function(data)
function Chattynator.API.RemoveDynamicModifier(func)
  if dynamicModFuncToWrapper[func] then
    addonTable.Messages.RemoveLiveModifier(dynamicModFuncToWrapper[func])
    dynamicModFuncToWrapper[func] = nil
  end
end

addonTable.API.RejectionFilters = {}

local rejectionFuncToWrapper = {}
-- Have the `func` return false to reject the message, return true to accept.
-- Returning nothing will cause the message to be rejected.
-- This is non-destructive, messages will still be stored in backing data normally.
---@param func function(data) -> boolean
---@param windowIndex number
---@param tabIndex number
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

---@param func function(data)
---@param windowIndex number
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

---@param state boolean
function Chattynator.API.FilterTimePlayed(state)
  if state then
    addonTable.Messages:UnregisterEvent("TIME_PLAYED_MSG")
  else
    addonTable.Messages:RegisterEvent("TIME_PLAYED_MSG")
  end
end
