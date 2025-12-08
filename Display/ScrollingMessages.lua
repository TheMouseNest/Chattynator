---@class addonTableChattynator
local addonTable = select(2, ...)

local rightInset = 3

---@class DisplayScrollingMessages: Frame
addonTable.Display.ScrollingMessagesMixin = {}

function addonTable.Display.ScrollingMessagesMixin:MyOnLoad()
  self:SetHyperlinkPropagateToParent(true)
  self:SetHyperlinksEnabled(true)

  self:SetFontObject(addonTable.Messages.font)
  self:SetTextColor(1, 1, 1)
  self:SetJustifyH("LEFT")
  self:SetIndentedWordWrap(true)

  self:SetFading(addonTable.Config.Get(addonTable.Config.Options.ENABLE_MESSAGE_FADE))
  self:SetTimeVisible(addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FADE_TIME))

  self:SetScript("OnMouseWheel", function(_, delta)
    if delta > 0 then
      self:ScrollUp()
    else
      self:ScrollDown()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("MessageDisplayChanged", function()
    self:SetFontObject(addonTable.Messages.font)
    self:SetTextColor(1, 1, 1)
    self:SetScale(addonTable.Core.GetFontScalingFactor())
  end)

  addonTable.CallbackRegistry:RegisterCallback("RefreshStateChange", function(_, refreshState)
    if refreshState[addonTable.Constants.RefreshReason.MessageWidget] then
      self:Render()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.ENABLE_MESSAGE_FADE then
      self:SetFading(addonTable.Config.Get(addonTable.Config.Options.ENABLE_MESSAGE_FADE))
    elseif settingName == addonTable.Config.Options.MESSAGE_FADE_TIME then
      self:SetTimeVisible(addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FADE_TIME))
    end
  end)
end

function addonTable.Display.ScrollingMessagesMixin:SetFilter(filterFunc)
  self.filterFunc = filterFunc
end

local function GetPrefix(timestamp)
  if addonTable.Config.Get(addonTable.Config.Options.SHOW_TIMESTAMP_SEPARATOR) then
    return "|cff989898" .. date(addonTable.Messages.timestampFormat, timestamp) .. " || |r"
  else
    return "|cff989898" .. date(addonTable.Messages.timestampFormat, timestamp) .. "|r"
  end
end

function addonTable.Display.ScrollingMessagesMixin:Render(newMessages)
  if newMessages == nil then
    self:Clear()
    newMessages = 200
  end
  local index = 1
  local messages = {}
  while index <= newMessages do
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
    for i = #messages, 1, -1 do
      local m = messages[i]
      self:AddMessage(GetPrefix(m.timestamp) .. m.text, m.color.r, m.color.g, m.color.b)
    end
  end
end
