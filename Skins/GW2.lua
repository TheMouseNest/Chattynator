---@class addonTableChattynator
local addonTable = select(2, ...)
local GW

local intensity = {r = 83.9/100, g = 82.7/100, b = 67.8/100}
local hoverColor = {r = 1, g = 1, b = 1}

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
  (frame.GwStripTextures or frame.StripTextures)(frame)
  GW.CreateFrameHeaderWithBody(frame, frame:GetTitleText(), texture, {})
  frame.gwHeader:ClearAllPoints()
  frame.gwHeader:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, -25)
  frame.gwHeader:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -25)
  ;(frame.CloseButton.GwSkinButton or frame.CloseButton.SkinButton)(frame.CloseButton, true)
  frame.CloseButton:SetPoint("TOPRIGHT", -10, 4)
  frame.CloseButton:SetSize(20, 20)
end

local hidden = CreateFrame("Frame")
hidden:Hide()

local skinners = {
  Button = function(frame)
    (frame.GwSkinButton or frame.SkinButton)(frame, false, true, false, false, false, false)
  end,
  ButtonFrame = function(frame, tags)
    frame:SetFrameStrata("HIGH")
    if tags.customise then
      AddHeader(frame, "Interface/AddOns/GW2_UI/textures/character/settings-window-icon")
      frame.Tabs[1]:SetPoint("TOPLEFT", 65, -25)
      frame:HookScript("OnShow", function(self)
        local tabsWidth = self.Tabs[#self.Tabs]:GetRight() - self.Tabs[1]:GetLeft()

        self:SetWidth(math.max(self:GetWidth(), tabsWidth + 90))
      end)
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
    tab:GetFontString():GwSetFontTemplate(DAMAGE_TEXT_FONT, GW.TextSizeType.NORMAL)
    tab:GetFontString():SetTextColor(1, 1, 1)
    tab:GetFontString():SetPoint("TOP", 0, -5)
    local tabPadding = 10
    if tab:GetText() == newTabMarkup then
      tab:SetText(GW2NewTabMarkup)
    end
    if tab.minWidth then
      tab:SetWidth(tab:GetFontString():GetUnboundedStringWidth() + tabPadding)
    else
      tab:SetWidth(math.max(tab:GetFontString():GetUnboundedStringWidth(), 80) + tabPadding)
    end

    local SetText = tab.SetText
    hooksecurefunc(tab, "SetText", function(_, text)
      if text == newTabMarkup then
        SetText(tab, GW2NewTabMarkup)
      end
      if tab.minWidth then
        tab:SetWidth(tab:GetFontString():GetUnboundedStringWidth() + tabPadding)
      else
        tab:SetWidth(math.max(tab:GetFontString():GetUnboundedStringWidth(), 80) + tabPadding)
      end
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

    hooksecurefunc(tab, "SetSelected", function(_, state)
      tab.Left:SetShown(state)
      tab.Right:SetShown(state)
      tab.Middle:SetShown(state)
    end)
    if tab.selected ~= nil then
      tab:SetSelected(tab.selected)
    end
  end,
  ChatEditBox = function(frame)
    _G[frame:GetName() .. "Left"]:GwKill()
    _G[frame:GetName() .. "Right"]:GwKill()
    _G[frame:GetName() .. "Mid"]:GwKill()
    _G[frame:GetName() .. "FocusLeft"]:GwKill()
    _G[frame:GetName() .. "FocusRight"]:GwKill()
    _G[frame:GetName() .. "FocusMid"]:GwKill()
    if GW.settings.CHAT_USE_GW2_STYLE then
      local chatFont = GW.Libs.LSM:Fetch("font", "GW2_UI_Chat")
      local _, _, fontFlags = frame:GetFont()
      frame:SetFont(chatFont, addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FONT_SIZE), fontFlags)
      _G[frame:GetName() .. "Header"]:SetFont(chatFont, addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FONT_SIZE), fontFlags)
    end
  end,
  ChatFrame = function(frame)
    frame.background = CreateFrame("Frame", nil, frame, "GwChatContainer")
    frame.background:SetPoint("TOPLEFT", 0, -22)
    frame.background:SetPoint("BOTTOMRIGHT")
    frame.background:Show()
    if frame:GetID() == 1 then
      frame:SetClampRectInsets(0, 0, 0, -16)
      if frame:GetBottom() < 16 then
        frame:AdjustPointsOffset(0, 16 - frame:GetBottom())
      end
    end
  end,
  ChatButton = function(button, tags)
    button:SetSize(26, 28);
    button:ClearNormalTexture()
    button:ClearPushedTexture()
    button:ClearHighlightTexture()
    button.HoverIcon = button:CreateTexture(nil, "OVERLAY")
    button.HoverIcon:Hide()
    button.HoverIcon:SetSize(15, 15)

    button:HookScript("OnEnter", function()
      button.HoverIcon:Show()
    end)
    button:HookScript("OnLeave", function()
      button.HoverIcon:Hide()
    end)

    button:HookScript("OnMouseDown", function()
      button.Icon:AdjustPointsOffset(2, -2)
      button.HoverIcon:AdjustPointsOffset(2, -2)
    end)
    button:HookScript("OnMouseUp", function()
      button.Icon:AdjustPointsOffset(-2, 2)
      button.HoverIcon:AdjustPointsOffset(-2, 2)
    end)

    if tags.toasts then
      button.Icon = button:CreateTexture(nil, "ARTWORK")
      button.FriendsButton:GwKill()
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

      button:HookScript("OnEnter", function()
        button.FriendCount:SetTextColor(hoverColor.r, hoverColor.g, hoverColor.b)
      end)
      button:HookScript("OnLeave", function()
        button.FriendCount:SetTextColor(intensity.r, intensity.g, intensity.b)
      end)
    elseif tags.channels then
      button.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_button_normal")
      button.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/channel_button_normal_highlight")
      button.HoverIcon:SetBlendMode("ADD")
    elseif tags.menu then
      button.Icon = button:CreateTexture(nil, "ARTWORK")
      button.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/bubble_up")
      button.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/chat/bubble_down")
      button.HoverIcon:SetBlendMode("ADD")
      button.Icon:SetPoint("CENTER")
      button.HoverIcon:SetPoint("CENTER")
      button.Icon:SetSize(15, 15)
    else
      button.Icon = button:CreateTexture(nil, "ARTWORK")
      if tags.search then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/Search.png")
      elseif tags.copy then
        button.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/uistuff/maximize_button")
      elseif tags.settings then
        button.Icon:SetTexture("Interface/AddOns/GW2_UI/textures/icons/MainMenuMicroButton-Down")
        button.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/icons/MainMenuMicroButton-Up")
      elseif tags.scrollToEnd then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/ScrollToBottom.png")
        button.HoverIcon:SetTexture("Interface/AddOns/GW2_UI/textures/uistuff/arrowdown_down")
      end
      button.Icon:SetVertexColor(intensity.r, intensity.g, intensity.b)
      if button.HoverIcon:GetTexture() == nil then
        button.HoverIcon:SetTexture(button.Icon:GetTexture())
        button.HoverIcon:SetVertexColor(hoverColor.r, hoverColor.g, hoverColor.b)
      end
      button.Icon:SetPoint("CENTER")
      button.HoverIcon:SetPoint("CENTER")
      button.Icon:SetSize(15, 15)
    end
  end,
  TabButton = function(frame)
    if GW.HandleTabs then
      GW.HandleTabs(frame, false)
    else
      (frame.GwStripTextures or frame.StripTextures)(frame)
      ;(frame.GwSkinButton or frame.SkinButton)(frame, false, true, false, false, false, false)
      if Chattynator.Constants.IsRetail then
        -- Work around GW2 bug on retail where the hover texture doesn't hide
        -- properly
        frame:HookScript("OnDisable", function()
          frame.hover:SetAlpha(0)
        end)
        frame:HookScript("OnShow", function()
          frame.hover:SetAlpha(0)
        end)
        frame:HookScript("OnEnable", function()
          frame.hover:SetAlpha(0)
        end)
      end
    end
  end,
  TopTabButton = function(frame)
    if GW.HandleTabs then
      GW.HandleTabs(frame, "bottom")
    else
      (frame.GwStripTextures or frame.StripTextures)(frame)
      ;(frame.GwSkinButton or frame.SkinButton)(frame, false, true, false, false, false, false)
      if Chattynator.Constants.IsRetail then
        -- Work around GW2 bug on retail where the hover texture doesn't hide
        -- properly
        frame:HookScript("OnDisable", function()
          frame.hover:SetAlpha(0)
        end)
        frame:HookScript("OnEnable", function()
          frame.hover:SetAlpha(0)
        end)
      end
    end
  end,
  CheckBox = function(frame)
    (frame.GwSkinCheckButton or frame.SkinCheckButton)(frame)
    frame:SetPoint("TOP", 0, -12)
    frame:SetSize(15, 15)
  end,
  Slider = function(frame)
    (frame.GwSkinSliderFrame or frame.SkinSliderFrame)(frame)
    frame:GetThumbTexture():SetSize(16, 16)
    frame.tex:SetDrawLayer("ARTWORK")
    frame.tex:SetPoint("TOPLEFT", 0, 2)
    frame.tex:SetPoint("BOTTOMRIGHT", 0, -2)
  end,
  InsetFrame = function(frame)
    frame.Bg:Hide()
    ;(frame.GwStripTextures or frame.StripTextures)(frame)
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
    (frame.GwStripTextures or frame.StripTextures)(frame)
    if frame.NineSlice then
      frame.NineSlice:Hide()
    end
    ;(frame.GwCreateBackdrop or frame.CreateBackdrop)(frame)
    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(frame)
    tex:SetTexture("Interface/AddOns/GW2_UI/textures/party/manage-group-bg")
    frame.tex = tex
  end,
  ResizeWidget = function(frame, tags)
    local tex = frame:CreateTexture(nil, "ARTWORK")
    tex:SetVertexColor(intensity.r, intensity.g, intensity.b)
    tex:SetTexture("Interface/AddOns/GW2_UI/textures/uistuff/resize")
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
end

if addonTable.Skins.IsAddOnLoading("GW2_UI") then
  addonTable.Skins.RegisterSkin(addonTable.Locales.GW2_UI, "gw2_ui", LoadSkin, SkinFrame, SetConstants, {}, true)
end
