---@class addonTableChatanator
local addonTable = select(2, ...)

local customisers = {}
local filtersToRefresh = {}
addonTable.CallbackRegistry:RegisterCallback("TabSelected", function(_, windowIndex, tabIndex)
  for _, frame in ipairs(filtersToRefresh) do
    if frame and frame:IsShown() and windowIndex == 1 then
      frame:ShowSettings(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[1].tabs[addonTable.allChatFrames[1].tabIndex])
    end
  end
end)

local function SetupGeneral(parent)
  local container = CreateFrame("Frame", nil, parent)

  local showCombatLog = addonTable.CustomiseDialog.Components.GetCheckbox(container, addonTable.Locales.SHOW_COMBAT_LOG, 20, function(state)
    addonTable.Config.Set(addonTable.Config.Options.SHOW_COMBAT_LOG, state)
  end)

  local locked = addonTable.CustomiseDialog.Components.GetCheckbox(container, addonTable.Locales.LOCKED, 20, function(state)
    addonTable.Config.Set(addonTable.Config.Options.LOCKED, state)
  end)

  container:SetScript("OnShow", function()
    showCombatLog:SetValue(addonTable.Config.Get(addonTable.Config.Options.SHOW_COMBAT_LOG))
    locked:SetValue(addonTable.Config.Get(addonTable.Config.Options.LOCKED))
  end)

  showCombatLog:SetPoint("TOP", 0, 0)
  locked:SetPoint("TOP", showCombatLog, "BOTTOM")

  return container
end

local function SetupFilters(parent)
  local filters = addonTable.CustomiseDialog.SetupTabFilters(parent)

  table.insert(filtersToRefresh, filters)

  filters:ShowSettings(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[1].tabs[addonTable.allChatFrames[1].tabIndex])

  return filters
end

local TabSetups = {
  {name = GENERAL, callback = SetupGeneral},
  {name = FILTERS, callback = SetupFilters},
}

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

  local containers = {}
  local lastTab
  local Tabs = {}
  for _, setup in ipairs(TabSetups) do
    local tabContainer = setup.callback(frame)
    tabContainer:SetPoint("TOPLEFT", 0 + addonTable.Constants.ButtonFrameOffset, -65)
    tabContainer:SetPoint("BOTTOMRIGHT")

    local tabButton = addonTable.CustomiseDialog.Components.GetTab(frame)
    if lastTab then
      tabButton:SetPoint("LEFT", lastTab, "RIGHT", 5, 0)
    else
      tabButton:SetPoint("TOPLEFT", 0 + addonTable.Constants.ButtonFrameOffset, -25)
    end
    lastTab = tabButton
    tabContainer.button = tabButton
    tabButton:SetScript("OnClick", function()
      for _, c in ipairs(containers) do
        PanelTemplates_DeselectTab(c.button)
        c:Hide()
      end
      PanelTemplates_SelectTab(tabButton)
      tabContainer:Show()
    end)
    tabButton:SetText(setup.name)
    tabContainer:Hide()

    table.insert(Tabs, tabButton)
    table.insert(containers, tabContainer)
  end
  frame.Tabs = Tabs
  PanelTemplates_SetNumTabs(frame, #frame.Tabs)
  containers[1].button:Click()
end
