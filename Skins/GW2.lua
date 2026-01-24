---@class addonTableChattynator
local addonTable = select(2, ...)
local GW

local intensity = {r = 83.9/100, g = 82.7/100, b = 67.8/100}
local hoverColor = {r = 1, g = 1, b = 1}

local enableHooks = true

local newTabMarkup = addonTable.Constants.NewTabMarkup
local GW2NewTabMarkup = CreateTextureMarkup("Interface/AddOns/GW2_UI/textures/party/roleicon-healer", 40, 40, 14, 14, 0, 1, 0, 1, 0, 2)

local function ConvertTags(tags)
  local res = {}
  for _, tag in ipairs(tags) do
    res[tag] = true
  end
  return res
end

local function AddHeader(frame, texture)
  frame:GwStripTextures(frame)
  GW.CreateFrameHeaderWithBody(frame, frame:GetTitleText(), texture, {})
  frame.gwHeader:ClearAllPoints()
  frame.gwHeader:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, -25)
  frame.gwHeader:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -25)
  frame.CloseButton:GwSkinButton(frame.CloseButton, true)
  frame.CloseButton:SetPoint("TOPRIGHT", -10, 4)
  frame.CloseButton:SetSize(20, 20)
end

local toUpdate = {}

local UIScaleMonitor = CreateFrame("Frame")
UIScaleMonitor:RegisterEvent("UI_SCALE_CHANGED")
UIScaleMonitor:SetScript("OnEvent", function()
  C_Timer.After(0, function()
    C_Timer.After(0, function()
      for _, func in ipairs(toUpdate) do
        func()
      end
    end)
  end)
end)

