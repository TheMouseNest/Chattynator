---@class addonTableChattynator
local addonTable = select(2, ...)

local rightInset = 3

---@class DisplayScrollingMessages: Frame
addonTable.Display.ScrollingMessagesMixin = {}

function addonTable.Display.ScrollingMessagesMixin:OnLoad()
  self:SetClipsChildren(true)

  self:SetHyperlinkPropagateToParent(true)

  self.messagePool = CreateFramePool("Frame", self, nil, nil, false, function(frame)
    Mixin(frame, addonTable.Display.MessageRowMixin)
    frame:OnLoad()
    frame:UpdateWidgets(self.currentStringWidth)
  end)
  ---@type DisplayMessageRow[]
  self.allocated = {}
  self.activeFrames = {}

  self.currentFadeOffsetTime = 0
  self.scrollOffset = 0
  self.panExtent = 50
  self.scrollInterpolator = CreateInterpolator(InterpolatorUtil.InterpolateEaseOut)
  self.destination = 0

  self.timestampOffset = GetTime() - time()

  addonTable.CallbackRegistry:RegisterCallback("MessageDisplayChanged", function()
    self:ResetFading()
    self:UpdateWidth()
    self:UpdateAllocated()
  end)

  addonTable.CallbackRegistry:RegisterCallback("ResetOneMessageCache", function(_, id)
    for index, frame in ipairs(self.activeFrames) do
      if frame.data.id == id then
        frame.data = nil
        table.remove(self.activeFrames, index)
        break
      end
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("RefreshStateChange", function(_, state)
    if state[addonTable.Constants.RefreshReason.MessageModifier] then
      self.cleanRender = true
    elseif state[addonTable.Constants.RefreshReason.MessageWidget] then
      self:UpdateAllocated()
      if self:GetParent():GetID() ~= 0 then
        self:Render()
      end
    end
  end)

  self:SetScript("OnMouseWheel", self.OnMouseWheel)
  self:SetScript("OnSizeChanged", function()
    self:UpdateWidth()
    self:UpdateAllocated()
    if self:GetTop() and self:GetBottom() then
      self:Render()
    end
  end)
  self:UpdateWidth()

  self:SetPropagateMouseMotion(true)
  self:SetPropagateMouseClicks(true)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if self:GetParent():GetID() == 0 then
      return
    end
    if settingName == addonTable.Config.Options.ENABLE_MESSAGE_FADE then
      self:UpdateAlphas()
    end
  end)

  self.scrollCallback = nil
end

function addonTable.Display.ScrollingMessagesMixin:Reset()
  self:ResetFading()
  self.currentFadeOffsetTime = 0

  self.scrollInterpolator:Cancel()
  self.destination = 0
  self.scrollOffset = 0
  if self.scrollCallback then
    self.scrollCallback(self.destination)
  end
end

function addonTable.Display.ScrollingMessagesMixin:ScrollTo(target, easyMode)
  self.destination = math.max(0, target)
  if self.scrollCallback then
    self.scrollCallback(self.destination)
  end
  if self.destination == self.scrollOffset then -- Already done
    self:UpdateAlphas()
    return
  end
  self.isScrolling = true
  if easyMode then
    self.scrollInterpolator:Interpolate(self.scrollOffset, target, 0.11, function(value)
      local diff = self.scrollOffset - value
      for _, f in ipairs(self.activeFrames) do
        f:AdjustPointsOffset(0, diff)
      end
      self.scrollOffset = value
      self:UpdateAlphas()
    end, function()
      self.isScrolling = false
    end)
  else
    self.scrollInterpolator:Interpolate(self.scrollOffset, target, 0.11, function(value)
      self.scrollOffset = value
      self:Render()
    end, function()
      self.isScrolling = false
    end)
  end
end

function addonTable.Display.ScrollingMessagesMixin:ScrollToEnd(easyMode)
  self:ScrollTo(0, easyMode)
end

