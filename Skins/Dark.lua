---@class addonTableChattynator
local addonTable = select(2, ...)

local enableHooks = true

local intensity = 0.8
local hoverColor = {r = 59/255, g = 210/255, b = 237/255}
local voiceActiveColor = {r = 33/255, g = 209/255, b = 45/255}
local flashTabColor = {r = 247/255, g = 222/255, b = 61/255}

local toUpdate = {}

local UIScaleMonitor = CreateFrame("Frame")
UIScaleMonitor:RegisterEvent("UI_SCALE_CHANGED")
UIScaleMonitor:SetScript("OnEvent", function()
  for _, func in ipairs(toUpdate) do
    func()
  end
end)

local chatTabs = {}
local chatFrames = {}
local editBoxes = {}
local chatButtons = {}

local skinners = {
  ChatButton = function(button, tags)
    table.insert(chatButtons, button)
    button:SetSize(26, 28)
    button:SetNormalTexture("Interface/AddOns/Chattynator/Assets/ChatButton.png")
    button:GetNormalTexture():SetVertexColor(0.15, 0.15, 0.15)
    button:GetNormalTexture():SetDrawLayer("BACKGROUND")
    button:SetPushedTexture("Interface/AddOns/Chattynator/Assets/ChatButton.png")
    button:GetPushedTexture():SetVertexColor(0.05, 0.05, 0.05)
    button:GetPushedTexture():SetDrawLayer("BACKGROUND")
    button:ClearHighlightTexture()

    button:HookScript("OnEnter", function()
      if not enableHooks then
        return
      end
      button.Icon:SetVertexColor(hoverColor.r, hoverColor.g, hoverColor.b)
    end)
    button:HookScript("OnLeave", function()
      if not enableHooks then
        return
      end
      button.Icon:SetVertexColor(intensity, intensity, intensity)
    end)

    button:HookScript("OnMouseDown", function()
      if not enableHooks then
        return
      end
      button.Icon:AdjustPointsOffset(2, -2)
    end)
    button:HookScript("OnMouseUp", function()
      if not enableHooks then
        return
      end
      button.Icon:AdjustPointsOffset(-2, 2)
    end)

    if tags.toasts then
      button.Icon = button.FriendsButton or button:CreateTexture(nil, "ARTWORK")
      button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/ChatSocial.png")
      button.Icon:SetVertexColor(intensity, intensity, intensity)
      button.Icon:SetDrawLayer("ARTWORK")
      button.Icon:SetSize(12, 12)
      button.Icon:ClearAllPoints()
      button.Icon:SetPoint("TOP", 0, -2);
      (button.FriendCount or FriendsMicroButtonCount):SetTextColor(intensity, intensity, intensity)
      button:HookScript("OnEnter", function()
        if not enableHooks then
          return
        end
        (button.FriendCount or FriendsMicroButtonCount):SetTextColor(hoverColor.r, hoverColor.g, hoverColor.b)
      end)
      button:HookScript("OnLeave", function()
        if not enableHooks then
          return
        end
        (button.FriendCount or FriendsMicroButtonCount):SetTextColor(intensity, intensity, intensity)
      end)
    elseif tags.channels then
      hooksecurefunc(button, "SetIconToState", function(self, state)
        if not enableHooks then
          return
        end
        button:SetNormalTexture("Interface/AddOns/Chattynator/Assets/ChatButton.png")
        button:GetNormalTexture():SetVertexColor(0.15, 0.15, 0.15)
        button:GetNormalTexture():SetDrawLayer("BACKGROUND")
        button:SetPushedTexture("Interface/AddOns/Chattynator/Assets/ChatButton.png")
        button:GetPushedTexture():SetVertexColor(0.05, 0.05, 0.05)
        button:GetPushedTexture():SetDrawLayer("BACKGROUND")
        button:ClearHighlightTexture()
        if state then
          button.Icon:SetTexture("Interface/Addons/Chattynator/Assets/ChatChannelsVC.png")
          button.Icon:SetVertexColor(voiceActiveColor.r, voiceActiveColor.g, voiceActiveColor.b)
        else
          button.Icon:SetTexture("Interface/Addons/Chattynator/Assets/ChatChannels.png")
          button.Icon:SetVertexColor(intensity, intensity, intensity)
        end
        if button:IsMouseOver() then
          button:GetScript("OnEnter")(button)
        end
      end)
      button:HookScript("OnLeave", function()
        if not enableHooks then
          return
        end
        button:UpdateVisibleState()
      end)
      button:UpdateVisibleState()
    elseif tags.voiceChatNoAudio or tags.voiceChatMuteMic then
      hooksecurefunc(button, "SetIconToState", function(self, state)
        if not enableHooks then
          return
        end
        button:SetNormalTexture("Interface/AddOns/Chattynator/Assets/ChatButton.png")
        button:GetNormalTexture():SetVertexColor(0.15, 0.15, 0.15)
        button:GetNormalTexture():SetDrawLayer("BACKGROUND")
        button:SetPushedTexture("Interface/AddOns/Chattynator/Assets/ChatButton.png")
        button:GetPushedTexture():SetVertexColor(0.05, 0.05, 0.05)
        button:GetPushedTexture():SetDrawLayer("BACKGROUND")
        button.Icon:ClearAllPoints()
        button.Icon:SetPoint("CENTER")
      end)
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
    local alpha = 1 - addonTable.Config.Get("skins.dark.chat_transparency")
    table.insert(chatFrames, frame)
    frame.background = frame:CreateTexture(nil, "BACKGROUND")
    frame.background:SetPoint("TOP", frame.ScrollingMessagesWrapper, 0, 5)
    frame.background:SetPoint("LEFT")
    frame.background:SetPoint("BOTTOMRIGHT", frame.ScrollingMessagesWrapper, 0, -5)

    hooksecurefunc(frame, "SetBackgroundColor", function(_, r, g, b)
      if not enableHooks then
        return
      end
      alpha = 1 - addonTable.Config.Get("skins.dark.chat_transparency")
      if addonTable.Config.Get("skins.dark.solid_chat_background") then
        frame.background:SetColorTexture(r, g, b, alpha)
        frame.background:SetVertexColor(1, 1, 1, 1)
      else
        frame.background:SetTexture("Interface/AddOns/Chattynator/Assets/ChatBackground")
        frame.background:SetTexCoord(0, 1, 1, 0)
        frame.background:SetVertexColor(r, g, b, alpha)
      end
    end)
    if frame.backgroundColor then
      frame:SetBackgroundColor(frame.backgroundColor.r, frame.backgroundColor.g, frame.backgroundColor.b)
    end
  end,
  ChatEditBox = function(editBox, tags)
    table.insert(editBoxes, editBox)
    for _, texName in ipairs({"Left", "Right", "Mid", "FocusLeft", "FocusRight", "FocusMid"}) do
      local tex = _G[editBox:GetName() .. texName]
      if tex then
        tex:SetParent(addonTable.hiddenFrame)
      end
    end
    local alpha = 1 - addonTable.Config.Get("skins.dark.chat_transparency")
    editBox.background = editBox:CreateTexture(nil, "BACKGROUND")
    local value = 0.1
    if addonTable.Config.Get("skins.dark.solid_chat_background") then
      value = 0
    end
    editBox.background:SetColorTexture(value, value, value, alpha)
    editBox.background:SetPoint("TOPLEFT", editBox)
    editBox.background:SetPoint("BOTTOM", editBox)
    editBox.background:SetPoint("RIGHT", editBox)
  end,
  ChatTab = function(tab, tags)
    local alpha = 1 - addonTable.Config.Get("skins.dark.tab_transparency")
    table.insert(chatTabs, tab)
    tab:SetHeight(22)
    tab:SetAlpha(1)
    tab.Left = tab:CreateTexture(nil, "BACKGROUND")
    tab.Left:SetTexture("Interface/AddOns/Chattynator/Assets/ChatTabLeft")
    tab.Left:SetHeight(22)
    tab.Left:SetWidth(6)
    tab.Left:SetPoint("TOPLEFT")
    tab.Left:SetAlpha(alpha)
    tab.Right = tab:CreateTexture(nil, "BACKGROUND")
    tab.Right:SetTexture("Interface/AddOns/Chattynator/Assets/ChatTabRight")
    tab.Right:SetHeight(22)
    tab.Right:SetWidth(6)
    tab.Right:SetPoint("TOPRIGHT")
    tab.Right:SetAlpha(alpha)
    tab.Middle = tab:CreateTexture(nil, "BACKGROUND")
    tab.Middle:SetTexture("Interface/AddOns/Chattynator/Assets/ChatTabMiddle")
    tab.Middle:SetHeight(22)
    tab.Middle:SetPoint("LEFT", 6, 0)
    tab.Middle:SetPoint("RIGHT", -6, 0)
    tab.Middle:SetAlpha(alpha)
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
    tab:GetFontString():SetWordWrap(false)
    tab:GetFontString():SetNonSpaceWrap(false)
    local fsWidth
    if tab.minWidth then
      fsWidth = tab:GetFontString():GetUnboundedStringWidth() + addonTable.Constants.TabPadding
    else
      fsWidth = math.max(tab:GetFontString():GetUnboundedStringWidth(), not tab:GetText():find("|K") and addonTable.Constants.MinTabWidth or 70) + addonTable.Constants.TabPadding
    end
    tab:GetFontString():SetWidth(fsWidth)
    tab:SetWidth(fsWidth)
    hooksecurefunc(tab, "SetText", function()
      if not enableHooks then
        return
      end
      if tab.minWidth then
        fsWidth = tab:GetFontString():GetUnboundedStringWidth() + addonTable.Constants.TabPadding
      else
        fsWidth = math.max(tab:GetFontString():GetUnboundedStringWidth(), not tab:GetText():find("|K") and addonTable.Constants.MinTabWidth or 70) + addonTable.Constants.TabPadding
      end
      tab:GetFontString():SetWidth(fsWidth)
      tab:SetWidth(fsWidth)
    end)
    table.insert(toUpdate, function()
      tab:SetText(tab:GetText())
    end)
    tab:GetFontString():SetPoint("TOP", 0, -5)
    tab:HookScript("OnEnter", function()
      if not enableHooks then
        return
      end
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
      if not enableHooks then
        return
      end
      alpha = 1 - addonTable.Config.Get("skins.dark.tab_transparency")
      if not tab:IsMouseMotionFocus() then
        tab.Left:SetAlpha(alpha)
        tab.Right:SetAlpha(alpha)
        tab.Middle:SetAlpha(alpha)
      end
      if state then
        tab:SetAlpha(1)
      else
        tab:SetAlpha(0.5)
      end
    end
    tab:HookScript("OnLeave", function()
      if not enableHooks then
        return
      end
      SetSelected(tab, tab.selected)
    end)
    hooksecurefunc(tab, "SetSelected", SetSelected)
    hooksecurefunc(tab, "SetColor", function(_, r, g, b)
      if not enableHooks then
        return
      end
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
    alpha1:SetFromAlpha(0)
    alpha1:SetToAlpha(1)
    alpha1:SetDuration(0.5)
    alpha1:SetOrder(1)
    local alpha2 = tab.FlashAnimation:CreateAnimation("Alpha")
    alpha2:SetChildKey("RightFlash")
    alpha2:SetFromAlpha(0)
    alpha2:SetToAlpha(1)
    alpha2:SetDuration(0.5)
    alpha2:SetOrder(1)
    local alpha3 = tab.FlashAnimation:CreateAnimation("Alpha")
    alpha3:SetChildKey("MiddleFlash")
    alpha3:SetFromAlpha(0)
    alpha3:SetToAlpha(1)
    alpha3:SetDuration(0.5)
    alpha3:SetOrder(1)
    hooksecurefunc(tab, "SetFlashing", function(_, state)
      if not enableHooks then
        return
      end
      tab:SetIgnoreParentAlpha(state)
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
    tex:SetTexCoord(0, 1, 1, 0)
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
    if settingName == "skins.dark.tab_transparency" then
      local alpha = 1 - addonTable.Config.Get(settingName)
      for _, tab in ipairs(chatTabs) do
        tab.Left:SetAlpha(alpha)
        tab.Right:SetAlpha(alpha)
        tab.Middle:SetAlpha(alpha)
      end
    elseif settingName == "skins.dark.chat_transparency" then
      local alpha = 1 - addonTable.Config.Get(settingName)
      for _, frame in ipairs(chatFrames) do
        frame:SetBackgroundColor(frame.backgroundColor.r, frame.backgroundColor.g, frame.backgroundColor.b)
      end
      for _, frame in ipairs(editBoxes) do
        frame.background:SetAlpha(alpha)
      end
    elseif settingName == "skins.dark.solid_chat_background" then
      local isSolid = addonTable.Config.Get(settingName)
      for _, frame in ipairs(chatFrames) do
        frame:SetBackgroundColor(frame.backgroundColor.r, frame.backgroundColor.g, frame.backgroundColor.b)
      end

      local value = 0.1
      if isSolid then
        value = 0
      end
      local alpha = 1 - addonTable.Config.Get("skins.dark.chat_transparency")
      for _, frame in ipairs(editBoxes) do
        frame.background:SetColorTexture(value, value, value, alpha)
      end
    end
  end)

  --[[local function UpdateHeader(editBox)
    if tIndexOf(editBoxes, editBox) ~= nil then
      local promptWidth = editBox.header:GetWidth() + (editBox.headerSuffix:IsShown() and editBox.headerSuffix:GetWidth() or 0) + (editBox.languageHeader and editBox.languageHeader:IsShown() and editBox.languageHeader:GetWidth() or 0)
      local wantedOffset = addonTable.Messages.inset
      local realPosition = math.max(5, 3 + addonTable.Messages.inset - promptWidth)
      if addonTable.Messages.timestampFormat == " " then
        realPosition = addonTable.Messages.inset + 2
      end
      editBox.prompt:SetPoint("LEFT", realPosition, 0)
      editBox.header:SetPoint("LEFT", realPosition, 0)
      editBox:SetTextInsets(promptWidth + realPosition, 13, 0, 0)
    end
  end
  if ChatFrame1EditBox.UpdateHeader then
    hooksecurefunc(ChatFrame1EditBox, "UpdateHeader", UpdateHeader)
  else
    hooksecurefunc("ChatEdit_UpdateHeader", UpdateHeader)
  end]]
end

addonTable.Skins.RegisterSkin(addonTable.Locales.DARK, "dark", LoadSkin, SkinFrame, SetConstants, {
  {
    type = "checkbox",
    text = addonTable.Locales.SOLID_CHAT_BACKGROUND,
    option = "solid_chat_background",
    default = false,
  },
  {
    type = "slider",
    min = 0,
    max = 100,
    lowText = "0%",
    highText = "100%",
    scale = 100,
    text = addonTable.Locales.CHAT_TRANSPARENCY,
    valuePattern = "%s%%",
    option = "chat_transparency",
    default = 0.2,
  },
  {
    type = "slider",
    min = 0,
    max = 100,
    lowText = "0%",
    highText = "100%",
    scale = 100,
    text = addonTable.Locales.TAB_TRANSPARENCY,
    valuePattern = "%s%%",
    option = "tab_transparency",
    default = 0,
  },
})
