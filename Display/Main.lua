---@class addonTableChattynator
local addonTable = select(2, ...)

---@class ChatFrameMixin: Frame
addonTable.Display.ChatFrameMixin = {}

function addonTable.Display.ChatFrameMixin:OnLoad()
  self:SetHyperlinkPropagateToParent(true)
  self:SetMovable(true)
  self:SetResizable(true)
  self:SetResizeBounds(240, 140)
  self:SetClampedToScreen(true)

  self:SetScript("OnSizeChanged", function()
    self.ButtonsBar:Update()
    self:SavePosition()
    self:SaveSize()
  end)

  self.ScrollingMessages = CreateFrame("Frame", nil, self)
  Mixin(self.ScrollingMessages, addonTable.Display.ScrollingMessagesMixin)
  self.ScrollingMessages:OnLoad()

  self.ScrollingMessages:SetPoint("TOPLEFT", 34, -27)
  self.ScrollingMessages:SetPoint("BOTTOMRIGHT", 0, 38)

  self.resizeWidget = CreateFrame("Button", nil, self)
  self.resizeWidget:SetSize(20, 22)
  self.resizeWidget:SetPoint("BOTTOMRIGHT", self.ScrollingMessages, -5,  0)
  self.resizeWidget:RegisterForDrag("LeftButton")
  self.resizeWidget:SetScript("OnDragStart", function()
    self:StartSizing("BOTTOMRIGHT")
  end)
  self.resizeWidget:SetScript("OnDragStop", function()
    self:StopMovingOrSizing()
    self:SaveSize()
  end)
  addonTable.Skins.AddFrame("ResizeWidget", self.resizeWidget)
  self.resizeWidget:SetShown(not addonTable.Config.Get(addonTable.Config.Options.LOCKED))

  self.TabsBar = CreateFrame("Frame", nil, self)
  Mixin(self.TabsBar, addonTable.Display.TabsBarMixin)
  self.TabsBar:OnLoad()
  self.TabsBar:SetPoint("TOPLEFT", 32, 0)
  self.TabsBar:SetPoint("TOPRIGHT")
  self.TabsBar:SetHeight(22)

  self.ButtonsBar = CreateFrame("Frame", nil, self)
  Mixin(self.ButtonsBar, addonTable.Display.ButtonsBarMixin)
  self.ButtonsBar:OnLoad()

  addonTable.CallbackRegistry:RegisterCallback("Render", function(_, newMessages)
    if self:GetID() == 0 then
      return
    end
    self.TabsBar:ApplyFlashing(newMessages)
    self.ScrollingMessages:Render(newMessages)
  end, self)

  addonTable.CallbackRegistry:RegisterCallback("RefreshStateChange", function(_, refreshState)
    if self:GetID() ~= 0 and refreshState[addonTable.Constants.RefreshReason.Tabs] then
      self.TabsBar:RefreshTabs()
      self.ScrollingMessages:Render()
    end
    if refreshState[addonTable.Constants.RefreshReason.MessageWidget] then
      if self:GetID() ~= 0 then
        self.ScrollingMessages:Render()
      end
    end
    if refreshState[addonTable.Constants.RefreshReason.Locked] then
      self.resizeWidget:SetShown(not addonTable.Config.Get(addonTable.Config.Options.LOCKED))
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if self:GetID() == 0 then
      return
    end
    if settingName == addonTable.Config.Options.WINDOWS then
      local ownWindowData = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()]
      if not ownWindowData then
        addonTable.Core.ReleaseClosedChatFrame(self:GetID())
      else
        self:ClearAllPoints()
        self:SetPoint(unpack(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].position))
        self:SetSize(unpack(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].size))
        self.ButtonsBar:Update()
      end
    elseif settingName == addonTable.Config.Options.BUTTON_POSITION then
      self.ButtonsBar:Update()
      self:ApplyButtonPositionAnchors()
    elseif settingName == addonTable.Config.Options.EDIT_BOX_POSITION and self:GetID() == 1 then
      self:PositionEditBox()
    end
  end)

  addonTable.Skins.AddFrame("ChatFrame", self)
end

