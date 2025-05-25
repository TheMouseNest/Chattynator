---@class addonTableChattynator
local addonTable = select(2, ...)

function addonTable.Core.GetTabsPool(parent)
  return CreateFramePool("Button", parent, nil, nil, false,
    function(tabButton)
      tabButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
      tabButton:RegisterForDrag("LeftButton")
      tabButton:SetScript("OnDragStart", function()
        if not addonTable.Config.Get(addonTable.Config.Options.LOCKED) then
          parent:StartMoving()
        end
      end)
      tabButton:SetScript("OnDragStop", function()
        parent:StopMovingOrSizing()
        parent:SavePosition()
      end)
      function tabButton:SetSelected(state)
        self.selected = state
      end
      function tabButton:SetColor(r, g, b)
        self.color = {r = r, g = g, b = b}
      end
      addonTable.Skins.AddFrame("ChatTab", tabButton)
    end
  )
end

local function DisableCombatLog(chatFrame)
  ChatFrame2:SetParent(addonTable.hiddenFrame)
  chatFrame.ScrollBox:Show()
end

function addonTable.Core.InitializeTabs(chatFrame)
  if not chatFrame.tabsPool then
    chatFrame.tabsPool = addonTable.Core.GetTabsPool(chatFrame)
  else -- Might have shown combat log at some point
    DisableCombatLog(chatFrame)
  end
  chatFrame.tabsPool:ReleaseAll()
  local allTabs = {}
  local lastButton
  for index, tab in ipairs(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[chatFrame:GetID()].tabs) do
    local button = chatFrame.tabsPool:Acquire()
    button.minWidth = false
    button:SetID(index)
    button:Show()
    button:SetText(_G[tab.name] or tab.name or UNKNOWN)
    local tabColor = CreateColorFromRGBHexString(tab.tabColor)
    local bgColor = CreateColorFromRGBHexString(tab.backgroundColor)
    local filter
    if tab.invert then
      filter = function(data)
        return tab.groups[data.typeInfo.type] ~= false and
          (
          not data.typeInfo.channel or
          (tab.channels[data.typeInfo.channel.name] == nil and data.typeInfo.channel.isDefault) or
          tab.channels[data.typeInfo.channel.name]
        ) and tab.whispersTemp[data.typeInfo.player] ~= false
      end
    else
      filter = function(data)
        return tab.groups[data.typeInfo.type] or
          data.typeInfo.player and tab.whispersTemp[data.typeInfo.player] or
          tab.channels[data.typeInfo.channel and data.typeInfo.channel.name]
      end
    end
    button.filter = filter
    button.bgColor = bgColor
    button:SetScript("OnClick", function(_, mouseButton)
      if chatFrame:GetID() == 1 then
        DisableCombatLog(chatFrame)
      end
      if mouseButton == "LeftButton" then
        chatFrame:SetFilter(filter)
        chatFrame:SetBackgroundColor(bgColor.r, bgColor.g, bgColor.b)
        chatFrame:SetTabSelected(button:GetID())
        chatFrame:Render()
        for _, otherTab in ipairs(allTabs) do
          otherTab:SetSelected(false)
        end
        button:SetSelected(true)
        addonTable.CallbackRegistry:TriggerEvent("TabSelected", chatFrame:GetID(), button:GetID())
      elseif mouseButton == "RightButton" and (tab.isTemporary or not addonTable.Config.Get(addonTable.Config.Options.LOCKED)) then
        MenuUtil.CreateContextMenu(button, function(menu, rootDescription)
          rootDescription:CreateButton(CLOSE, function()
            table.remove(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[chatFrame:GetID()].tabs, index)
            addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
          end)
        end)
      end
    end)

    if lastButton == nil then
      button:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", 32, -22)
    else
      button:SetPoint("LEFT", lastButton, "RIGHT", 10, 0)
    end
    button:SetColor(tabColor.r, tabColor.g, tabColor.b)
    table.insert(allTabs, button)
    lastButton = button
  end

  if chatFrame:GetID() == 1 and addonTable.Config.Get(addonTable.Config.Options.SHOW_COMBAT_LOG) then
    local combatLogButton = chatFrame.tabsPool:Acquire()
    combatLogButton.minWidth = false
    combatLogButton:SetID(#allTabs + 1)
    combatLogButton:Show()
    combatLogButton:SetText(COMBAT_LOG)
    combatLogButton:SetScript("OnClick", function(_, mouseButton)
      if mouseButton == "LeftButton" then
        for _, otherTab in ipairs(allTabs) do
          otherTab:SetSelected(false)
        end
        chatFrame:SetBackgroundColor(0.15, 0.15, 0.15)
        combatLogButton:SetSelected(true)
        chatFrame.ScrollBox:Hide()
        CombatLogQuickButtonFrame_Custom:SetParent(ChatFrame2)
        CombatLogQuickButtonFrame_Custom:ClearAllPoints()
        CombatLogQuickButtonFrame_Custom:SetPoint("TOPLEFT", chatFrame.ScrollBox, 0, 0)
        CombatLogQuickButtonFrame_Custom:SetPoint("TOPRIGHT", chatFrame.ScrollBox, 0, 0)
        ChatFrame2:SetParent(chatFrame)
        ChatFrame2:ClearAllPoints()
        ChatFrame2:SetPoint("TOPLEFT", chatFrame.ScrollBox, 0, -22)
        ChatFrame2:SetPoint("BOTTOMRIGHT", chatFrame.ScrollBox, -15, 0)
        ChatFrame2Background:SetParent(addonTable.hiddenFrame)
        ChatFrame2BottomRightTexture:SetParent(addonTable.hiddenFrame)
        ChatFrame2BottomLeftTexture:SetParent(addonTable.hiddenFrame)
        ChatFrame2BottomTexture:SetParent(addonTable.hiddenFrame)
        ChatFrame2TopLeftTexture:SetParent(addonTable.hiddenFrame)
        ChatFrame2TopRightTexture:SetParent(addonTable.hiddenFrame)
        ChatFrame2TopTexture:SetParent(addonTable.hiddenFrame)
        ChatFrame2RightTexture:SetParent(addonTable.hiddenFrame)
        ChatFrame2LeftTexture:SetParent(addonTable.hiddenFrame)
        if ChatFrame2ButtonFrameBackground then
          ChatFrame2ButtonFrameBackground:SetParent(addonTable.hiddenFrame)
          ChatFrame2ButtonFrameRightTexture:SetParent(addonTable.hiddenFrame)
        end
        ChatFrame2:Show()
      elseif mouseButton == "RightButton" then
        MenuUtil.CreateContextMenu(combatLogButton, function(menu, rootDescription)
          rootDescription:CreateButton(SETTINGS, function()
            ShowUIPanel(ChatConfigFrame)
          end)
          if not addonTable.Config.Get(addonTable.Config.Options.LOCKED) then
            rootDescription:CreateButton(CLOSE, function()
              addonTable.Config.Set(addonTable.Config.Options.SHOW_COMBAT_LOG, false)
            end)
          end
        end)
      end
    end)
    local combatLogColor = CreateColor(201/255, 124/255, 72/255)
    combatLogButton:SetColor(combatLogColor.r, combatLogColor.g, combatLogColor.b)

    if lastButton == nil then
      combatLogButton:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", 32, -22)
    else
      combatLogButton:SetPoint("LEFT", lastButton, "RIGHT", 10, 0)
    end

    table.insert(allTabs, combatLogButton)
    lastButton = combatLogButton
  end

  if not addonTable.Config.Get(addonTable.Config.Options.LOCKED) then
    local newTab = chatFrame.tabsPool:Acquire()
    newTab.minWidth = true
    newTab:SetText(CreateTextureMarkup("Interface/AddOns/Chattynator/Assets/NewTab.png", 40, 40, 15, 15, 0, 1, 0, 1))
    newTab:SetScript("OnClick", function()
      table.insert(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[chatFrame:GetID()].tabs, addonTable.Config.GetEmptyTabConfig(addonTable.Locales.NEW_TAB))
      addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
    end)
    newTab:Show()
    newTab:SetColor(0.3, 0.3, 0.3)
    table.insert(allTabs, newTab)

    if lastButton == nil then
      newTab:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", 32, -22)
    else
      newTab:SetPoint("LEFT", lastButton, "RIGHT", 10, 0)
    end
    lastButton = newTab
  end

  for _, tab in ipairs(allTabs) do
    tab:SetSelected(false)
  end
  chatFrame.tabs = allTabs
  local currentTab = chatFrame.tabIndex and math.min(chatFrame.tabIndex, #addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[chatFrame:GetID()].tabs) or 1
  allTabs[currentTab]:SetSelected(true)
  chatFrame:SetFilter(allTabs[currentTab].filter)
  chatFrame:SetBackgroundColor(allTabs[currentTab].bgColor.r, allTabs[currentTab].bgColor.g, allTabs[currentTab].bgColor.b)
  if currentTab ~= chatFrame.tabIndex then
    chatFrame:SetTabSelected(currentTab)
    chatFrame:Render()
  end
  addonTable.CallbackRegistry:TriggerEvent("TabSelected", chatFrame:GetID(), currentTab)
end
