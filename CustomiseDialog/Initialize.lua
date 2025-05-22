---@class addonTableChatanator
local addonTable = select(2, ...)

local customisers = {}

function addonTable.CustomiseDialog.Toggle()
  if customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)] then
    customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)]:Show()
    return
  end
  local frame = CreateFrame("Frame", "ChatanatorTabCustomiser" .. addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN), UIParent, "ButtonFrameTemplate")
  frame:SetToplevel(true)
  customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)] = frame
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