function addonTable.Display.ScrollingMessagesMixin:ScrollBy(diff)
  self:ScrollTo(self.scrollOffset + diff)
end

function addonTable.Display.ScrollingMessagesMixin:OnMouseWheel(delta)
  if delta > 0 then
    delta = 1
  elseif delta < 0 then
    delta = -1
  end
  self.currentFadeOffsetTime = GetTime()
  local multiplier = 1
  if IsShiftKeyDown() then
    multiplier = 1000
  elseif IsControlKeyDown() then
    multiplier = 5
  end
  self:ScrollBy(self.panExtent * delta * multiplier)
end

function addonTable.Display.ScrollingMessagesMixin:UpdateAllocated()
  for _, f in ipairs(self.allocated) do
    f:UpdateWidgets(self.currentStringWidth)
    self.cleanRender = true
  end
end

function addonTable.Display.ScrollingMessagesMixin:UpdateWidth()
  local width = math.floor(self:GetWidth() - addonTable.Messages.inset - rightInset)
  if width <= 0 then
    return
  end
  addonTable.Messages:RegisterWidth(width)
  if self.currentStringWidth then
    addonTable.Messages:UnregisterWidth(self.currentStringWidth)
  end
  self.currentStringWidth = width
  self.key = width
end

function addonTable.Display.ScrollingMessagesMixin:UpdateAlphas(elapsed)
  if elapsed then
    self.accumulatedTime = (self.accumulatedTime or 0) + elapsed
    if self.animationsPending then
      local any = false
      for _, f in ipairs(self.activeFrames) do
        if f.animationTime ~= f.animationFinalTime then
          any = true
          f.animationTime = math.min(f.animationFinalTime, f.animationTime + elapsed)
          f:SetAlpha(f.animationStart + (1 - (1 - f.animationTime/f.animationFinalTime) ^ 2) * f.animationDestination)
          f:SetShown(f:GetAlpha() > 0)
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

  local lineHeight = self.activeFrames[1] and self.activeFrames[1].DisplayString:GetLineHeight() * 0.9 or 0

  local any = false
  local top, bottom = self:GetTop(), self:GetBottom()
  local faded = false
  for _, f in ipairs(self.activeFrames) do
    local alpha = f:GetAlpha()
    f:SetShown(alpha > 0)

    if fadeEnabled and self.destination == 0 and math.max(f.data.timestamp + self.timestampOffset, self.currentFadeOffsetTime) + fadeTime - currentTime < 0 then
      if not faded and self.accumulatedTime == 0 and alpha ~= 0 and (f.animationFinalAlpha ~= 0 or f.animationFinalTime == 0) then
        faded = true
        any = true
        f.animationTime = 0
        f.animationStart = alpha
        f.animationFinalTime = 3
        f.animationDestination = 0 - alpha
        f.animationFinalAlpha = 0
      end
    elseif f:GetBottom() - top > - lineHeight or f:GetTop() - bottom < lineHeight then
      if alpha ~= 0.5 and (f.animationFinalAlpha ~= 0.5 or f.animationFinalTime == 0) then
        any = true
        f.animationTime = 0
        f.animationStart = alpha
        f.animationFinalTime = 0.2
        f.animationDestination = 0.5 - alpha
        f.animationFinalAlpha = 0.5
      end
    elseif alpha ~= 1 and (f.animationFinalAlpha ~= 1 or f.animationFinalTime == 0) then
      any = true
      f.animationTime = 0
      f.animationFinalTime = 0.11 -- Same as scrolling
      f.animationStart = alpha
      f.animationDestination = 1 - alpha
      f.animationFinalAlpha = 1
    end
  end

  if any then
    self.animationsPending = true
    self:SetScript("OnUpdate", self.UpdateAlphas)
  end
end

function addonTable.Display.ScrollingMessagesMixin:ResetFading()
  self.currentFadeOffsetTime = GetTime()
end

function addonTable.Display.ScrollingMessagesMixin:SetFilter(filterFunc)
  self.filterFunc = filterFunc
