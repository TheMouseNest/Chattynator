---@class addonTableChattynator
local addonTable = select(2, ...)

local rightInset = 10

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
  self.panExtent = 100
  self.scrollInterpolator = CreateInterpolator(InterpolatorUtil.InterpolateEaseOut)
  self.destination = 0

  self.firstRender = true

  self.timestampOffset = GetTime() - time()

  addonTable.CallbackRegistry:RegisterCallback("MessageDisplayChanged", function()
    self:UpdateWidth()
    self:UpdateAllocated()
  end)

  self:SetScript("OnMouseWheel", self.OnMouseWheel)
  self:SetScript("OnSizeChanged", function()
    self:UpdateWidth()
    self:UpdateAllocated()
    if not self.firstRender then
      self:Render()
    end
  end)

  self:SetScript("OnUpdate", self.UpdateAlphas)

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
end

function addonTable.Display.ScrollingMessagesMixin:ScrollTo(target, easyMode)
  self.destination = math.max(0, target)
  if self.scrollCallback then
    self.scrollCallback(self.destination)
  end
  if self.destination == self.scrollOffset then -- Already done
    return
  end
  if easyMode then
    self.scrollInterpolator:Interpolate(self.scrollOffset, target, 0.11, function(value)
      local diff = self.scrollOffset - value
      for _, f in ipairs(self.activeFrames) do
        f:AdjustPointsOffset(0, diff)
      end
      self.scrollOffset = value
      self:UpdateAlphas()
      --self:Render()
    end)
  else
    self.scrollInterpolator:Interpolate(self.scrollOffset, target, 0.11, function(value)
      self.scrollOffset = value
      self:Render()
    end)
  end
end

function addonTable.Display.ScrollingMessagesMixin:ScrollToEnd(easyMode)
  self:ScrollTo(0, easyMode)
end

function addonTable.Display.ScrollingMessagesMixin:OnMouseWheel(delta)
  if delta > 0 then
    delta = 1
  else
    delta = -1
  end
  self.currentFadeOffsetTime = GetTime()
  self:ScrollTo(self.scrollOffset + self.panExtent * delta)
end

function addonTable.Display.ScrollingMessagesMixin:UpdateAllocated()
  for _, f in ipairs(self.allocated) do
    f:UpdateWidgets(self.currentStringWidth)
    f.data = nil
  end
end

function addonTable.Display.ScrollingMessagesMixin:UpdateWidth()
  local width = math.floor(self:GetWidth() - addonTable.Messages.inset - rightInset)
  addonTable.Messages:RegisterWidth(width)
  if self.currentStringWidth then
    addonTable.Messages:UnregisterWidth(self.currentStringWidth)
  end
  self.currentStringWidth = width
  self.key = width
end

function addonTable.Display.ScrollingMessagesMixin:UpdateAlphas(elapsed)
  if elapsed then
    self.accummulatedTime = (self.accummulatedTime or 0) + elapsed
    if self.accummulatedTime < 1 then
      return
    else
      self.accummulatedTime = 0
    end
  end

  local fadeTime = addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FADE_TIME)
  local fadeEnabled = addonTable.Config.Get(addonTable.Config.Options.ENABLE_MESSAGE_FADE)
  local currentTime = GetTime()

  local lineHeight = self.activeFrames[1] and self.activeFrames[1].DisplayString:GetLineHeight() * 0.9 or 0

  self.alphas = {}
  self.lastFadeTime = self.lastFadeTime or currentTime
  local top, bottom = self:GetTop(), self:GetBottom()
  for _, f in ipairs(self.activeFrames) do
    local targetAlpha, duration = nil, 0.2

    local alpha = f:GetAlpha()
    if fadeEnabled and self.destination == 0 and math.max(f.data.timestamp + self.timestampOffset, self.currentFadeOffsetTime) + fadeTime - currentTime < 0 then
      if alpha ~= 0 and (f.FadeAnimation.alpha:GetToAlpha() ~= 0 or not f.FadeAnimation:IsPlaying()) and currentTime - self.lastFadeTime > 1 then
        self.lastFadeTime = currentTime
        duration = 3
        targetAlpha = 0
      end
    elseif f:GetBottom() - top > - lineHeight or f:GetTop() - bottom < lineHeight then
      if alpha ~= 0.5 then
        targetAlpha = 0.5
      end
    elseif alpha ~= 1 then
      targetAlpha = 1
      duration = 0.11 -- Same as scrolling
    end

    if targetAlpha then
      f.FadeAnimation.alpha:SetFromAlpha(alpha)
      f.FadeAnimation.alpha:SetToAlpha(targetAlpha)
      f.FadeAnimation.alpha:SetDuration(duration)
      f.FadeAnimation:Play()
    end
  end
