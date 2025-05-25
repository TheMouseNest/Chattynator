---@class addonTableChattynator
local addonTable = select(2, ...)

Chattynator = {
  API = {},
}

function Chattynator.API.SetFilter(filterFunc)
  addonTable.ChatFrame:SetFilter(filterFunc)
  addonTable.ChatFrame:Render()
end
