---@class addonTableChatanator
local addonTable = select(2, ...)

Chatanator = {
  API = {},
}

function Chatanator.API.SetFilter(filterFunc)
  addonTable.ChatFrame:SetFilter(filterFunc)
  addonTable.ChatFrame:Render()
end
