---@class addonTableChattynator
local addonTable = select(2, ...)

function addonTable.Core.GetTabsPool(parent)
  return CreateFramePool("Button", parent, nil, nil, false,
    function(tabButton)
      tabButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
      tabButton:RegisterForDrag("LeftButton")
      tabButton:SetScript("OnDragStart", function()
        if addonTable.Config.Get(addonTable.Config.Options.LOCKED) then
          return
        end
        if tabButton:GetID() == 1 then
          parent:StartMoving()
        end
      end)
      tabButton:SetScript("OnDragStop", function()
        parent:StopMovingOrSizing()
        parent:SavePosition()
      end)
      function tabButton:SetSelected(state)
        self:SetFlashing(false)
        self.selected = state
      end
      function tabButton:SetColor(r, g, b)
        self.color = {r = r, g = g, b = b}
      end
      function tabButton:SetFlashing(state)
        self.flashing = state
      end
      addonTable.Skins.AddFrame("ChatTab", tabButton)
    end
  )
end

local function DisableCombatLog(chatFrame)
  ChatFrame2:SetParent(addonTable.hiddenFrame)
  chatFrame.ScrollingMessages:Show()
end

local function RenameTab(windowIndex, tabIndex, newName)
  local windowData = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[windowIndex]
  if not windowData then
    return
  end
  local tabData = windowData.tabs[tabIndex]
  if not tabData then
    return
  end

  tabData.name = newName
  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
end

local renameDialog = "Chattynator_RenameTabDialog"
StaticPopupDialogs[renameDialog] = {
  text = "",
  button1 = ACCEPT,
  button2 = CANCEL,
  hasEditBox = 1,
  OnAccept = function(self, data)
    RenameTab(data.window, data.tab, self.editBox:GetText())
  end,
  EditBoxOnEnterPressed = function(self, data)
    RenameTab(data.window, data.tab, self:GetText())
    self:GetParent():Hide()
  end,
  EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
  hideOnEscape = 1,
}

