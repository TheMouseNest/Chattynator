---@class addonTableChatanator
local addonTable = select(2, ...)

local intensity = 0.8
local hoverColor = {r = 59/255, g = 210/255, b = 237/255}

local skinners = {
  ChatButton = function(button, tags)
    button:SetSize(26, 28)
    button:SetNormalTexture("Interface/AddOns/Chatanator/Assets/ChatButton.png")
    button:GetNormalTexture():SetVertexColor(0.15, 0.15, 0.15)
    button:GetNormalTexture():SetDrawLayer("BACKGROUND")
    button:SetPushedTexture("Interface/AddOns/Chatanator/Assets/ChatButton.png")
    button:GetPushedTexture():SetVertexColor(0.05, 0.05, 0.05)
    button:GetPushedTexture():SetDrawLayer("BACKGROUND")
    button:ClearHighlightTexture()

    button:HookScript("OnEnter", function()
      button.Icon:SetVertexColor(hoverColor.r, hoverColor.g, hoverColor.b)
    end)
    button:HookScript("OnLeave", function()
      button.Icon:SetVertexColor(intensity, intensity, intensity)
    end)

    button:HookScript("OnMouseDown", function()
      button.Icon:AdjustPointsOffset(2, -2)
    end)
    button:HookScript("OnMouseUp", function()
      button.Icon:AdjustPointsOffset(-2, 2)
    end)

    if tags.toasts then
      button.Icon = button.FriendsButton
      button.FriendsButton:SetTexture("Interface/AddOns/Chatanator/Assets/ChatSocial.png")
      button.FriendsButton:SetVertexColor(intensity, intensity, intensity)
      button.FriendsButton:SetDrawLayer("ARTWORK")
      button.FriendsButton:SetSize(12, 12)
      button.FriendsButton:ClearAllPoints()
      button.FriendsButton:SetPoint("TOP", 0, -2)

      button:HookScript("OnEnter", function()
        button.FriendCount:SetTextColor(hoverColor.r, hoverColor.g, hoverColor.b)
      end)
      button:HookScript("OnLeave", function()
        button.FriendCount:SetTextColor(intensity, intensity, intensity)
      end)
    elseif tags.channels then
      button.Icon:SetTexture("Interface/Addons/Chatanator/Assets/ChatChannels.png")
      button.Icon:SetVertexColor(intensity, intensity, intensity)
    elseif tags.menu then
      button.Icon = button:CreateTexture(nil, "ARTWORK")
      button.Icon:SetTexture("Interface/AddOns/Chatanator/Assets/ChatMenu.png")
      button.Icon:SetVertexColor(intensity, intensity, intensity)
      button.Icon:SetPoint("CENTER")
      button.Icon:SetSize(15, 15)
    else
      button.Icon = button:CreateTexture(nil, "OVERLAY")
      if tags.search then
        button.Icon:SetTexture("Interface/AddOns/Chatanator/Assets/Search.png")
      elseif tags.copy then
        button.Icon:SetTexture("Interface/AddOns/Chatanator/Assets/Copy.png")
      elseif tags.settings then
        button.Icon:SetTexture("Interface/AddOns/Chatanator/Assets/SettingsCog.png")
      end
      button.Icon:SetPoint("CENTER")
      button.Icon:SetSize(15, 15)
      button.Icon:SetVertexColor(intensity, intensity, intensity)
    end
  end,
  ChatFrame = function(frame, tags)
    frame.background = frame:CreateTexture(nil, "BACKGROUND")
    frame.background:SetTexture("Interface/AddOns/Chatanator/Assets/ChatBackground")
    frame.background:SetTexCoord(0, 1, 1, 0)
    frame.background:SetPoint("TOP", frame.ScrollBox, 0, 5)
    frame.background:SetPoint("LEFT")
    frame.background:SetPoint("BOTTOMRIGHT", frame.ScrollBox, 0, -5)
    frame.background:SetAlpha(0.8)

    if frame.backgroundColor then
      frame.background:SetVertexColor(frame.backgroundColor.r, frame.backgroundColor.g, frame.backgroundColor.b)
    end
    hooksecurefunc(frame, "SetBackgroundColor", function(_, r, g, b)
      frame.background:SetVertexColor(r, g, b)
    end)
  end,
  ChatEditBox = function(editBox, tags)
    for _, texName in ipairs({"Left", "Right", "Mid", "FocusLeft", "FocusRight", "FocusMid"}) do
      local tex = _G[editBox:GetName() .. texName]
      if tex then
        tex:SetParent(addonTable.hiddenFrame)
      end
    end
    local background = editBox:CreateTexture(nil, "BACKGROUND")
    background:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    background:SetPoint("TOPLEFT", editBox)
    background:SetPoint("BOTTOM", editBox)
    background:SetPoint("RIGHT", editBox)
  end,
  ChatTab = function(tab, tags)
    tab:SetHeight(22)
    tab:SetAlpha(1)
    tab.Left = tab:CreateTexture(nil, "BACKGROUND")
    tab.Left:SetTexture("Interface/AddOns/Chatanator/Assets/ChatTabLeft")
    tab.Left:SetHeight(22)
    tab.Left:SetWidth(6)
    tab.Left:SetPoint("TOPLEFT")
    tab.Right = tab:CreateTexture(nil, "BACKGROUND")
    tab.Right:SetTexture("Interface/AddOns/Chatanator/Assets/ChatTabRight")
    tab.Right:SetHeight(22)
    tab.Right:SetWidth(6)
    tab.Right:SetPoint("TOPRIGHT")
    tab.Middle = tab:CreateTexture(nil, "BACKGROUND")
    tab.Middle:SetTexture("Interface/AddOns/Chatanator/Assets/ChatTabMiddle")
    tab.Middle:SetHeight(22)
    tab.Middle:SetPoint("LEFT", 6, 0)
    tab.Middle:SetPoint("RIGHT", -6, 0)
    tab:SetNormalFontObject("GameFontNormalSmall")
    if tab:GetFontString() == nil then
      tab:SetText(" ")
    end
    local tabPadding = 30
    tab:SetWidth(math.max(tab:GetFontString():GetUnboundedStringWidth(), 80) + tabPadding)
    hooksecurefunc(tab, "SetText", function()
      tab:SetWidth(math.max(tab:GetFontString():GetUnboundedStringWidth(), 80) + tabPadding)
    end)
    tab:GetFontString():SetPoint("TOP", 0, -5)
    tab:HookScript("OnEnter", function()
      if tab.selected then
        tab.Left:SetAlpha(1)
        tab.Right:SetAlpha(1)
        tab.Middle:SetAlpha(1)
      else
        tab:SetAlpha(1)
        tab.Left:SetAlpha(0.8)
        tab.Right:SetAlpha(0.8)
        tab.Middle:SetAlpha(0.8)
      end
    end)
    tab:HookScript("OnLeave", function()
      tab:SetSelected(tab.selected)
    end)
    hooksecurefunc(tab, "SetSelected", function(_, state)
      if state then
        tab.Left:SetAlpha(0.8)
        tab.Right:SetAlpha(0.8)
        tab.Middle:SetAlpha(0.8)
        tab:SetAlpha(1)
      else
        tab.Left:SetAlpha(0.8)
        tab.Right:SetAlpha(0.8)
        tab.Middle:SetAlpha(0.8)
        tab:SetAlpha(0.5)
      end
    end)
    hooksecurefunc(tab, "SetColor", function(_, r, g, b)
      tab.Left:SetVertexColor(r, g, b)
      tab.Right:SetVertexColor(r, g, b)
      tab.Middle:SetVertexColor(r, g, b)
    end)
    if tab.color then
      tab:SetColor(tab.color.r, tab.color.g, tab.color.b)
    end
    if tab.selected ~= nil then
      tab:SetSelected(tab.selected)
    end
  end,
  ResizeWidget = function(frame, tags)
    local tex = frame:CreateTexture(nil, "ARTWORK")
    tex:SetVertexColor(intensity, intensity, intensity)
    tex:SetTexture("Interface/AddOns/Chatanator/Assets/resize.png")
    tex:SetAllPoints()
    frame:SetScript("OnEnter", function()
      tex:SetVertexColor(59/255, 210/255, 237/255)
    end)
    frame:SetScript("OnLeave", function()
      tex:SetVertexColor(1, 1, 1)
    end)
  end,
}

local function ConvertTags(tags)
  local res = {}
  for _, tag in ipairs(tags) do
    res[tag] = true
  end
  return res
end

local function SkinFrame(details)
  local func = skinners[details.regionType]
  if func then
    func(details.region, details.tags and ConvertTags(details.tags) or {})
  end
end

local function SetConstants()
end

local function LoadSkin()
  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
  end)
end

addonTable.Skins.RegisterSkin(addonTable.Locales.DARK, "dark", LoadSkin, SkinFrame, SetConstants, {})
