---@class addonTableChatanator
local addonTable = select(2, ...)

local customisers = {}

function addonTable.CustomiseDialog.GetTabCustomiser(tabIndex)
  if customisers[tabIndex] then
    customisers[tabIndex]:Show()
    return
  end
  local frame = CreateFrame("Frame", "ChatanatorTabCustomiser" .. tabIndex, UIParent, "ButtonFrameTemplate")
end