end

function addonTable.Display.ScrollingMessagesMixin:ResetFading()
  self.currentFadeOffsetTime = GetTime()
end

function addonTable.Display.ScrollingMessagesMixin:SetFilter(filterFunc)
  self.filterFunc = filterFunc
end

function addonTable.Display.ScrollingMessagesMixin:FilterMessages()
  local result1, result2 = {}, {}
  local data = addonTable.Messages:GetMessage(1)
  local index = 1
  local limit = addonTable.Config.Get(addonTable.Config.Options.ROWS_LIMIT)
  while #result1 < limit and data do
    if (
      data.recordedBy == addonTable.Data.CharacterName and
      (not self.filterFunc or self.filterFunc(data))
    ) then
      table.insert(result1, data)
      table.insert(result2, addonTable.Messages:GetMessageHeight(index))
    end
    index = index + 1
    data = addonTable.Messages:GetMessage(index)
  end
  return result1, result2
end

function addonTable.Display.ScrollingMessagesMixin:Render(newMessages)
  self.firstRender = false
  self.scrollOffset = math.max(0, self.scrollOffset)

  if self.currentFadeOffsetTime == 0 then
    self.currentFadeOffsetTime = GetTime()
  end

  local viewportHeight = self:GetHeight()
  local messageSpacing = addonTable.Config.Get(addonTable.Config.Options.MESSAGE_SPACING)
  local allocatedHeight = 0
  local shownMessages = {}
  local index = 1
  local correctedOffset = false
  while allocatedHeight < viewportHeight + self.scrollOffset do
    local m = addonTable.Messages:GetMessage(index)
    if not m then
      break
    end
    if m.recordedBy == addonTable.Data.CharacterName and (not self.filterFunc or self.filterFunc(m)) then
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
        if #shownMessages == 1 then
          return
        else
          self.scrollOffset = self.scrollOffset + shownMessages[#shownMessages].extentBottom
        end
      end
      allocatedHeight = allocatedHeight + heights[self.key] + messageSpacing
    end
    index = index + 1
  end

  if #shownMessages > 0 and shownMessages[#shownMessages].extentTop < self.scrollOffset + viewportHeight and self.scrollOffset ~= 0 then
    self.scrollOffset = shownMessages[#shownMessages].extentTop - self:GetHeight()
  end

  local shift = 0
  if self.destination == 0 and self.scrollOffset ~= 0 and self.scrollOffset < viewportHeight and newMessages then
    shift = self.scrollOffset
  end

  local known = {}
  for _, info in ipairs(shownMessages) do
    info.fromBottom = info.extentBottom - self.scrollOffset
    info.show = info.extentTop - self.scrollOffset + shift >= 0 and info.fromBottom <= viewportHeight
    known[info.data.id] = info.show
  end
  local toReplace = {}
  local toReuse = {}
  for _, a in ipairs(self.allocated) do
    if a.data and known[a.data.id] then
      toReuse[a.data.id] = a
    else
      a:Hide()
      table.insert(toReplace, a)
      a.data = nil
    end
  end
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

  if self.destination == 0 and self.scrollOffset ~= 0 and newMessages then
    self:ScrollToEnd(shift > 0)
  end
end
