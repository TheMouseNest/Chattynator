---@class addonTableChatanator
local addonTable = select(2, ...)

function addonTable.Core.GetTabsPool(parent)
  return CreateFramePool("Button", parent, nil, nil, false,
    function(tabButton)
      tabButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
      tabButton:SetHeight(22)
      tabButton.Left = tabButton:CreateTexture(nil, "BACKGROUND")
      tabButton.Left:SetTexture("Interface/AddOns/Chatanator/Assets/ChatTabLeft")
      tabButton.Left:SetHeight(22)
      tabButton.Left:SetWidth(6)
      tabButton.Left:SetPoint("TOPLEFT")
      tabButton.Right = tabButton:CreateTexture(nil, "BACKGROUND")
      tabButton.Right:SetTexture("Interface/AddOns/Chatanator/Assets/ChatTabRight")
      tabButton.Right:SetHeight(22)
      tabButton.Right:SetWidth(6)
      tabButton.Right:SetPoint("TOPRIGHT")
      tabButton.Middle = tabButton:CreateTexture(nil, "BACKGROUND")
      tabButton.Middle:SetTexture("Interface/AddOns/Chatanator/Assets/ChatTabMiddle")
      tabButton.Middle:SetHeight(22)
      tabButton.Middle:SetPoint("LEFT", 6, 0)
      tabButton.Middle:SetPoint("RIGHT", -6, 0)
      tabButton:SetNormalFontObject("GameFontNormalSmall")
      tabButton:SetText(" ")
      tabButton:GetFontString():SetPoint("TOP", 0, -5)
      tabButton:SetWidth(80)
      tabButton:SetAlpha(1)
      tabButton:RegisterForDrag("LeftButton")
      tabButton:SetScript("OnDragStart", function()
        addonTable.ChatFrame:StartMoving()
      end)
      tabButton:SetScript("OnDragStop", function()
        addonTable.ChatFrame:StopMovingOrSizing()
        addonTable.ChatFrame:SavePosition()
      end)
      tabButton:SetScript("OnEnter", function()
        if tabButton.selected then
          tabButton.Left:SetAlpha(1)
          tabButton.Right:SetAlpha(1)
          tabButton.Middle:SetAlpha(1)
        else
          tabButton:SetAlpha(1)
          tabButton.Left:SetAlpha(0.8)
          tabButton.Right:SetAlpha(0.8)
          tabButton.Middle:SetAlpha(0.8)
        end
      end)
      tabButton:SetScript("OnLeave", function()
        tabButton:SetSelected(tabButton.selected)
      end)
      function tabButton:SetSelected(state)
        self.selected = state
        if state then
          tabButton.Left:SetAlpha(0.8)
          tabButton.Right:SetAlpha(0.8)
          tabButton.Middle:SetAlpha(0.8)
          tabButton:SetAlpha(1)
        else
          tabButton.Left:SetAlpha(0.8)
          tabButton.Right:SetAlpha(0.8)
          tabButton.Middle:SetAlpha(0.8)
          tabButton:SetAlpha(0.5)
        end
      end
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
  end
  chatFrame.tabsPool:ReleaseAll()
  local allTabs = {}
  local lastButton
  for index, tab in ipairs(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[chatFrame:GetID()].tabs) do
    local button = chatFrame.tabsPool:Acquire()
    button:Show()
    button:SetText(_G[tab.name] or tab.name or UNKNOWN)
    local tabColor = CreateColorFromRGBHexString(tab.tabColor)
    local bgColor = CreateColorFromRGBHexString(tab.backgroundColor)
    local filter
    if tab.invert then
      filter = function(data) return tab.groups[data.typeInfo.type] ~= false end
    else
      filter = function(data) return tab.groups[data.typeInfo.type] end
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
        chatFrame:SetTabChanged()
        chatFrame:Render()
        for _, otherTab in ipairs(allTabs) do
          otherTab:SetSelected(false)
        end
        button:SetSelected(true)
      elseif mouseButton == "RightButton" then
        MenuUtil.CreateContextMenu(button, function(_, rootDescription)
          rootDescription:CreateButton(SETTINGS, function()
            addonTable.CustomiseDialog.GetTabCustomiser(index)
          end)
        end)
      end
    end)

    if lastButton == nil then
      button:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", 32, -22)
    else
      button:SetPoint("LEFT", lastButton, "RIGHT", 10, 0)
    end
    button.Left:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.Right:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.Middle:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    table.insert(allTabs, button)
    lastButton = button
  end

  if chatFrame:GetID() == 1 then
    local combatLogButton = chatFrame.tabsPool:Acquire()
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
        ChatFrame2ButtonFrameBackground:SetParent(addonTable.hiddenFrame)
        ChatFrame2ButtonFrameRightTexture:SetParent(addonTable.hiddenFrame)
        ChatFrame2:Show()
      elseif mouseButton == "RightButton" then
        MenuUtil.CreateContextMenu(combatLogButton, function(_, rootDescription)
          rootDescription:CreateButton(SETTINGS, function()
            ShowUIPanel(ChatConfigFrame)
          end)
        end)
      end
    end)
    local combatLogColor = CreateColor(201/255, 124/255, 72/255)
    combatLogButton.Left:SetVertexColor(combatLogColor.r, combatLogColor.g, combatLogColor.b)
    combatLogButton.Right:SetVertexColor(combatLogColor.r, combatLogColor.g, combatLogColor.b)
    combatLogButton.Middle:SetVertexColor(combatLogColor.r, combatLogColor.g, combatLogColor.b)

    if lastButton == nil then
      combatLogButton:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", 32, -22)
    else
      combatLogButton:SetPoint("LEFT", lastButton, "RIGHT", 10, 0)
    end

    table.insert(allTabs, combatLogButton)
    lastButton = combatLogButton
  end

  for _, tab in ipairs(allTabs) do
    tab:SetSelected(false)
  end
  allTabs[1]:SetSelected(true)
  chatFrame:SetFilter(allTabs[1].filter)
  chatFrame:SetBackgroundColor(allTabs[1].bgColor.r, allTabs[1].bgColor.g, allTabs[1].bgColor.b)
  chatFrame:SetTabChanged()
end
