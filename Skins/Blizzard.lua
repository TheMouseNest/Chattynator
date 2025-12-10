---@class addonTableChattynator
local addonTable = select(2, ...)

local enableHooks = true

local toUpdate = {}

local UIScaleMonitor = CreateFrame("Frame")
UIScaleMonitor:RegisterEvent("UI_SCALE_CHANGED")
UIScaleMonitor:SetScript("OnEvent", function()
  for _, func in ipairs(toUpdate) do
    func()
  end
end)

local counter = 0

local chatTabs = {}
local chatFrames = {}
local chatButtons = {}

local skinners = {
  ChatButton = function(button, tags)
    button:SetSize(26, 28)


    if tags.toasts then
    elseif tags.channels then
    elseif tags.voiceChatNoAudio or tags.voiceChatMuteMic then
    else
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

      button:SetNormalTexture("chatframe-button-up")
      button:SetPushedTexture("chatframe-button-down")
      button:SetHighlightTexture("chatframe-button-highlight")

      button.Icon = button:CreateTexture(nil, "OVERLAY")
      if tags.search then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/Search.png")
      elseif tags.copy then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/Copy.png")
      elseif tags.settings then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/SettingsCog.png")
      elseif tags.scrollToEnd then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/ScrollToBottom.png")
      elseif tags.menu then
        button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/ChatMenu.png")
      end
      button.Icon:SetPoint("CENTER")
      button.Icon:SetSize(12, 12)
      button.Icon:SetVertexColor(0.925, 0.804, 0.063)
    end
  end,
  ChatFrame = function(frame, tags)
    local alpha = 1 - addonTable.Config.Get("skins.blizzard.chat_transparency")
    table.insert(chatFrames, frame)
    frame.background = CreateFrame("Frame", nil, frame, "FloatingBorderedFrame")
    frame.background:SetFrameStrata("BACKGROUND")
    frame.background:SetFrameLevel(frame:GetFrameLevel() - 1)
    frame.background:SetPoint("TOPLEFT", frame.ScrollingMessagesWrapper, 0, 2)
    frame.background:SetPoint("BOTTOMRIGHT", frame.ScrollingMessagesWrapper)

    hooksecurefunc(frame, "SetBackgroundColor", function(_, r, g, b)
      for _, region in ipairs({frame.background:GetRegions()}) do
        region:SetVertexColor(r, g, b)
      end
    end)
    if frame.backgroundColor then
      frame:SetBackgroundColor(frame.backgroundColor.r, frame.backgroundColor.g, frame.backgroundColor.b)
    end
    frame.background:SetAlpha(alpha)
  end,
  ChatEditBox = function(editBox, tags)
  end,
  ChatTab = function(tab, tags)
    local alpha = 1 - addonTable.Config.Get("skins.blizzard.tab_transparency")
    table.insert(chatTabs, tab)
    counter = counter + 1
    tab.background = CreateFrame("Frame", "ChattynatorBlizzardTabStyle" .. counter, tab, "ChatTabArtTemplate")
    if not tab.background.ActiveLeft then
      tab.background.ActiveLeft = _G[tab.background:GetName() .. "SelectedLeft"]
      tab.background.ActiveRight = _G[tab.background:GetName() .. "SelectedRight"]
      tab.background.ActiveMiddle = _G[tab.background:GetName() .. "SelectedMiddle"]
      tab.background.HighlightLeft = _G[tab.background:GetName() .. "HighlightLeft"]
      tab.background.HighlightRight = _G[tab.background:GetName() .. "HighlightRight"]
      tab.background.HighlightMiddle = _G[tab.background:GetName() .. "HighlightMiddle"]
      tab.background.Left = _G[tab.background:GetName() .. "Left"]
      tab.background.Right = _G[tab.background:GetName() .. "Right"]
      tab.background.Middle = _G[tab.background:GetName() .. "Middle"]
    end
    tab.background:SetAllPoints()
    if addonTable.Constants.IsClassic then
      tab.background:AdjustPointsOffset(0, 10)
      tab.background.Left:ClearAllPoints()
      tab.background.Left:SetPoint("TOPLEFT", -3, 0)
      tab.background.Right:ClearAllPoints()
      tab.background.Right:SetPoint("TOPRIGHT", 3, 0)
      tab.background.Middle:SetPoint("RIGHT", tab.background.Right, "LEFT")
    else
      tab.background.Left:AdjustPointsOffset(-3, 0)
      tab.background.Right:AdjustPointsOffset(3, 0)
    end
    tab.background.glow:Show()
    tab.background.glow:SetAlpha(0)
    tab.background:SetFrameStrata("BACKGROUND")
    tab.background:SetAlpha(alpha)
    tab.background:SetFrameLevel(tab:GetFrameLevel() - 1)

    hooksecurefunc(tab, "SetColor", function(_, r, g, b)
      if not enableHooks then
        return
      end
      tab.background.glow:SetVertexColor(r, g, b)
      tab.background.ActiveLeft:SetVertexColor(r, g, b)
      tab.background.ActiveRight:SetVertexColor(r, g, b)
      tab.background.ActiveMiddle:SetVertexColor(r, g, b)
      tab.background.HighlightLeft:SetVertexColor(r, g, b)
      tab.background.HighlightRight:SetVertexColor(r, g, b)
      tab.background.HighlightMiddle:SetVertexColor(r, g, b)
    end)
    tab.background.ActiveLeft:Hide()
    tab.background.ActiveRight:Hide()
    tab.background.ActiveMiddle:Hide()
    if tab.color then
      tab:SetColor(tab.color.r, tab.color.g, tab.color.b)
    end
    tab:SetHeight(22)
    tab:SetAlpha(1)
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
    tab:HookScript("OnEnter", function()
      if not enableHooks then
        return
      end
      tab.background.HighlightLeft:Show()
      tab.background.HighlightRight:Show()
      tab.background.HighlightMiddle:Show()
      tab.background.ActiveLeft:Show()
      tab.background.ActiveRight:Show()
      tab.background.ActiveMiddle:Show()
      if not tab.selected then
        tab:SetAlpha(0.6)
      else
        tab:SetAlpha(1)
      end
    end)
    local function SetSelected(_, state)
      if not enableHooks then
        return
      end
      alpha = 1 - addonTable.Config.Get("skins.blizzard.tab_transparency")
      if not tab:IsMouseMotionFocus() then
        tab.background:SetAlpha(alpha)
      end
      if state then
        tab.background.ActiveLeft:Show()
        tab.background.ActiveRight:Show()
        tab.background.ActiveMiddle:Show()
        tab:SetAlpha(0.8)
      else
        tab.background.ActiveLeft:Hide()
        tab.background.ActiveRight:Hide()
        tab.background.ActiveMiddle:Hide()
        tab:SetAlpha(0.3)
      end

      if tab:IsMouseMotionFocus() then
        tab:GetScript("OnEnter")(tab)
      end
    end
    tab:HookScript("OnLeave", function()
      if not enableHooks then
        return
      end
      tab.background.HighlightLeft:Hide()
      tab.background.HighlightRight:Hide()
      tab.background.HighlightMiddle:Hide()
      tab.background.ActiveLeft:Hide()
      tab.background.ActiveRight:Hide()
      tab.background.ActiveMiddle:Hide()
      SetSelected(tab, tab.selected)
    end)
    hooksecurefunc(tab, "SetSelected", SetSelected)
    if tab.color then
      tab:SetColor(tab.color.r, tab.color.g, tab.color.b)
    end
    if tab.selected ~= nil then
      tab:SetSelected(tab.selected)
    end

    tab.background.FlashAnimation = tab.background:CreateAnimationGroup()
    tab.background.FlashAnimation:SetLooping("BOUNCE")
    local alpha2 = tab.background.FlashAnimation:CreateAnimation("Alpha")
    alpha2:SetChildKey("glow")
    alpha2:SetFromAlpha(0)
    alpha2:SetToAlpha(1)
    alpha2:SetDuration(0.8)
    alpha2:SetOrder(1)
    hooksecurefunc(tab, "SetFlashing", function(_, state)
      if not enableHooks then
        return
      end
      tab.background.FlashAnimation:SetPlaying(state)
    end)
  end,
  ResizeWidget = function(frame, tags)
    frame:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    frame:GetNormalTexture():SetTexCoord(0, 1, 1, 0)
    frame:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    frame:GetPushedTexture():SetTexCoord(0, 1, 1, 0)
    frame:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    frame:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    frame:GetHighlightTexture():SetTexCoord(0, 1, 1, 0)
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
    if settingName == "skins.blizzard.tab_transparency" then
      local alpha = 1 - addonTable.Config.Get(settingName)
      for _, tab in ipairs(chatTabs) do
        tab.background:SetAlpha(alpha)
      end
    elseif settingName == "skins.blizzard.chat_transparency" then
      local alpha = 1 - addonTable.Config.Get(settingName)
      for _, frame in ipairs(chatFrames) do
        frame.background:SetAlpha(alpha)
      end
    end
  end)
end

addonTable.Skins.RegisterSkin(addonTable.Locales.BLIZZARD, "blizzard", LoadSkin, SkinFrame, SetConstants, {
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
    default = 0.75,
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
