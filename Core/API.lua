---@class addonTableChattynator
local addonTable = select(2, ...)

Chattynator = {
  API = {},
}

function Chattynator.API.GetHyperlinkHandler()
  return ChattynatorHyperlinkHandler
end

local funcToWrapper = {
}
-- TODO: Test this
function Chattynator.API.AddDynamicFilter(func)
  local wrapper
  wrapper = function(data)
    local state = xpcall(function() func(data) end, CallErrorHandler)
    if not state then
      Chattynator.API.RemoveDynamicFilter(wrapper)
    end
  end
  funcToWrapper[func] = wrapper
  addonTable.Messages.AddLiveModifier(wrapper)
end

function Chattynator.API.RemoveDynamicFilter(func)
  if funcToWrapper[func] then
    addonTable.Messages.RemoveLiveModifier(funcToWrapper[func])
    funcToWrapper[func] = nil
  end
end
