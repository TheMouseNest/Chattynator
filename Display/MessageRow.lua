---@class addonTableChattynator
local addonTable = select(2, ...)

---@class DisplayMessageRow: Frame
addonTable.Display.MessageRowMixin = {}
function addonTable.Display.MessageRowMixin:OnLoad()
  self:SetHyperlinkPropagateToParent(true)
  self.DisplayString = self:CreateFontString(nil, "ARTWORK", addonTable.Messages.font)
  self.DisplayString:SetJustifyH("LEFT")
  self.DisplayString:SetNonSpaceWrap(true)
  self.DisplayString:SetWordWrap(true)
  self.Timestamp = self:CreateFontString(nil, "ARTWORK", addonTable.Messages.font)
  self.Timestamp:SetPoint("TOPLEFT", 0, 0)
  self.Timestamp:SetJustifyH("LEFT")
  self.Timestamp:SetTextColor(0.5, 0.5, 0.5)
  self.Bar = self:CreateTexture(nil, "BACKGROUND")
  self.Bar:SetTexture("Interface/AddOns/Chattynator/Assets/Fade.png")
  self.Bar:SetPoint("RIGHT", self.DisplayString, "LEFT", -4, 0)
  self.Bar:SetPoint("TOP", 0, 0)
  self.Bar:SetWidth(2)

  self:SetFlattensRenderLayers(true)

  self.DisplayString:SetPoint("TOPLEFT", self.Timestamp, "TOPRIGHT")

  self:AttachDebug()
end

function addonTable.Display.MessageRowMixin:AttachDebug()
  if not self.debugAttached and not InCombatLockdown() then
    self.debugAttached = true
    self:SetScript("OnEnter", function()
      if addonTable.Config.Get(addonTable.Config.Options.DEBUG) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Type: " .. tostring(self.data.typeInfo.type))
        GameTooltip:AddLine("Event: " .. tostring(self.data.typeInfo.event))
        GameTooltip:AddLine("Player: " .. tostring(C_EncodingUtil and C_EncodingUtil.SerializeJSON(self.data.typeInfo.player) or self.data.typeInfo.player and self.data.typeInfo.player.name))
        GameTooltip:AddLine("Source: " .. tostring(self.data.typeInfo.source))
        GameTooltip:AddLine("Recorder: " .. tostring(self.data.recordedBy))
        GameTooltip:AddLine("Channel: " .. tostring(C_EncodingUtil and C_EncodingUtil.SerializeJSON(self.data.typeInfo.channel) or self.data.typeInfo.channel and self.data.typeInfo.channel.name))
        local color = self.data.color
        GameTooltip:AddLine("Color: " .. CreateColor(color.r, color.g, color.b):GenerateHexColorNoAlpha())
        GameTooltip:Show()
      end
    end)
    self:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    self:SetPropagateMouseClicks(true)
    self:SetPropagateMouseMotion(true)
  end
end

---@param width number
function addonTable.Display.MessageRowMixin:UpdateWidgets(width)
  self.Bar:SetPoint("BOTTOM", 0, 1 + addonTable.Messages.spacing)

  self.Timestamp:SetWidth(addonTable.Messages.inset)
  self.DisplayString:SetWidth(width)
  self.DisplayString:SetIndentedWordWrap(not addonTable.Config.Get(addonTable.Config.Options.SHOW_TIMESTAMP_SEPARATOR) and addonTable.Config.Get(addonTable.Config.Options.TIMESTAMP_FORMAT) == " ")

  for _, fontString in ipairs({self.DisplayString, self.Timestamp}) do
    fontString:SetFontObject(addonTable.Messages.font)
    fontString:SetTextScale(addonTable.Messages.scalingFactor)
  end

  self.Bar:SetShown(addonTable.Config.Get(addonTable.Config.Options.SHOW_TIMESTAMP_SEPARATOR))
end

function addonTable.Display.MessageRowMixin:SetData(data)
  self.data = data
  self.Timestamp:SetText(date(addonTable.Messages.timestampFormat, data.timestamp))
  self.DisplayString:SetSpacing(0)
  self.DisplayString:SetText(data.text)
  self.DisplayString:SetTextColor(data.color.r, data.color.g, data.color.b)
  self.animationTime = 0
  self.animationStart = 0
  self.animationFinalTime = 0
  self.animationDestination = 0
  self.animationFinalAlpha = nil
  self:SetAlpha(0)
end
