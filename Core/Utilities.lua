---@class addonTableChatanator
local addonTable = select(2, ...)

function addonTable.Utilities.Message(text)
  addonTable.Messages:AddMessage("|cffea7ed8" .. addonTable.Locales.CHATANATOR .. "|r: " .. text)
end
