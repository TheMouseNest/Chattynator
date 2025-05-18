---@class addonTableChatanator
local addonTable = select(2, ...)

function addonTable.Core.GetTabsPool(parent)
  return CreateFramePool("Button", parent, "ChatTabArtTemplate", nil, false,
    function(tabButton)
      tabButton:SetNormalFontObject("GameFontNormalSmall")
      tabButton:SetText(" ")
      tabButton:GetFontString():SetPoint("TOP", 0, -18)
      tabButton:SetWidth(80)
      tabButton:SetAlpha(1)
      tabButton:RegisterForDrag("LeftButton")
      tabButton:SetScript("OnDragStart", function()
        addonTable.ChatFrame:StartMoving()
      end)
      tabButton:SetScript("OnDragStop", function()
        addonTable.ChatFrame:StopMovingOrSizing()
      end)
      function tabButton:SetSelected(state)
        self.ActiveMiddle:SetShown(state)
        self.ActiveLeft:SetShown(state)
        self.ActiveRight:SetShown(state)
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
    if tab.invert then
      button:SetScript("OnClick", function()
        chatFrame:SetFilter(function(data) return tab.groups[data.typeInfo.type] ~= false end)
        chatFrame:Render()
        for _, otherTab in ipairs(allTabs) do
          otherTab:SetSelected(false)
        end
        button:SetSelected(true)
      end)
    else
      button:SetScript("OnClick", function()
        chatFrame:SetFilter(function(data) return tab.groups[data.typeInfo.type] end)
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
    local tabColor = CreateColorFromRGBHexString(tab.tabColor)
    button.Left:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.Right:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.Middle:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.ActiveLeft:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.ActiveRight:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.ActiveMiddle:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.HighlightLeft:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.HighlightRight:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.HighlightMiddle:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    table.insert(allTabs, button)
    lastButton = button
  end

  allTabs[1]:Click()
end