end

function addonTable.Display.ScrollingMessagesMixin:Render(newMessages)
  self.scrollOffset = math.max(0, self.scrollOffset)

  if self.currentFadeOffsetTime == 0 then
    self.currentFadeOffsetTime = GetTime()
  end

  local viewportHeight = self:GetHeight()
  local messageSpacing = addonTable.Config.Get(addonTable.Config.Options.MESSAGE_SPACING)
  local allocatedHeight = 0
  local shownMessages = {}
  local index = 1
  local correctedOffset = nil
  while allocatedHeight < viewportHeight + self.scrollOffset do
    local m = addonTable.Messages:GetMessageRaw(index)
    if not m then
      break
    end
    if m.recordedBy == addonTable.Data.CharacterName and (not self.filterFunc or self.filterFunc(m)) then
      m = addonTable.Messages:GetMessageProcessed(index)
      local heights = addonTable.Messages:GetMessageHeight(index)
      table.insert(shownMessages, {
        data = m,
        height = heights[self.key],
        extentBottom = allocatedHeight,
        extentTop = allocatedHeight + heights[self.key] + messageSpacing,
        index = index,
      })
      if not correctedOffset and newMessages and index >= newMessages + 1 then
        correctedOffset = true
        if #shownMessages == 1 and not self.cleanRender then
          return
        else
          self.scrollOffset = self.scrollOffset + shownMessages[#shownMessages].extentBottom
          correctedOffset = shownMessages[#shownMessages].extentBottom
        end
      end
      allocatedHeight = allocatedHeight + heights[self.key] + messageSpacing
    end
    index = index + 1
  end

  if newMessages == #shownMessages then
    self.scrollOffset = self.scrollOffset + allocatedHeight
    correctedOffset = allocatedHeight
  end

  if #shownMessages > 0 and shownMessages[#shownMessages].extentTop < self.scrollOffset + viewportHeight and self.scrollOffset ~= 0 and (not correctedOffset or self.scrollOffset > correctedOffset) then
    self.scrollOffset = math.max(0, allocatedHeight - viewportHeight, correctedOffset or 0)
    self.destination = self.scrollOffset
    if self.scrollCallback then
      self.scrollCallback(self.destination)
    end
  end

  local shift = 0
  if self.destination == 0 and self.scrollOffset ~= 0 and self.scrollOffset < viewportHeight and newMessages then
    shift = self.scrollOffset
  end

  local known = {}
  self.startingIndex = nil
  for _, info in ipairs(shownMessages) do
    info.fromBottom = info.extentBottom - self.scrollOffset
    info.show = info.extentTop - self.scrollOffset + shift >= 0 and info.fromBottom <= viewportHeight
    known[info.data.id] = info.show
    if not self.startingIndex and info.show then
      self.startingIndex = info.index
    end
  end
  local toReplace = {}
  local toReuse = {}
  for _, a in ipairs(self.allocated) do
    if a.data and known[a.data.id] and not self.cleanRender then
      toReuse[a.data.id] = a
    else
      a:Hide()
      table.insert(toReplace, a)
      a.data = nil
    end
  end
  self.cleanRender = false
  self.activeFrames = {}
  for _, info in ipairs(shownMessages) do
    if info.show then
      local frame = toReuse[info.data.id]
      if not frame then
        frame = table.remove(toReplace)
        if not frame then
          frame = self.messagePool:Acquire()
          table.insert(self.allocated, frame)
        end
        frame:Show()
        frame:SetWidth(self:GetWidth())
        frame:SetHeight(info.height + messageSpacing)
        frame:SetData(info.data)
      end
      frame:SetPoint("BOTTOM", 0, info.fromBottom)
      table.insert(self.activeFrames, 1, frame)
    end
  end
  self:UpdateAlphas()

  if self.destination == 0 and self.scrollOffset ~= 0 and (newMessages or not self.isScrolling) then
    self:ScrollToEnd(shift > 0)
  end
end
