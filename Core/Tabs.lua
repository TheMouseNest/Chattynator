---@class addonTableChatanator
local addonTable = select(2, ...)

function addonTable.Core.GetTabsPool(parent)
  return CreateFramePool("Button", parent, nil, nil, false,
    function(tabButton)
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

function addonTable.Core.InitializeTabs(chatFrame)
  local pool = addonTable.Core.GetTabsPool(chatFrame)
  local allTabs = {}
  local lastButton
  for _, tab in ipairs(addonTable.Config.Get(addonTable.Config.Options.TABS)) do
    local button = pool:Acquire()
    button:Show()
    button:SetText(_G[tab.name] or tab.name or UNKNOWN)
    local tabColor = CreateColorFromRGBHexString(tab.tabColor)
    local bgColor = CreateColorFromRGBHexString(tab.backgroundColor)
    if tab.invert then
      button:SetScript("OnClick", function()
        chatFrame:SetFilter(function(data) return tab.groups[data.typeInfo.type] ~= false end)
        chatFrame:SetBackgroundColor(bgColor.r, bgColor.g, bgColor.b)
        chatFrame:SetTabChanged()
        chatFrame:Render()
        for _, otherTab in ipairs(allTabs) do
          otherTab:SetSelected(false)
        end
        button:SetSelected(true)
      end)
    else
      button:SetScript("OnClick", function()
        chatFrame:SetFilter(function(data) return tab.groups[data.typeInfo.type] end)
        chatFrame:SetBackgroundColor(bgColor.r, bgColor.g, bgColor.b)
        chatFrame:SetTabChanged()
        chatFrame:Render()
        for _, otherTab in ipairs(allTabs) do
          otherTab:SetSelected(false)
        end
        button:SetSelected(true)
      end)
    end

    if lastButton == nil then
      button:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", 0, 5)
    else
      button:SetPoint("LEFT", lastButton, "RIGHT", 10, 0)
    end
    button.Left:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.Right:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.Middle:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    table.insert(allTabs, button)
    lastButton = button
  end

  allTabs[1]:Click()
end