function addonTable.Core.InitializeTabs(chatFrame)
  local forceSelected = false
  if not chatFrame.tabsPool then
    forceSelected = true
    chatFrame.tabsPool = addonTable.Core.GetTabsPool(chatFrame)
  else -- Might have shown combat log at some point
    DisableCombatLog(chatFrame)
  end
  chatFrame.tabsPool:ReleaseAll()
  local allTabs = {}
  local lastButton
  for index, tab in ipairs(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[chatFrame:GetID()].tabs) do
    local tabButton = chatFrame.tabsPool:Acquire()
    tabButton.minWidth = false
    tabButton:SetID(index)
    tabButton:Show()
    tabButton:SetText(_G[tab.name] or tab.name or UNKNOWN)
    local tabColor = CreateColorFromRGBHexString(tab.tabColor)
    local bgColor = CreateColorFromRGBHexString(tab.backgroundColor)
    local filter
    local tabTag = chatFrame:GetID() .. "_" .. index
    if tab.invert then
      filter = function(data)
        return tab.groups[data.typeInfo.type] ~= false and (data.typeInfo.tabTag == nil or data.typeInfo.tabTag == tabTag) and
          (
          not data.typeInfo.channel or
          (tab.channels[data.typeInfo.channel.name] == nil and data.typeInfo.channel.isDefault) or
          tab.channels[data.typeInfo.channel.name]
        ) and ((data.typeInfo.type ~= "WHISPER" and data.typeInfo.type ~= "BN_WHISPER") or tab.whispersTemp[data.typeInfo.player.name] ~= false)
        or (data.typeInfo.type == "ADDON" and tab.groups["ADDON"] == false and tab.addons[data.typeInfo.source] ~= false and (data.typeInfo.tabTag == nil or data.typeInfo.tabTag == tabTag))
      end
    else
      filter = function(data)
        return tab.groups[data.typeInfo.type] and (data.typeInfo.tabTag == nil or data.typeInfo.tabTag == tabTag) or
          (data.typeInfo.type == "WHISPER" or data.typeInfo.type == "BN_WHISPER") and tab.whispersTemp[data.typeInfo.player.name] or
          tab.channels[data.typeInfo.channel and data.typeInfo.channel.name] or
          data.typeInfo.type == "ADDON" and not tab.groups["ADDON"] and tab.addons[data.typeInfo.source] and (data.typeInfo.tabTag == nil or data.typeInfo.tabTag == tabTag)
      end
    end
    tabButton.filter = filter
    tabButton.bgColor = bgColor
    tabButton:SetScript("OnClick", function(_, mouseButton)
      if chatFrame:GetID() == 1 then
        DisableCombatLog(chatFrame)
      end
      if mouseButton == "LeftButton" then
        chatFrame:SetBackgroundColor(bgColor.r, bgColor.g, bgColor.b)
        chatFrame:SetTabSelectedAndFilter(tabButton:GetID(), filter)
        chatFrame.ScrollingMessages:Render()
        for _, otherTab in ipairs(allTabs) do
          otherTab:SetSelected(false)
        end
        tabButton:SetSelected(true)
        addonTable.CallbackRegistry:TriggerEvent("TabSelected", chatFrame:GetID(), tabButton:GetID())
      elseif mouseButton == "RightButton" then
        MenuUtil.CreateContextMenu(tabButton, function(_, rootDescription)
          rootDescription:CreateButton(addonTable.Locales.TAB_SETTINGS, function()
            addonTable.CustomiseDialog.ToggleTabFilters(chatFrame:GetID(), tabButton:GetID())
          end)
          rootDescription:CreateButton(addonTable.Locales.GLOBAL_SETTINGS, function()
            addonTable.CustomiseDialog.Toggle()
          end)
          rootDescription:CreateDivider()
          if tab.isTemporary or not addonTable.Config.Get(addonTable.Config.Options.LOCKED) then
            rootDescription:CreateButton(addonTable.Locales.LOCK_CHAT, function()
              addonTable.Config.Set(addonTable.Config.Options.LOCKED, true)
            end)
            rootDescription:CreateButton(addonTable.Locales.RENAME_TAB, function()
              StaticPopup_Show(renameDialog, nil, nil, {window = chatFrame:GetID(), tab = tabButton:GetID()})
            end)
            if tabButton:GetID() ~= 1 then
              rootDescription:CreateButton(addonTable.Locales.MOVE_TO_NEW_WINDOW, function()
                local newChatFrame = addonTable.Core.MakeChatFrame()

                local windows = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)
                windows[newChatFrame:GetID()].tabs[1] = windows[chatFrame:GetID()].tabs[tabButton:GetID()]
                table.remove(windows[chatFrame:GetID()].tabs, tabButton:GetID())
                newChatFrame:Reset()
                newChatFrame.ScrollingMessages:Render()
                addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
              end)
            end
            if tabButton:GetID() == 1 and chatFrame:GetID() ~= 1 then
              rootDescription:CreateButton(addonTable.Locales.CLOSE_WINDOW, function()
                addonTable.Core.DeleteChatFrame(chatFrame:GetID())
              end)
            elseif tabButton:GetID() ~= 1 then
              rootDescription:CreateButton(addonTable.Locales.CLOSE_TAB, function()
                table.remove(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[chatFrame:GetID()].tabs, index)
                addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
              end)
            end
          else
            rootDescription:CreateButton(addonTable.Locales.UNLOCK_CHAT, function()
              addonTable.Config.Set(addonTable.Config.Options.LOCKED, false)
            end)
          end
        end)
      end
    end)

    if lastButton == nil then
      tabButton:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", 32, -22)
    else
      tabButton:SetPoint("LEFT", lastButton, "RIGHT", 10, 0)
    end
    tabButton:SetColor(tabColor.r, tabColor.g, tabColor.b)
    table.insert(allTabs, tabButton)
    lastButton = tabButton
  end

  if chatFrame:GetID() == 1 and addonTable.Config.Get(addonTable.Config.Options.SHOW_COMBAT_LOG) then
    local combatLogButton = chatFrame.tabsPool:Acquire()
    combatLogButton.filter = nil
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
        chatFrame.ScrollingMessages:Hide()
        CombatLogQuickButtonFrame_Custom:SetParent(ChatFrame2)
        CombatLogQuickButtonFrame_Custom:ClearAllPoints()
        CombatLogQuickButtonFrame_Custom:SetPoint("TOPLEFT", chatFrame.ScrollingMessages, 0, 0)
        CombatLogQuickButtonFrame_Custom:SetPoint("TOPRIGHT", chatFrame.ScrollingMessages, 0, 0)
        ChatFrame2:SetParent(chatFrame)
        if ChatFrame2ResizeButton then
          ChatFrame2ResizeButton:SetParent(addonTable.hiddenFrame)
        end
        ChatFrame2:ClearAllPoints()
        ChatFrame2:SetPoint("TOPLEFT", chatFrame.ScrollingMessages, 0, -22)
        ChatFrame2:SetPoint("BOTTOMRIGHT", chatFrame.ScrollingMessages, -15, 0)
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
        if ChatFrame2ButtonFrameUpButton then
          ChatFrame2ButtonFrameUpButton:SetParent(addonTable.hiddenFrame)
          ChatFrame2ButtonFrameDownButton:SetParent(addonTable.hiddenFrame)
        end
        ChatFrame2:Show()
      elseif mouseButton == "RightButton" then
        MenuUtil.CreateContextMenu(combatLogButton, function(menu, rootDescription)
          rootDescription:CreateButton(addonTable.Locales.TAB_SETTINGS, function()
            ShowUIPanel(ChatConfigFrame)
          end)
          rootDescription:CreateDivider()
          if not addonTable.Config.Get(addonTable.Config.Options.LOCKED) then
            rootDescription:CreateButton(addonTable.Locales.LOCK_CHAT, function()
              addonTable.Config.Set(addonTable.Config.Options.LOCKED, true)
            end)
            rootDescription:CreateButton(addonTable.Locales.CLOSE_TAB, function()
              addonTable.Config.Set(addonTable.Config.Options.SHOW_COMBAT_LOG, false)
            end)
          else
            rootDescription:CreateButton(addonTable.Locales.UNLOCK_CHAT, function()
              addonTable.Config.Set(addonTable.Config.Options.LOCKED, false)
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
    newTab:SetText(addonTable.Constants.NewTabMarkup)
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
  chatFrame.Tabs = allTabs
  local currentTab = chatFrame.tabIndex and math.min(chatFrame.tabIndex, #addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[chatFrame:GetID()].tabs) or 1
  allTabs[currentTab]:SetSelected(true)
  chatFrame:SetFilter(allTabs[currentTab].filter)
  chatFrame:SetBackgroundColor(allTabs[currentTab].bgColor.r, allTabs[currentTab].bgColor.g, allTabs[currentTab].bgColor.b)
  if currentTab ~= chatFrame.tabIndex then
    chatFrame:SetTabSelectedAndFilter(currentTab, allTabs[currentTab].filter)
    chatFrame.ScrollingMessages:Render()
    addonTable.CallbackRegistry:TriggerEvent("TabSelected", chatFrame:GetID(), currentTab)
  elseif forceSelected then
    addonTable.CallbackRegistry:TriggerEvent("TabSelected", chatFrame:GetID(), currentTab)
  end
end

addonTable.CallbackRegistry:RegisterCallback("Render", function(_, newMessages)
  local targetWindow = addonTable.Config.Get(addonTable.Config.Options.NEW_WHISPER_NEW_TAB)
  if targetWindow ~= 0 and newMessages then
    for i = 1, newMessages do
      local m = addonTable.Messages:GetMessageRaw(i)
      if m.typeInfo.type == "WHISPER" or m.typeInfo.type == "BN_WHISPER" then
        local window = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[targetWindow]
        local any = false
        for _, tab in ipairs(window.tabs) do
          if tab.whispersTemp[m.typeInfo.player.name] then
            any = true
            break
          end
        end
        if not any then
          local tabConfig = addonTable.Config.GetEmptyTabConfig(Ambiguate(m.typeInfo.player.name, "all"))
          local c = ChatTypeInfo[m.typeInfo.type]
          tabConfig.tabColor = CreateColor(c.r, c.g, c.b):GenerateHexColorNoAlpha()
          tabConfig.whispersTemp[m.typeInfo.player.name] = true
          tabConfig.isTemporary = true
          table.insert(window.tabs, tabConfig)
          addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
        end
      end
    end
  end
end)
