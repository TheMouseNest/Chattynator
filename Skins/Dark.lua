---@class addonTableChattynator
local addonTable = select(2, ...)

local intensity = 0.8
local hoverColor = {r = 59/255, g = 210/255, b = 237/255}
local flashTabColor = {r = 247/255, g = 222/255, b = 61/255}

local skinners = {
  ChatButton = function(button, tags)
    button:SetSize(26, 28)
    button:SetNormalTexture("Interface/AddOns/Chattynator/Assets/ChatButton.png")
    button:GetNormalTexture():SetVertexColor(0.15, 0.15, 0.15)
    button:GetNormalTexture():SetDrawLayer("BACKGROUND")
    button:SetPushedTexture("Interface/AddOns/Chattynator/Assets/ChatButton.png")
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
      button.FriendsButton:SetTexture("Interface/AddOns/Chattynator/Assets/ChatSocial.png")
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
      button.Icon:SetTexture("Interface/Addons/Chattynator/Assets/ChatChannels.png")
      button.Icon:SetVertexColor(intensity, intensity, intensity)
    elseif tags.menu then
      button.Icon = button:CreateTexture(nil, "ARTWORK")
      button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/ChatMenu.png")
      button.Icon:SetVertexColor(intensity, intensity, intensity)
      button.Icon:SetPoint("CENTER")
      button.Icon:SetSize(15, 15)
    else
      button.Icon = button:CreateTexture(nil, "OVERLAY")
      if tags.search then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/Search.png")
      elseif tags.copy then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/Copy.png")
      elseif tags.settings then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/SettingsCog.png")
      elseif tags.scrollToEnd then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/ScrollToBottom.png")
      end
      button.Icon:SetPoint("CENTER")
      button.Icon:SetSize(15, 15)
      button.Icon:SetVertexColor(intensity, intensity, intensity)
    end
  end,
  ChatFrame = function(frame, tags)
    frame.background = frame:CreateTexture(nil, "BACKGROUND")
    frame.background:SetTexture("Interface/AddOns/Chattynator/Assets/ChatBackground")
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
    tab.Left:SetTexture("Interface/AddOns/Chattynator/Assets/ChatTabLeft")
    tab.Left:SetHeight(22)
    tab.Left:SetWidth(6)
    tab.Left:SetPoint("TOPLEFT")
    tab.Right = tab:CreateTexture(nil, "BACKGROUND")
    tab.Right:SetTexture("Interface/AddOns/Chattynator/Assets/ChatTabRight")
    tab.Right:SetHeight(22)
    tab.Right:SetWidth(6)
    tab.Right:SetPoint("TOPRIGHT")
    tab.Middle = tab:CreateTexture(nil, "BACKGROUND")
    tab.Middle:SetTexture("Interface/AddOns/Chattynator/Assets/ChatTabMiddle")
    tab.Middle:SetHeight(22)
    tab.Middle:SetPoint("LEFT", 6, 0)
    tab.Middle:SetPoint("RIGHT", -6, 0)
    tab.LeftFlash = tab:CreateTexture(nil, "BACKGROUND")
    tab.LeftFlash:SetTexture("Interface/AddOns/Chattynator/Assets/ChatTabLeft")
    tab.LeftFlash:SetHeight(24)
    tab.LeftFlash:SetWidth(8)
    tab.LeftFlash:SetPoint("BOTTOMLEFT", -1, 0)
    tab.LeftFlash:Hide()
    tab.LeftFlash:SetIgnoreParentAlpha(true)
    tab.LeftFlash:SetVertexColor(flashTabColor.r, flashTabColor.g, flashTabColor.b)
    tab.RightFlash = tab:CreateTexture(nil, "BACKGROUND")
    tab.RightFlash:SetTexture("Interface/AddOns/Chattynator/Assets/ChatTabRight")
    tab.RightFlash:SetHeight(24)
    tab.RightFlash:SetWidth(8)
    tab.RightFlash:SetPoint("BOTTOMRIGHT", 1, 0)
    tab.RightFlash:Hide()
    tab.RightFlash:SetIgnoreParentAlpha(true)
    tab.RightFlash:SetVertexColor(flashTabColor.r, flashTabColor.g, flashTabColor.b)
    tab.MiddleFlash = tab:CreateTexture(nil, "BACKGROUND")
    tab.MiddleFlash:SetTexture("Interface/AddOns/Chattynator/Assets/ChatTabMiddle")
    tab.MiddleFlash:SetHeight(24)
    tab.MiddleFlash:SetPoint("BOTTOMLEFT", 7, 0)
    tab.MiddleFlash:SetPoint("BOTTOMRIGHT", -7, 0)
    tab.MiddleFlash:Hide()
    tab.MiddleFlash:SetIgnoreParentAlpha(true)
    tab.MiddleFlash:SetVertexColor(flashTabColor.r, flashTabColor.g, flashTabColor.b)
    tab:SetNormalFontObject("GameFontNormalSmall")
    if tab:GetFontString() == nil then
      tab:SetText(" ")
    end
    local tabPadding = 30
    if tab.minWidth then
      tab:SetWidth(tab:GetFontString():GetUnboundedStringWidth() + tabPadding)
    else
      tab:SetWidth(math.max(tab:GetFontString():GetUnboundedStringWidth(), 80) + tabPadding)
    end
    hooksecurefunc(tab, "SetText", function()
      if tab.minWidth then
        tab:SetWidth(tab:GetFontString():GetUnboundedStringWidth() + tabPadding)
      else
        tab:SetWidth(math.max(tab:GetFontString():GetUnboundedStringWidth(), 80) + tabPadding)
      end
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
    local function SetSelected(_, state)
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
    end
    tab:HookScript("OnLeave", function()
      SetSelected(tab, tab.selected)
    end)
    hooksecurefunc(tab, "SetSelected", SetSelected)
    hooksecurefunc(tab, "SetColor", function(_, r, g, b)
      tab.Left:SetVertexColor(r, g, b)
      tab.Right:SetVertexColor(r, g, b)
      tab.Middle:SetVertexColor(r, g, b)
      tab.LeftFlash:SetVertexColor(r, g, b)
      tab.RightFlash:SetVertexColor(r, g, b)
      tab.MiddleFlash:SetVertexColor(r, g, b)
    end)
    if tab.color then
      tab:SetColor(tab.color.r, tab.color.g, tab.color.b)
    end
    if tab.selected ~= nil then
      tab:SetSelected(tab.selected)
    end

    tab.FlashAnimation = tab:CreateAnimationGroup()
    tab.FlashAnimation:SetLooping("BOUNCE")
    local alpha1 = tab.FlashAnimation:CreateAnimation("Alpha")
    alpha1:SetChildKey("LeftFlash")
    alpha1:SetFromAlpha(0.3)
    alpha1:SetToAlpha(1)
    alpha1:SetDuration(0.8)
    alpha1:SetOrder(1)
    local alpha2 = tab.FlashAnimation:CreateAnimation("Alpha")
    alpha2:SetChildKey("RightFlash")
    alpha2:SetFromAlpha(0.3)
    alpha2:SetToAlpha(1)
    alpha2:SetDuration(0.8)
    alpha2:SetOrder(1)
    local alpha3 = tab.FlashAnimation:CreateAnimation("Alpha")
    alpha3:SetChildKey("MiddleFlash")
    alpha3:SetFromAlpha(0.3)
    alpha3:SetToAlpha(1)
    alpha3:SetDuration(0.8)
    alpha3:SetOrder(1)
    hooksecurefunc(tab, "SetFlashing", function(_, state)
      tab.FlashAnimation:SetPlaying(state)
      tab.LeftFlash:SetShown(state)
      tab.RightFlash:SetShown(state)
      tab.MiddleFlash:SetShown(state)
      if state then
        tab:SetHitRectInsets(0, 0, -2, 0)
      else
        tab:SetHitRectInsets(0, 0, 0, 0)
      end
    end)
  end,
  ResizeWidget = function(frame, tags)
    local tex = frame:CreateTexture(nil, "ARTWORK")
    tex:SetVertexColor(intensity, intensity, intensity)
    tex:SetTexture("Interface/AddOns/Chattynator/Assets/resize.png")
    tex:SetAllPoints()
    frame:SetScript("OnEnter", function()
      tex:SetVertexColor(hoverColor.r, hoverColor.g, hoverColor.b)
    end)
    frame:SetScript("OnLeave", function()
      tex:SetVertexColor(intensity, intensity, intensity)
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
