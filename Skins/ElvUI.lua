---@class addonTableChattynator
local addonTable = select(2, ...)

local intensity = 1
local hoverColor
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

local hidden = CreateFrame("Frame")
hidden:Hide()
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
    S:HandleEditBox(editBox)
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
  ChatTab = function(tab)
    tab:SetHeight(22)
    tab:SetNormalFontObject("GameFontNormal")
    if tab:GetFontString() == nil then
      tab:SetText(" ")
    end
    local tabPadding = 30
    if tab.minWidth then
      tab:SetWidth(tab:GetFontString():GetUnboundedStringWidth() + tabPadding)
    else
      tab:SetWidth(math.max(tab:GetFontString():GetUnboundedStringWidth(), 80) + tabPadding)
    end
    local SetText = tab.SetText
    local text = tab:GetText()
    hooksecurefunc(tab, "SetText", function(_, cleanText)
      text = cleanText
      if tab.minWidth then
        tab:SetWidth(tab:GetFontString():GetUnboundedStringWidth() + tabPadding)
      else
        tab:SetWidth(math.max(tab:GetFontString():GetUnboundedStringWidth(), 80) + tabPadding)
      end
    end)
    hooksecurefunc(tab, "SetSelected", function(_, state)
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
  end,
  ChatFrame = function(frame)
    if frame:GetID() == 1 then
      LeftChatPanel:ClearAllPoints()
      LeftChatPanel:SetPoint("TOPLEFT", frame)
      LeftChatPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 24)
    else
      frame:CreateBackdrop()
      local panelColor = CH.db.panelColor
      frame:SetBackdropColor(panelColor.r, panelColor.g, panelColor.b, panelColor.a)
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
    S:HandleSliderFrame(frame)
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
end

if addonTable.Skins.IsAddOnLoading("ElvUI") then
  local frame = CreateFrame("Frame")
  frame:SetScript("OnEvent", function()
    addonTable.Core.OverwriteDefaultFont("default")
  end)
  frame:RegisterEvent("PLAYER_LOGIN")
  addonTable.Skins.RegisterSkin(addonTable.Locales.ELVUI, "elvui", LoadSkin, SkinFrame, SetConstants, {
    {
      type = "checkbox",
      text = addonTable.Locales.USE_EXPRESSWAY_FONT_ON_ITEMS,
      option = "use_bag_font",
      rightText = addonTable.Locales.RELOAD_REQUIRED,
      default = false,
    },
  }, true)
end
