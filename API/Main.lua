---@class addonTableChattynator
local addonTable = select(2, ...)

Chattynator = {
  API = {},
}

function Chattynator.API.GetHyperlinkHandler()
  return ChattynatorHyperlinkHandler
end

local dynamicModFuncToWrapper = {}
local dynamicModFuncQueue = {}

-- Permits non-destructive (ie backing data is unaffected) modification
-- of messages before display.
---@param func function(data)
function Chattynator.API.AddModifier(func)
  local wrapper
  wrapper = function(data)
    local state = xpcall(function() func(data) end, CallErrorHandler)
    if not state then
      Chattynator.API.RemoveModifier(func)
    end
  end
  dynamicModFuncToWrapper[func] = wrapper
  if not addonTable.Messages then
    table.insert(dynamicModFuncQueue, wrapper)
  else
    addonTable.Messages:AddLiveModifier(wrapper)
  end
end

---@param func function(data)
function Chattynator.API.RemoveModifier(func)
  if not addonTable.Messages then
    local index = tIndexOf(dynamicModFuncQueue, dynamicModFuncToWrapper[func])
    if index then
      table.remove(dynamicModFuncQueue, index)
    end
    dynamicModFuncToWrapper[func] = nil
    return
  end

  if dynamicModFuncToWrapper[func] then
    addonTable.Messages:RemoveLiveModifier(dynamicModFuncToWrapper[func])
    dynamicModFuncToWrapper[func] = nil
  end
end

---@param id string
function Chattynator.API.InvalidateMessage(id)
  assert(type(id) == "string")
  addonTable.Messages:InvalidateProcessedMessage(id)
end

addonTable.API.RejectionFilters = {}

local rejectionFuncToWrapper = {}
-- Have the `func` return false to reject the message, return true to accept.
-- Returning nothing will cause the message to be rejected.
-- This is non-destructive, messages will still be stored in backing data normally.
---@param func function(data) -> boolean
---@param windowIndex number
---@param tabIndex number
function Chattynator.API.AddFilter(func, windowIndex, tabIndex)
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
        Chattynator.API.RemoveFilter(func, windowIndex, tabIndex)
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
function Chattynator.API.RemoveFilter(func, windowIndex, tabIndex)
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


function Chattynator.API.GetWindowsAndTabs()
  local windows = {}
  for index, w in ipairs(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)) do
    table.insert(windows, {})
    for _, t in ipairs(w.tabs) do
      table.insert(windows[index], t.name)
    end
  end
  return windows
end

---@param windowIndex number
---@param tabIndex number
---@param message string
---@param r number?
---@param g number?
---@param b number?
function Chattynator.API.AddMessageToWindowAndTab(windowIndex, tabIndex, message, r, g, b)
  if not addonTable.Messages then
    print(message)
  end
  local addonPath = debugstack(2, 1, 0)
  local source = addonPath:match("Interface/AddOns/([^/]+)/")
  if addonPath:find("/[Ll]ibs?/Ace") then
    source = "/aceconsole"
  elseif source == nil then
    source = "/loadstring"
  end
  addonTable.Messages:SetIncomingType({type = "ADDON", event = "NONE", source = source, tabTag = windowIndex .. "_" .. tabIndex})
  addonTable.Messages:AddMessage(message, r, g, b)
end

addonTable.API.CustomTabs = {}

---@param label string
---@param id string
---@param installCallback function(parent) Note: Must be safe to be called multiple times on different parents
function Chattynator.API.RegisterCustomTab(label, id, installCallback)
  addonTable.API.CustomTabs[id] = { label = label, install = installCallback }
end

function addonTable.API.Initialize()
  for _, func in ipairs(dynamicModFuncQueue) do
    addonTable.Messages:AddLiveModifier(func)
  end
end
