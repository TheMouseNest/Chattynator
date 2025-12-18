---@class addonTableChattynator
local addonTable = select(2, ...)

local rightInset = 3

---@class DisplayScrollingMessages: Frame
addonTable.Display.ScrollingMessagesMixin = {}

function addonTable.Display.ScrollingMessagesMixin:MyOnLoad()
  self:SetHyperlinkPropagateToParent(true)
  self:SetClipsChildren(true)
  self:SetFlattensRenderLayers(true)

  self.scrollIndex = 1

  self.visibleLines = {}

  self.currentFadeOffsetTime = 0
  self.accumulatedTime = 0
  self.timestampOffset = GetTime() - time()

  self.pool = CreateFontStringPool(self, "BACKGROUND", 0, addonTable.Messages.font)
  self.barPool = CreateTexturePool(self, "BACKGROUND")

  do
    local edgeFadeTop = 20
    local edgeFadeLeft = 0
    local edgeFadeRight = 0
    local edgeFadeBottom = 0

    self:SetAlphaGradient(0, CreateVector2D(edgeFadeLeft, edgeFadeTop))
    self:SetAlphaGradient(1, CreateVector2D(edgeFadeRight, edgeFadeBottom))
  end

  self:SetScript("OnMouseWheel", function(_, delta)
    self.currentFadeOffsetTime = GetTime()
    local multiplier = 1
    if IsShiftKeyDown() then
      multiplier = 1000
    elseif IsControlKeyDown() then
      multiplier = 5
    end
    if delta > 0 then
      self:ScrollByAmount(1 * multiplier)
    else
      self:ScrollByAmount(-1 * multiplier)
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("MessageDisplayChanged", function()
    self:Render()
  end)

  addonTable.CallbackRegistry:RegisterCallback("RefreshStateChange", function(_, refreshState)
    if refreshState[addonTable.Constants.RefreshReason.MessageWidget] then
      self:Render()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.ENABLE_MESSAGE_FADE or settingName == addonTable.Config.Options.MESSAGE_FADE_TIME then
      self:UpdateAlphas()
    end
  end)
end

function addonTable.Display.ScrollingMessagesMixin:Reset()
  self.scrollIndex = 1
  self.currentFadeOffsetTime = 0
end

function addonTable.Display.ScrollingMessagesMixin:ScrollByAmount(amount)
  self.scrollIndex = math.max(1, self.scrollIndex + amount)
  self.scrollCallback()

  self:Render()
end

function addonTable.Display.ScrollingMessagesMixin:PageUp()
  self:ScrollByAmount(1)
end

function addonTable.Display.ScrollingMessagesMixin:PageDown()
  self:ScrollByAmount(-1)
end

function addonTable.Display.ScrollingMessagesMixin:ScrollToBottom()
  self.scrollIndex = 1
  self.scrollCallback()
  self:Render()
end

function addonTable.Display.ScrollingMessagesMixin:AtBottom()
  return self.scrollIndex == 1
end

function addonTable.Display.ScrollingMessagesMixin:SetOnScrollChangedCallback(callback)
  self.scrollCallback = callback
end

function addonTable.Display.ScrollingMessagesMixin:Clear()
  self.visibleLines = {}
  self.pool:ReleaseAll()
  self.barPool:ReleaseAll()
end

function addonTable.Display.ScrollingMessagesMixin:SetFilter(filterFunc)
  self.filterFunc = filterFunc
end

function addonTable.Display.ScrollingMessagesMixin:UpdateAlphas(elapsed)
  if elapsed then
    self.accumulatedTime = self.accumulatedTime + elapsed
    if self.animationsPending then
      local any = false
      for _, fs in ipairs(self.visibleLines) do
        if fs.animationTime ~= fs.animationFinalTime then
          any = true
          fs.animationTime = math.min(fs.animationFinalTime, fs.animationTime + elapsed)
          local alpha = fs.animationStart + (1 - (1 - fs.animationTime/fs.animationFinalTime) ^ 2) * fs.animationDestination
          fs:SetAlpha(alpha)
          fs.timestamp:SetAlpha(alpha)
          if fs.bar then
            fs.bar:SetAlpha(alpha)
          end
          fs:SetShown(alpha > 0)
        end
      end

      if not any then
        self.animationsPending = false
      end
    end
    if self.accumulatedTime < 1 then
      return

    else
      self.accumulatedTime = 0
    end
  end

  local fadeTime = addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FADE_TIME)
  local fadeEnabled = addonTable.Config.Get(addonTable.Config.Options.ENABLE_MESSAGE_FADE)
  local currentTime = GetTime()

  local any = false
  local faded = false
  for i = #self.visibleLines, 1, -1 do
    local fs = self.visibleLines[i]
    if fs then
      local alpha = fs:GetAlpha()
      fs:SetShown(alpha > 0)
      fs.timestamp:SetShown(alpha > 0)
      if fs.bar then
        fs.bar:SetShown(alpha > 0)
      end

      if fadeEnabled and self.scrollIndex == 1 and math.max(fs.timestampValue + self.timestampOffset, self.currentFadeOffsetTime) + fadeTime - currentTime < 0 then
        if not faded and self.accumulatedTime == 0 and alpha ~= 0 and (fs.animationFinalAlpha ~= 0 or fs.animationFinalTime == 0) then
          faded = true
          any = true
          fs.animationTime = 0
          fs.animationStart = alpha
          fs.animationFinalTime = 3
          fs.animationDestination = 0 - alpha
          fs.animationFinalAlpha = 0
        end
      elseif not fadeEnabled then
        fs.animationFinalAlpha = nil
        fs.animationTime = nil
        fs.animationStart = nil
        fs.animationFinalTime = nil
        fs.animationDestination = nil
        fs:SetAlpha(1)
        fs:Show()
        fs.timestamp:SetAlpha(1)
        fs.timestamp:Show()
        if fs.bar then
          fs.bar:SetAlpha(1)
          fs.bar:Show()
        end
      elseif alpha == 1 then
        any = true
      end
    end
  end

  if any then
    self.animationsPending = true
    self:SetScript("OnUpdate", self.UpdateAlphas)
  end
