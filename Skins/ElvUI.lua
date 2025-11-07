---@class addonTableChattynator
local addonTable = select(2, ...)

local enableHooks = true

local intensity = 1
local hoverColor
local voiceActiveColor = {r = 33/255, g = 209/255, b = 45/255}
local flashTabColor = {r = 247/255, g = 222/255, b = 61/255}

local E
local S
local B
local LSM
local CH

local function ConvertTags(tags)
  local res = {}
  for _, tag in ipairs(tags) do
    res[tag] = true
  end
  return res
end

local toUpdate = {}

local UIScaleMonitor = CreateFrame("Frame")
UIScaleMonitor:RegisterEvent("UI_SCALE_CHANGED")
UIScaleMonitor:SetScript("OnEvent", function()
  for _, func in ipairs(toUpdate) do
    func()
  end
end)

local skinners = {
  Button = function(frame)
    S:HandleButton(frame)
  end,
  ButtonFrame = function(frame)
    S:HandlePortraitFrame(frame)
  end,
  SearchBox = function(frame)
    S:HandleEditBox(frame)
  end,
  EditBox = function(frame)
    S:HandleEditBox(frame)
  end,
  ChatEditBox = function(editBox)
    for _, texName in ipairs({"Left", "Right", "Mid", "FocusLeft", "FocusRight", "FocusMid"}) do
      local tex = _G[editBox:GetName() .. texName]
      if tex then
        tex:SetParent(addonTable.hiddenFrame)
      end
    end
    editBox:SetHeight(22)
    S:HandleEditBox(editBox)
    editBox.backdrop:SetPoint("TOPLEFT", 1, 0)
    editBox.backdrop:SetPoint("RIGHT", -1, 0)
    local _, size = editBox:GetFont()
    editBox:FontTemplate(LSM:Fetch('font', CH.db.font), size, CH.db.fontOutline)
    addonTable.allChatFrames[1]:UpdateEditBox()
  end,
  TabButton = function(frame)
    S:HandleTab(frame)
  end,
  ChatButton = function(button, tags)
    button:SetSize(26, 28)
    button:ClearNormalTexture()
    button:ClearPushedTexture()
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
        button:ClearNormalTexture()
        button:ClearPushedTexture()
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
        button:ClearNormalTexture()
        button:ClearHighlightTexture()
        button:ClearPushedTexture()
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
  ChatTab = function(tab)
    tab:SetHeight(22)
    tab:SetNormalFontObject("GameFontNormal")
    if tab:GetFontString() == nil then
      tab:SetText(" ")
    end
    tab.glow = tab:CreateTexture(nil, "BORDER")
    tab.glow:SetTexture("Interface\\AddOns\\Chattynator\\Assets\\ElvUIChatTabNewMessageFlash")
    tab.glow:SetPoint("BOTTOMLEFT", 8, -2)
    tab.glow:SetPoint("BOTTOMRIGHT", -8, -2)
    tab.glow:SetAlpha(0)
    tab:GetFontString():SetWordWrap(false)
    tab:GetFontString():SetNonSpaceWrap(false)
    tab:GetFontString():FontTemplate(LSM:Fetch('font', CH.db.tabFont), CH.db.tabFontSize, CH.db.tabFontOutline)
    local fsWidth
    if tab.minWidth then
      fsWidth = tab:GetFontString():GetUnboundedStringWidth() + addonTable.Constants.TabPadding
    else
      fsWidth = math.max(tab:GetFontString():GetUnboundedStringWidth(), not tab:GetText():find("|K") and addonTable.Constants.MinTabWidth or 70) + addonTable.Constants.TabPadding
    end
    tab:GetFontString():SetWidth(fsWidth)
    tab:SetWidth(fsWidth)
    local SetText = tab.SetText
    local text = tab:GetText()
    hooksecurefunc(tab, "SetText", function(_, cleanText)
      if not enableHooks then
        return
      end
      text = cleanText
      if tab.minWidth then
        fsWidth = tab:GetFontString():GetUnboundedStringWidth() + addonTable.Constants.TabPadding
      else
        fsWidth = math.max(tab:GetFontString():GetUnboundedStringWidth(), not tab:GetText():find("|K") and addonTable.Constants.MinTabWidth or 70) + addonTable.Constants.TabPadding
      end
      tab:GetFontString():SetWidth(fsWidth)
      tab:SetWidth(fsWidth)
    end)
    hooksecurefunc(tab, "SetSelected", function(_, state)
      if not enableHooks then
        return
      end
      if state then
        tab:GetFontString():SetTextColor(1, 1, 1)
        if CH.db.tabSelector ~= 'NONE' then
          local hexColor = E:RGBToHex(tab.color.r, tab.color.g, tab.color.b) or '|cff4cff4c'
          tab:SetFormattedText(CH.TabStyles[CH.db.tabSelector] or CH.TabStyles.ARROW1, hexColor, text, hexColor)
        else
          SetText(tab, text)
        end
      else
        tab:SetText(text)
        tab:GetFontString():SetTextColor(unpack(E.media.rgbvaluecolor))
      end
    end)
    if tab.selected ~= nil then
      tab:SetSelected(tab.selected)
    end

    hooksecurefunc(tab, "SetColor", function(_, r, g, b)
      tab.glow:SetVertexColor(r, g, b)
      tab:SetSelected(tab.selected)
    end)
    if tab.color then
      tab:SetColor(tab.color.r, tab.color.g, tab.color.b)
    end

    tab.FlashAnimation = tab:CreateAnimationGroup()
    tab.FlashAnimation:SetLooping("BOUNCE")
    local alpha2 = tab.FlashAnimation:CreateAnimation("Alpha")
    alpha2:SetChildKey("glow")
    alpha2:SetFromAlpha(0)
    alpha2:SetToAlpha(1)
    alpha2:SetDuration(0.8)
    alpha2:SetOrder(1)
    hooksecurefunc(tab, "SetFlashing", function(_, state)
      if not enableHooks then
        return
      end
      tab.FlashAnimation:SetPlaying(state)
    end)
    table.insert(toUpdate, function()
      tab:SetText(text)
      if tab.selected ~= nil then
        tab:SetSelected(tab.selected)
      end
    end)
    if tab.selected ~= nil then
      tab:SetSelected(tab.selected)
    end
  end,
  ChatFrame = function(frame)
    if frame:GetID() == 1 then
      local function AnchorDataPanel()
        local position = addonTable.Config.Get(addonTable.Config.Options.EDIT_BOX_POSITION)
        local isAbove = E.db.chat.LeftChatDataPanelAnchor == 'ABOVE_CHAT'
        LeftChatPanel:SetParent(addonTable.hiddenFrame)
        LeftChatDataPanel:ClearAllPoints()
        LeftChatDataPanel:SetParent(frame)
        LeftChatDataPanel:SetPoint(isAbove and "BOTTOMLEFT" or "TOPLEFT", frame, isAbove and "TOPLEFT" or "BOTTOMLEFT", E.db.chat.hideChatToggles and -1 or 18, position == "bottom" and not isAbove and 22 or 0)
        LeftChatDataPanel:SetPoint(isAbove and "BOTTOMRIGHT" or "TOPRIGHT", frame, isAbove and "TOPRIGHT" or "BOTTOMRIGHT", 1, position == "bottom" and not isAbove and 22 or 0)
        LeftChatDataPanel:SetHeight(23)
        LeftChatToggleButton:SetParent(frame)
        local panelEnabled = E.db.datatexts.panels.LeftChatDataPanel.enable
        frame:SetClampRectInsets(0, 0, panelEnabled and isAbove and 25 or 0, panelEnabled and position == "top" and not isAbove and -25 or 0)
        frame:UpdateEditBox()
      end
      local function PositionPanel()
        AnchorDataPanel()
        addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
          if not enableHooks then
            return
          end
          if settingName == addonTable.Config.Options.EDIT_BOX_POSITION then
            AnchorDataPanel()
          end
        end)
      end
      if not LeftChatDataPanel then
        hooksecurefunc(E:GetModule('Layout'), "CreateChatPanels", PositionPanel)
      else
        PositionPanel()
      end
      hooksecurefunc(E:GetModule('Layout'), "RepositionChatDataPanels", AnchorDataPanel)
      hooksecurefunc(E:GetModule('Layout'), "RefreshChatMovers", AnchorDataPanel)
    end
    if E.db.chat.panelBackdrop ~= "HIDEBOTH" then
      frame:CreateBackdrop('Transparent')
      local panelColor = CH.db.panelColor
      frame.backdrop:SetBackdropColor(panelColor.r, panelColor.g, panelColor.b, panelColor.a)
    end
  end,
  TopTabButton = function(frame)
    S:HandleTab(frame)
  end,
  TrimScrollBar = function(frame)
    S:HandleTrimScrollBar(frame)
  end,
  CheckBox = function(frame)
    S:HandleCheckBox(frame)
  end,
  Slider = function(frame)
    S:HandleStepSlider(frame)
  end,
  InsetFrame = function(frame)
    if frame.NineSlice then
      frame.NineSlice:SetTemplate("Transparent")
    else
      S:HandleInsetFrame(frame)
    end
  end,
  Dropdown = function(button)
    S:HandleDropDownBox(button)
  end,
  Dialog = function(frame)
    frame:StripTextures()
    frame:SetTemplate('Transparent')
  end,
  ResizeWidget = function(frame, tags)
    local tex = frame:CreateTexture(nil, "ARTWORK")
    tex:SetVertexColor(intensity, intensity, intensity)
    tex:SetTexture("Interface/AddOns/Chattynator/Assets/resize.png")
    tex:SetTexCoord(0, 1, 1, 0)
    tex:SetAllPoints()
    frame:SetScript("OnEnter", function()
      tex:SetVertexColor(59/255, 210/255, 237/255)
    end)
    frame:SetScript("OnLeave", function()
      tex:SetVertexColor(1, 1, 1)
    end)
  end,
}

local function SkinFrame(details)
  local func = skinners[details.regionType]
  if func then
    func(details.region, details.tags and ConvertTags(details.tags) or {})
  end
end

local function SetConstants()
  addonTable.Constants.ButtonFrameOffset = 0
end

local function LoadSkin()
  E = unpack(ElvUI)
  S = E:GetModule("Skins")
  B = E:GetModule('Bags')
  LSM = E.Libs.LSM
  CH = E:GetModule('Chat')
  hoverColor = {r = E.media.rgbvaluecolor[1], g = E.media.rgbvaluecolor[2], b = E.media.rgbvaluecolor[3]}
  local options = {CH.db.font, E.db.general.font, "Friz Quadrata TT"}
  for _, font in ipairs(options) do
    if LSM:Fetch("font", font, true) then
      addonTable.Core.OverwriteDefaultFont(font)
      break
    end
  end
end

if addonTable.Skins.IsAddOnLoading("ElvUI") then
  addonTable.Skins.RegisterSkin(addonTable.Locales.ELVUI, "elvui", LoadSkin, SkinFrame, SetConstants, {
  }, true)
end