function addonTable.Display.ChatFrameMixin:Reset()
  local function SetPosition()
    self:SetPoint(unpack(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].position))
  end
  local state = pcall(SetPosition)
  if not state then
    self:SetPoint("CENTER", UIParent)
  end
  self:SetSize(unpack(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].size))

  self.filterFunc = nil

  self.tabIndex = 1

  self.TabsBar:Reset()

  self:RepositionBlizzardWidgets()
  if self:GetID() == 1 then
    self.ButtonsBar:AddBlizzardButtons()
  end
  self.ButtonsBar:AddButtons()
  self.ButtonsBar:Update()
  self:AdjustMessageAnchors()
  self:ApplyButtonPositionAnchors()
  self.ScrollingMessages:Reset()

  self.TabsBar:RefreshTabs()
end

function addonTable.Display.ChatFrameMixin:SavePosition()
  local point1, anchorFrame, point2, x, y = self:GetPoint(1)
  local anchorFrameName = anchorFrame and anchorFrame:GetName() or "UIParent"
  addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].position = {point1, anchorFrameName, point2, x, y}
end

function addonTable.Display.ChatFrameMixin:SaveSize()
  local x, y = self:GetSize()
  addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetID()].size = {x, y}
end

function addonTable.Display.ChatFrameMixin:RepositionBlizzardWidgets()
  if self:GetID() == 1 and not addonTable.Data.BlizzardEditBoxAssigned then
    addonTable.Data.BlizzardEditBoxAssigned = true

    -- We use the default edit box rather than instantiating our own so that the keyboard shortcuts to open it work
    ChatFrame1EditBox:SetParent(self)
    self:PositionEditBox()
    addonTable.Skins.AddFrame("ChatEditBox", ChatFrame1EditBox)
  end
end

function addonTable.Display.ChatFrameMixin:AdjustMessageAnchors()
  if self:GetID() == 1 then
    return
  end
  self.ScrollingMessages:SetPoint("BOTTOMRIGHT", 0, 5)
end

function addonTable.Display.ChatFrameMixin:ApplyButtonPositionAnchors()
  local position = addonTable.Config.Get(addonTable.Config.Options.BUTTON_POSITION)
  if position == "left_always" then
    self.ScrollingMessages:SetPoint("TOPLEFT", 34, -27)
    self.TabsBar:SetPoint("TOPLEFT", 32, 0)
  else
    self.ScrollingMessages:SetPoint("TOPLEFT", 2, -27)
    self.TabsBar:SetPoint("TOPLEFT", 4, 0)
  end
end

function addonTable.Display.ChatFrameMixin:PositionEditBox()
  if self:GetID() ~= 1 then
    return
  end

  local position = addonTable.Config.Get(addonTable.Config.Options.EDIT_BOX_POSITION)
  ChatFrame1EditBox:ClearAllPoints()
  if position == "bottom" then
    self.ScrollingMessages:SetPoint("BOTTOMRIGHT", 0, 38)
    ChatFrame1EditBox:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 32)
    ChatFrame1EditBox:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 32)
  elseif position == "top" then
    self.ScrollingMessages:SetPoint("BOTTOMRIGHT", 0, 5)
    ChatFrame1EditBox:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    ChatFrame1EditBox:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
  end
end

function addonTable.Display.ChatFrameMixin:SetFilter(func)
  if addonTable.API.RejectionFilters[self:GetID()] and addonTable.API.RejectionFilters[self:GetID()][self.tabIndex] then
    local filters = addonTable.API.RejectionFilters[self:GetID()] and addonTable.API.RejectionFilters[self:GetID()][self.tabIndex]
    local oldFunc = func
    func = function(data)
      if not oldFunc(data) then
        return false
      end
      local copy = CopyTable(data)
      for _, f in ipairs(filters) do
        if not f(copy) then
          return false
        end
      end
      return true
    end
  end
  self.ScrollingMessages:SetFilter(func)
end

function addonTable.Display.ChatFrameMixin:SetBackgroundColor(r, g, b)
  self.backgroundColor = {r = r, g = g, b = b}
end

function addonTable.Display.ChatFrameMixin:SetTabSelectedAndFilter(index, func)
  self.tabIndex = index

  self:SetFilter(func)

  self.ScrollingMessages:Reset()
end
