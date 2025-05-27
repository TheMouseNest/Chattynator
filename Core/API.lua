---@class addonTableChattynator
local addonTable = select(2, ...)

Chattynator = {
  API = {},
}

function Chattynator.API.GetHyperlinkHandler()
  return ChattynatorHyperlinkHandler
end