end

function addonTable.Display.ScrollingMessagesMixin:Render(newMessages)
  if self.currentFadeOffsetTime == 0 then
    self.currentFadeOffsetTime = GetTime()
  end

  if newMessages == nil then
    self:Clear()
  end
  local tmp = self.pool:Acquire()
  local lines = math.ceil(self:GetHeight() / tmp:GetLineHeight())
  self.pool:Release(tmp)

  local index = 1
  local messages = {}
  while (newMessages and self.scrollIndex == 1 and index <= newMessages) or (not newMessages and #messages < self.scrollIndex + lines - 1) do
    local m = addonTable.Messages:GetMessageRaw(index)
    if not m then
      break
    end
    if m.recordedBy == addonTable.Data.CharacterName and (not self.filterFunc or self.filterFunc(m)) then
      m = addonTable.Messages:GetMessageProcessed(index)
      table.insert(messages, m)
    end
    index = index + 1
  end

  if #messages > 0 then
    local start = math.min(#messages, self.scrollIndex)
    while #self.visibleLines > 0 and #self.visibleLines >= lines - math.min(lines, #messages) do
      local fs = table.remove(self.visibleLines)
      self.pool:Release(fs.timestamp)
      fs.timestamp = nil
      if fs.bar then
        self.barPool:Release(fs.bar)
        fs.bar = nil
      end
      self.pool:Release(fs)
    end
    for i = start + math.min(#messages, lines) - 1, start, -1 do
      local m = messages[i]
      if m then
        local fs = self.pool:Acquire()
        fs:SetFontObject(addonTable.Messages.font)
        fs:SetTextColor(1, 1, 1)
        fs:SetJustifyH("LEFT")
        fs:SetPoint("LEFT", self, addonTable.Messages.inset + 3, 0)
        fs:SetPoint("RIGHT", self)
        fs:SetPoint("BOTTOM", self, 0, 2)
        fs:SetText(m.text)
        fs:SetTextColor(m.color.r, m.color.g, m.color.b)
        fs:SetTextScale(addonTable.Messages.scalingFactor)
        fs:SetAlpha(1)
        fs.animationTime = nil
        fs.animationStart = nil
        fs.animationFinalTime = nil
        fs.animationDestination = nil
        fs.animationFinalAlpha = nil
        fs:Show()
        if self.visibleLines[1] then
          self.visibleLines[1]:SetPoint("BOTTOM", fs, "TOP", 0, addonTable.Messages.spacing)
        end
        local timestamp = self.pool:Acquire()
        timestamp:SetFontObject(addonTable.Messages.font)
        timestamp:SetTextColor(0.6, 0.6, 0.6)
        timestamp:SetJustifyH("LEFT")
        timestamp:SetPoint("LEFT")
        timestamp:SetPoint("TOP", fs)
        timestamp:SetTextScale(addonTable.Messages.scalingFactor)
        timestamp:Show()
        timestamp:SetText(date(addonTable.Messages.timestampFormat, m.timestamp))
        timestamp:SetAlpha(1)
        fs.timestampValue = m.timestamp
        fs.timestamp = timestamp
        if addonTable.Config.Get(addonTable.Config.Options.SHOW_TIMESTAMP_SEPARATOR) then
          local bar = self.barPool:Acquire()
          bar:Show()
          bar:SetTexture("Interface/AddOns/Chattynator/Assets/Fade.png")
          bar:SetPoint("RIGHT", fs, "LEFT", -4, 0)
          bar:SetPoint("TOP", fs)
          bar:SetPoint("BOTTOM", fs, 0, 1)
          bar:SetWidth(2)
          bar:SetAlpha(1)
          fs.bar = bar
        end
        table.insert(self.visibleLines, 1, fs)
      end
    end

    self:UpdateAlphas()
  end
end