local skinners = {
  Button = function(frame)
    (frame.GwSkinButton or frame.SkinButton)(frame, false, true, false, false, false, false)
  end,
  ButtonFrame = function(frame, tags)
    frame:SetFrameStrata("HIGH")
    if tags.customise then
      AddHeader(frame, "Interface/AddOns/GW2_UI/textures/character/settings-window-icon")
      if frame.Tabs then
        frame.Tabs[1]:SetPoint("TOPLEFT", 65, -25)
        frame:HookScript("OnShow", function(self)
          if not enableHooks then
            return
          end
          local tabsWidth = self.Tabs[#self.Tabs]:GetRight() - self.Tabs[1]:GetLeft()

          self:SetWidth(math.max(self:GetWidth(), tabsWidth + 90))
        end)
      end
    elseif tags.copyChat then
      GW.HandlePortraitFrame(frame)
      GW.CreateFrameHeaderWithBody(frame, frame.TitleContainer.TitleText, "Interface/AddOns/GW2_UI/textures/character/macro-window-icon", {frame.textBox}, nil, false, true)
      frame.textBox:ClearAllPoints()
      frame.textBox:SetPoint("TOPLEFT", addonTable.Constants.ButtonFrameOffset + 10, -40)
      frame.textBox:SetPoint("BOTTOMRIGHT", -10, 10)
    else
      GW.HandlePortraitFrame(frame, true)
    end
  end,
  ChatTab = function(tab)
    tab:SetHeight(22)
    tab:SetAlpha(1)

    if tab:GetFontString() == nil then
      tab:SetText(" ")
    end
    if tab:GetFontString().GwSetFontTemplate then
      tab:GetFontString():GwSetFontTemplate(DAMAGE_TEXT_FONT, GW.TextSizeType.NORMAL)
    else
      tab:GetFontString():SetFont(DAMAGE_TEXT_FONT, 11, "")
    end
    tab:GetFontString():SetTextColor(1, 1, 1)
    tab:GetFontString():SetPoint("TOP", 0, -5)
    if tab:GetText() == newTabMarkup then
      tab:SetText(GW2NewTabMarkup)
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

    local SetText = tab.SetText
    hooksecurefunc(tab, "SetText", function(_, text)
      if not enableHooks then
        return
      end
      if text == newTabMarkup then
        SetText(tab, GW2NewTabMarkup)
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

    tab.Left = tab:CreateTexture(nil, "BACKGROUND")
    tab.Left:SetTexture("Interface/AddOns/Chattynator/Assets/ChatTabLeft")
    tab.Left:SetHeight(24)
    tab.Left:SetWidth(13)
    tab.Left:SetTexture("Interface/AddOns/GW2_UI/textures/chat/chattabactiveleft")
    tab.Left:ClearAllPoints()
    tab.Left:SetPoint("BOTTOMLEFT", 0, 1)
    tab.Left:SetBlendMode("BLEND")
    tab.Left:SetVertexColor(1, 1, 1, 1)
    tab.Right = tab:CreateTexture(nil, "BACKGROUND")
    tab.Right:SetHeight(24)
    tab.Right:SetWidth(13)
    tab.Right:SetTexture("Interface/AddOns/GW2_UI/textures/chat/chattabactiveright")
    tab.Right:ClearAllPoints()
    tab.Right:SetPoint("BOTTOMRIGHT", 0, 1)
    tab.Right:SetBlendMode("BLEND")
    tab.Right:SetVertexColor(1, 1, 1, 1)
    tab.Middle = tab:CreateTexture(nil, "BACKGROUND")
    tab.Middle:SetHeight(24)
    tab.Middle:SetTexture("Interface/AddOns/GW2_UI/textures/chat/chattabactive")
    tab.Middle:SetPoint("BOTTOMLEFT", tab.Left, "BOTTOMRIGHT")
    tab.Middle:SetPoint("BOTTOMRIGHT", tab.Right, "BOTTOMLEFT")
    tab.Middle:SetBlendMode("BLEND")
    tab.Middle:SetVertexColor(1, 1, 1, 1)
    tab.glow = tab:CreateTexture(nil, "BORDER")
    tab.glow:SetTexture("Interface\\AddOns\\Chattynator\\Assets\\ElvUIChatTabNewMessageFlash")
    tab.glow:SetPoint("BOTTOMLEFT", 8, 0)
    tab.glow:SetPoint("BOTTOMRIGHT", -8, 0)
    tab.glow:SetAlpha(0)

    hooksecurefunc(tab, "SetSelected", function(_, state)
      if not enableHooks then
        return
      end
      tab.Left:SetShown(state)
      tab.Right:SetShown(state)
      tab.Middle:SetShown(state)
    end)
    if tab.selected ~= nil then
      tab:SetSelected(tab.selected)
    end

    hooksecurefunc(tab, "SetColor", function(_, r, g, b)
      tab.glow:SetVertexColor(r, g, b)
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
      tab.glow:SetShown(state)
      tab.FlashAnimation:SetPlaying(state)
    end)
  end,
  ChatEditBox = function(frame)
    _G[frame:GetName() .. "Left"]:GwKill()
    _G[frame:GetName() .. "Right"]:GwKill()
    _G[frame:GetName() .. "Mid"]:GwKill()
    if _G[frame:GetName() .. "FocusLeft"] then
      _G[frame:GetName() .. "FocusLeft"]:SetColorTexture(0, 0, 0, 0)
      _G[frame:GetName() .. "FocusRight"]:SetColorTexture(0, 0, 0, 0)
      _G[frame:GetName() .. "FocusMid"]:SetColorTexture(0, 0, 0, 0)
    end
    frame.backgroundTex = frame:CreateTexture(nil, "BACKGROUND")
    frame.backgroundTex:SetTexture("Interface/AddOns/GW2_UI/textures/chat/chateditboxmid")
    frame.backgroundTex:SetPoint("BOTTOMLEFT")
    frame.backgroundTex:SetPoint("BOTTOMRIGHT")
    frame.backgroundTex:SetHeight(32)
  end,
  ChatFrame = function(frame)
    frame.visuals = CreateFrame("Frame", nil, frame)
    frame.visuals:SetFrameStrata("BACKGROUND")
    frame.visuals:SetFrameLevel(0)
    frame.visuals:SetAllPoints()
    frame.visuals.backgroundTex = frame.visuals:CreateTexture(nil, "BACKGROUND")
    frame.visuals.backgroundTex:SetTexture("Interface/AddOns/GW2_UI/textures/chat/chatframebackground")
    frame.visuals.backgroundTex:SetPoint("TOPLEFT", frame, 0, -22)
    frame.visuals.backgroundTex:SetPoint("BOTTOMRIGHT", frame.ScrollingMessagesWrapper, 0, -7)
    frame.visuals.borderTex = frame.visuals:CreateTexture(nil, "ARTWORK")
    frame.visuals.borderTex:SetSize(2, 2)
    frame.visuals.borderTex:SetTexture("Interface/AddOns/GW2_UI/textures/chat/chatframeborder")
    frame.visuals.borderTex:SetPoint("TOPRIGHT", frame, 0, -22)
    frame.visuals.borderTex:SetPoint("BOTTOMRIGHT", frame.ScrollingMessagesWrapper, 0, -7)
    frame.visuals.dockTex = frame.visuals:CreateTexture(nil, "BACKGROUND")
    frame.visuals.dockTex:SetTexture("Interface/AddOns/GW2_UI/textures/chat/chatdockbg")
    frame.visuals.dockTex:SetHeight(25)
    frame.visuals.dockTex:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, -22)
    frame.visuals.dockTex:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -22)
    if frame:GetID() == 1 then
      frame:SetClampRectInsets(0, 0, 0, -16)
      if frame:GetBottom() < 16 then
        frame:AdjustPointsOffset(0, 16 - frame:GetBottom())
      end
    end

    frame.visuals.fakeEditBoxTex = frame.visuals:CreateTexture(nil, "BACKGROUND")
    frame.visuals.fakeEditBoxTex:SetTexture("Interface/AddOns/GW2_UI/textures/chat/chateditboxmid")
    frame.visuals.fakeEditBoxTex:SetPoint("BOTTOMLEFT")
    frame.visuals.fakeEditBoxTex:SetPoint("BOTTOMRIGHT")
    frame.visuals.fakeEditBoxTex:SetHeight(32)
    frame.visuals.fakeEditBoxTex:SetScale(addonTable.Core.GetFontScalingFactor())

    local position = addonTable.Config.Get(addonTable.Config.Options.EDIT_BOX_POSITION)
    frame.visuals.fakeEditBoxTex:SetShown(position == "bottom")

    frame.ScrollingMessagesWrapper:SetIgnoreParentAlpha(true)
    frame.fadeOutAnimation = frame:CreateAnimationGroup()
    frame.fadeOutAnimation:SetToFinalAlpha(true)
    local alpha1 = frame.fadeOutAnimation:CreateAnimation("Alpha")
    alpha1:SetFromAlpha(1)
    alpha1:SetToAlpha(0)
    alpha1:SetDuration(0.5)
    alpha1:SetOrder(1)
    alpha1:SetChildKey("visuals")
    local alpha11 = frame.fadeOutAnimation:CreateAnimation("Alpha")
    alpha11:SetFromAlpha(1)
    alpha11:SetToAlpha(0)
    alpha11:SetDuration(0.5)
    alpha11:SetOrder(1)
    alpha11:SetChildKey("TabsBar")
    frame.fadeInAnimation = frame:CreateAnimationGroup()
    frame.fadeInAnimation:SetToFinalAlpha(true)
    local alpha2 = frame.fadeInAnimation:CreateAnimation("Alpha")
    alpha2:SetFromAlpha(0)
    alpha2:SetToAlpha(1)
    alpha2:SetDuration(0.5)
    alpha2:SetOrder(1)
    alpha2:SetChildKey("visuals")
    local alpha21 = frame.fadeInAnimation:CreateAnimation("Alpha")
    alpha21:SetFromAlpha(0)
    alpha21:SetToAlpha(1)
    alpha21:SetDuration(0.5)
    alpha21:SetOrder(1)
    alpha21:SetChildKey("TabsBar")
    frame.GW2HoverTracker = CreateFrame("Frame", nil, frame)
    frame.GW2HoverTracker:SetAllPoints()
    frame.GW2HoverTracker:SetFrameStrata("DIALOG")
    local function Show()
      frame.fadeOutAnimation:Stop()
      if frame.visuals:GetAlpha() < 1 then
        frame.fadeInAnimation:Play()
      end
      frame.GW2HoverTracker:SetScript("OnUpdate", function()
        if not frame:IsMouseOver() and not ChatFrame1EditBox:IsVisible() then
          frame.fadeInAnimation:Stop()
          if frame.visuals:GetAlpha() > 0 then
            frame.fadeOutAnimation:Play()
          end
          frame.GW2HoverTracker:SetScript("OnUpdate", nil)
        end
      end)
    end
    frame.GW2HoverTracker:SetScript("OnEnter", function()
      Show()
    end)
    if frame:GetID() == 1 then
      ChatFrame1EditBox:SetIgnoreParentAlpha(true)
      ChatFrame1EditBox:HookScript("OnShow", function()
        Show()
      end)
    end
    frame.GW2HoverTracker:SetPropagateMouseMotion(true)
    frame.GW2HoverTracker:SetPropagateMouseClicks(true)
    frame.GW2HoverTracker:SetShown(addonTable.Config.Get("skins.gw2_ui.fade_chat"))
    if addonTable.Config.Get("skins.gw2_ui.fade_chat") then
      frame.visuals:SetAlpha(0)
      frame.TabsBar:SetAlpha(0)
    end

    addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
      if not enableHooks then
        return
      end
      if settingName == addonTable.Config.Options.EDIT_BOX_POSITION then
        position = addonTable.Config.Get(addonTable.Config.Options.EDIT_BOX_POSITION)
        frame.visuals.fakeEditBoxTex:SetShown(position == "bottom")
      elseif settingName == "skins.gw2_ui.fade_chat" then
        local fadeStatus = addonTable.Config.Get("skins.gw2_ui.fade_chat")
        frame.GW2HoverTracker:SetShown(fadeStatus)
        if fadeStatus then
          Show()
        else
          frame.fadeOutAnimation:Stop()
          frame.fadeInAnimation:Stop()
          frame:SetAlpha(1)
        end
      end
    end)
  end,
  ChatButton = function(button, tags)
    button:SetSize(26, 28)
    button:ClearNormalTexture()
    button:ClearPushedTexture()
    button:ClearHighlightTexture()
    button.HoverIcon = button:CreateTexture(nil, "OVERLAY")
    button.HoverIcon:Hide()
    button.HoverIcon:SetSize(18, 18)

    button:HookScript("OnEnter", function()
      if not enableHooks then
        return
      end
      button.HoverIcon:Show()
    end)
    button:HookScript("OnLeave", function()
      if not enableHooks then
        return
      end
      button.HoverIcon:Hide()
    end)

    button:HookScript("OnMouseDown", function()
      if not enableHooks then
        return
      end
      button.Icon:AdjustPointsOffset(2, -2)
      button.HoverIcon:AdjustPointsOffset(2, -2)
    end)
    button:HookScript("OnMouseUp", function()
      if not enableHooks then
        return
      end
      button.Icon:AdjustPointsOffset(-2, 2)
      button.HoverIcon:AdjustPointsOffset(-2, 2)
    end)

    if tags.toasts then
      if not button.Icon then
        button.Icon = button:CreateTexture(nil, "ARTWORK")
      end
      if button.FriendsButton then
        button.FriendsButton:GwKill()
      end
      button:SetSize(32, 35)
      button.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/SocialChatButton")
      button.Icon:SetDrawLayer("ARTWORK")
      button.Icon:SetSize(20, 20)
      button.Icon:ClearAllPoints()
      button.Icon:SetPoint("TOP", 0, -2)
      button.HoverIcon:SetPoint("TOP", 0, -2)
      button.HoverIcon:SetSize(20, 20)
      button.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/SocialChatButton-Highlight")
      button.HoverIcon:SetBlendMode("ADD")
    elseif tags.channels then
      button.Flash:SetSize(18, 18)
      hooksecurefunc(button, "SetIconToState", function(self, joined)
        if not enableHooks then
          return
        end
        button:ClearNormalTexture()
        button:ClearPushedTexture()
        button:ClearHighlightTexture()
        if joined then
          self.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_button_vc")
          self.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_button_vc_highlight")
          self.Flash:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_button_vc_highlight")
        else
          self.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_button_normal")
          self.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_button_normal_highlight")
          self.Flash:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_button_normal_highlight")
        end
      end)
      button:UpdateVisibleState()
    elseif tags.voiceChatNoAudio then
      button:SetWidth(20)
      hooksecurefunc(button, "SetIconToState", function(self, deafened)
        if not enableHooks then
          return
        end
        button:ClearNormalTexture()
        button:ClearPushedTexture()
        button:ClearHighlightTexture()
        if deafened then
            self.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_vc_sound_off")
            self.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_vc_sound_off_highlight")
        else
            self.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_vc_sound_on")
            self.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_vc_sound_on_highlight")
        end
      end)
      button:UpdateVisibleState()
    elseif tags.voiceChatMuteMic then
      button:SetWidth(20)
      hooksecurefunc(button, "SetIconToState", function(self, state)
        if not enableHooks then
          return
        end
        button:ClearNormalTexture()
        button:ClearPushedTexture()
        button:ClearHighlightTexture()
        if state == MUTE_SILENCE_STATE_NONE then -- mic on
          self.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_vc_mic_on")
          self.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_vc_mic_on_highlight")
        elseif state == MUTE_SILENCE_STATE_MUTE then -- mic off
          self.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_vc_mic_off")
          self.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_vc_mic_off_highlight")
        elseif state == MUTE_SILENCE_STATE_SILENCE then -- mic silenced on
          self.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_vc_mic_silenced_on")
          self.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_vc_mic_silenced_on_highlight")
        elseif state == MUTE_SILENCE_STATE_MUTE_AND_SILENCE then -- mic silenced off
          self.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_vc_mic_silenced_off")
          self.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_vc_mic_silenced_off_highlight")
        end
      end)
      button:UpdateVisibleState()
    elseif tags.menu then
      button.Icon = button:CreateTexture(nil, "ARTWORK")
      button.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/bubble_up")
      button.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/bubble_down")
      button.HoverIcon:SetBlendMode("ADD")
      button.Icon:SetPoint("CENTER")
      button.HoverIcon:SetPoint("CENTER")
      button.Icon:SetSize(18, 18)
    else
      button.Icon = button:CreateTexture(nil, "ARTWORK")
      button.Icon:SetSize(18, 18)
      if tags.search then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/Search.png")
        button.Icon:SetSize(15, 15)
        button.HoverIcon:SetTexture(button.Icon:GetTexture())
        button.HoverIcon:SetVertexColor(hoverColor.r, hoverColor.g, hoverColor.b)
        button.HoverIcon:SetSize(15, 15)
      elseif tags.copy then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/Copy.png")
        button.Icon:SetSize(15, 15)
        button.HoverIcon:SetTexture(button.Icon:GetTexture())
        button.HoverIcon:SetVertexColor(hoverColor.r, hoverColor.g, hoverColor.b)
        button.HoverIcon:SetSize(15, 15)
      elseif tags.settings then
        button.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/icons/MainMenuMicroButton-Down")
        button.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/icons/MainMenuMicroButton-Up")
      elseif tags.scrollToEnd then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/ScrollToBottom.png")
        button.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/uistuff/arrowdown_down")
      end
      button.Icon:SetVertexColor(intensity.r, intensity.g, intensity.b)
      button.Icon:SetPoint("CENTER")
      button.HoverIcon:SetPoint("CENTER")
    end
  end,
  TabButton = function(frame)
    if GW.HandleTabs then
      GW.HandleTabs(frame, false)
    else
      frame:GwStripTextures(frame)
      frame:GwSkinButton(frame, false, true, false, false, false, false)
      if Chattynator.Constants.IsRetail then
        -- Work around GW2 bug on retail where the hover texture doesn't hide
        -- properly
        frame:HookScript("OnDisable", function()
          if not enableHooks then
            return
          end
          frame.hover:SetAlpha(0)
        end)
        frame:HookScript("OnShow", function()
          if not enableHooks then
            return
          end
          frame.hover:SetAlpha(0)
        end)
        frame:HookScript("OnEnable", function()
          if not enableHooks then
            return
          end
          frame.hover:SetAlpha(0)
        end)
      end
    end
  end,
  TopTabButton = function(frame)
    if GW.HandleTabs then
      GW.HandleTabs(frame, "bottom")
    else
      frame:GwStripTextures(frame)
      frame:GwSkinButton(frame, false, true, false, false, false, false)
      if Chattynator.Constants.IsRetail then
        -- Work around GW2 bug on retail where the hover texture doesn't hide
        -- properly
        frame:HookScript("OnDisable", function()
          if not enableHooks then
            return
          end
          frame.hover:SetAlpha(0)
        end)
        frame:HookScript("OnEnable", function()
          if not enableHooks then
            return
          end
          frame.hover:SetAlpha(0)
        end)
      end
    end
  end,
  CheckBox = function(frame)
    frame:GwSkinCheckButton(frame)
    frame:SetPoint("TOP", 0, -12)
    frame:SetSize(15, 15)
  end,
  Slider = function(frame)
    frame = frame.Slider
    frame:GwSkinSliderFrame(frame)
    frame:GetThumbTexture():SetSize(16, 16)
    frame.tex:SetDrawLayer("ARTWORK")
    frame.tex:SetPoint("TOPLEFT", 0, 2)
    frame.tex:SetPoint("BOTTOMRIGHT", 0, -2)
  end,
  InsetFrame = function(frame)
    frame.Bg:Hide()
    frame:GwStripTextures(frame)
    if frame.NineSlice then
      frame.NineSlice:Hide()
    end
    if GW.BackdropTemplates and GW.BackdropTemplates.ColorableBorderOnly then
      Mixin(frame, BackdropTemplateMixin)
      frame:SetBackdrop(GW.BackdropTemplates.ColorableBorderOnly)
      frame:SetBackdropBorderColor(0, 0, 0, 1)
    end
  end,
  Divider = function(tex)
    tex:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    tex:SetPoint("TOPLEFT", 0, 0)
    tex:SetPoint("TOPRIGHT", 0, 0)
    tex:SetHeight(1)
    tex:SetColorTexture(1, 0.93, 0.73, 0.45)
  end,
  Dropdown = function(button)
    button:GwHandleDropDownBox(nil, nil, nil)
    button:OnEnter() -- Fix text colour
    button.Text:SetPoint("LEFT", 10, -2)
    button.backdrop:SetPoint("TOPLEFT", -5, 0)
    button:SetHitRectInsets(-5, 0, 0, 0)
  end,
  Dialog = function(frame)
    frame:GwStripTextures(frame)
    if frame.NineSlice then
      frame.NineSlice:Hide()
    end
    frame:GwCreateBackdrop(frame)
    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(frame)
    tex:SetTexture("Interface/AddOns/GW2_UI/textures/party/manage-group-bg")
    frame.tex = tex
  end,
  ResizeWidget = function(frame, tags)
    local tex = frame:CreateTexture(nil, "ARTWORK")
    tex:SetVertexColor(intensity.r, intensity.g, intensity.b)
    tex:SetTexture("Interface/AddOns/GW2_UI/textures/uistuff/resize")
    tex:SetTexCoord(0, 1, 1, 0)
    tex:SetAllPoints()
    frame:SetScript("OnEnter", function()
      tex:SetVertexColor(hoverColor.r, hoverColor.g, hoverColor.b)
    end)
    frame:SetScript("OnLeave", function()
      tex:SetVertexColor(intensity.r, intensity.g, intensity.b)
    end)
  end,
}

local function SkinFrame(details)
  local func = skinners[details.regionType]
  if func then
    func(details.region, details.tags and #details.tags > 0 and ConvertTags(details.tags) or {})
  end
end

local function SetConstants()
  addonTable.Constants.ButtonFrameOffset = 0
end

local function LoadSkin()
  GW = GW2_ADDON
  addonTable.Core.OverwriteDefaultFont("GW2_UI_Chat")

  addonTable.Messages:AddLiveModifier(function(data)
    if data.typeInfo.channel then
      data.text = data.text:gsub("(|Hchannel:channel.-|h.-|h)", "|cffd0d0d0%1|r")
    end
  end)
end

if addonTable.Skins.IsAddOnLoading("GW2_UI") then
  addonTable.Skins.RegisterSkin(addonTable.Locales.GW2_UI, "gw2_ui", LoadSkin, SkinFrame, SetConstants, {
    {
      type = "checkbox",
      text = addonTable.Locales.FADE_CHAT_WHEN_NOT_IN_USE,
      option = "fade_chat",
      default = true,
    },
  }, true)
end
