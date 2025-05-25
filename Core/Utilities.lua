---@class addonTableChattynator
local addonTable = select(2, ...)

function addonTable.Utilities.Message(text)
  addonTable.Messages:SetIncomingType({type = "ADDON", event = "NONE", source = "CHATTYNATOR"})
  addonTable.Messages:AddMessage("|cffea7ed8" .. addonTable.Locales.CHATTYNATOR .. "|r: " .. text)
end
