---@class addonTableChatanator
local addonTable = select(2, ...)


function addonTable.Core.InitializeTabs(chatFrame)
  local allTabs = {}
  local lastButton
  for _, tab in ipairs(addonTable.Config.Get(addonTable.Config.Options.TABS)) do
    local button = CreateFrame("Button", nil, chatFrame, "ChatTabArtTemplate")
    button:SetNormalFontObject("GameFontNormalSmall")
    button:SetText(_G[tab.name] or tab.name or UNKNOWN)
    button:GetFontString():SetPoint("TOP", 0, -18)
    if tab.invert then
      button:SetScript("OnClick", function()
        chatFrame:SetFilter(function(data) return tab.groups[data.typeInfo.type] ~= false end)
        chatFrame:Render()
      end)
    else
      button:SetScript("OnClick", function()
        chatFrame:SetFilter(function(data) return tab.groups[data.typeInfo.type] end)
        chatFrame:Render()
      end)
    end

    if lastButton == nil then
      button:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", 0, 5)
    else
      button:SetPoint("LEFT", lastButton, "RIGHT", 10, 0)
    end
    button:SetWidth(80)
    local tabColor = CreateColorFromRGBHexString(tab.tabColor)
    button.Left:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.Right:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    button.Middle:SetVertexColor(tabColor.r, tabColor.g, tabColor.b)
    table.insert(allTabs, button)
    lastButton = button
  end
end
