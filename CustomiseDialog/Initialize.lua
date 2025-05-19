---@class addonTableChatanator
local addonTable = select(2, ...)

local customisers = {}

function addonTable.CustomiseDialog.GetTabCustomiser(tabIndex)
  if customisers[tabIndex] then
    customisers[tabIndex]:Show()
    return
  end
  local frame = CreateFrame("Frame", "ChatanatorTabCustomiser" .. tabIndex, UIParent, "ButtonFrameTemplate")
  frame:SetToplevel(true)
  customisers[tabIndex] = frame
  table.insert(UISpecialFrames, frame:GetName())
  frame:SetSize(800, 700)
  frame:SetPoint("CENTER")
  frame:Raise()

  ButtonFrameTemplate_HidePortrait(frame)
  ButtonFrameTemplate_HideButtonBar(frame)
  frame.Inset:Hide()
  frame:EnableMouse(true)
  frame:SetScript("OnMouseWheel", function() end)
end
