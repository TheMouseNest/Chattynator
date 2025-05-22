---@class addonTableChatanator
local addonTable = select(2, ...)

local customisers = {}
local currentTab = 1
addonTable.CallbackRegistry:RegisterCallback("TabSelected", function(_, windowIndex, tabIndex)
  currentTab = tabIndex
  local frame = customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)]
  if frame and frame:IsShown() then
    frame.filters:ShowSettings(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[1].tabs[currentTab])
  end
end)

function addonTable.CustomiseDialog.Toggle()
  if customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)] then
    local frame = customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)]
    frame:SetShown(not frame:IsVisible())
    if frame:IsShown() then
      frame.filters:ShowSettings(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[1].tabs[currentTab])
    end
    return
  end

  local frame = CreateFrame("Frame", "ChatanatorCustomiseDialog" .. addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN), UIParent, "ButtonFrameTemplate")
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

  frame:SetTitle(addonTable.Locales.CUSTOMISE_CHATANATOR)

  local filters = addonTable.CustomiseDialog.SetupTabFilters(frame)
  filters:SetPoint("TOPLEFT", 0, -50)
  filters:SetPoint("BOTTOMRIGHT")
  filters:Show()

  frame.filters = filters

  filters:ShowSettings(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[1].tabs[currentTab])
end
