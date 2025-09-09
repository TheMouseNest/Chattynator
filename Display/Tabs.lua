---@class addonTableChattynator
local addonTable = select(2, ...)

local function DisableCombatLog(chatFrame)
  ChatFrame2:SetParent(addonTable.hiddenFrame)
  chatFrame.ScrollingMessages:Show()
end

local function RenameTab(windowIndex, tabIndex, newName)
  local windowData = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[windowIndex]
  if not windowData then
    return
  end
  local tabData = windowData.tabs[tabIndex]
  if not tabData then
    return
  end

  tabData.name = newName
  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
end

addonTable.Display.TabsBarMixin = {}

function addonTable.Display.TabsBarMixin:OnLoad()
  self.chatFrame = self:GetParent()
  self:SetupPool()
  self.customHolders = {}

  self:SetScript("OnEvent", self.OnEvent)

  addonTable.CallbackRegistry:RegisterCallback("SkinLoaded", function()
    self:PositionTabs()
  end)

  self.active = false

  self.fadeInterpolator = CreateInterpolator(InterpolatorUtil.InterpolateEaseIn)
end

function addonTable.Display.TabsBarMixin:Reset()
  self.Tabs = {}
end

function addonTable.Display.TabsBarMixin:PositionTabs()
  local xOffset = 0
  for _, tab in ipairs(self.Tabs or {}) do
    tab:SetPoint("BOTTOMLEFT", self, "TOPLEFT", xOffset, -22)
    xOffset = xOffset + tab:GetWidth() + addonTable.Constants.TabSpacing
  end
end

function addonTable.Display.TabsBarMixin:StartDragging(index)
  local origin = GetCursorPosition() / UIParent:GetEffectiveScale()
  local prevLeft = self.Tabs[index]:GetLeft()
  self.dragIndex = index
  self:RegisterEvent("GLOBAL_MOUSE_UP")
  local rightLimit = self.Tabs[#self.Tabs]:GetRight()
  local leftLimit = self.Tabs[1]:GetLeft()

  self:SetScript("OnUpdate", function()
    local dragButton = self.Tabs[index]
    dragButton:SetFrameStrata("HIGH") -- Ensure dragged tab renders above all other tabs, avoids weird overlap artifacts

    local newOrigin = GetCursorPosition() / UIParent:GetEffectiveScale()
    local goingLeft = newOrigin < origin
    local goingRight = newOrigin > origin
    dragButton:AdjustPointsOffset(newOrigin - origin, 0)
    if dragButton:GetLeft() < leftLimit then
      dragButton:AdjustPointsOffset(leftLimit - dragButton:GetLeft(), 0)
    elseif dragButton:GetRight() > rightLimit then
      dragButton:AdjustPointsOffset(rightLimit - dragButton:GetRight(), 0)
    else
      origin = newOrigin
    end

    prevLeft = dragButton:GetLeft()

    local allTabsData = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self.chatFrame:GetID()].tabs
    -- Check if the tab overlaps the tab to the left, and is at least 40% overlapping, and has been recently dragged left
    if index > 1 and dragButton:GetLeft() < self.Tabs[index - 1]:GetLeft() + self.Tabs[index - 1]:GetWidth() - dragButton:GetWidth() * 0.4 and goingLeft then
      dragButton:SetFrameStrata("MEDIUM") -- Revert strata change
      local old = allTabsData[index]
      allTabsData[index] = allTabsData[index - 1]
      allTabsData[index - 1] = old
      if self.chatFrame.tabIndex == index then
        self.chatFrame.tabIndex = index - 1
      elseif self.chatFrame.tabIndex == index - 1 then
        self.chatFrame.tabIndex = index
      end
      index = index - 1
      addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
    -- Check if the tab overlaps the tab to the right, and is at least 40% overlapping, and has been recently dragged right
    elseif index < #self.Tabs and self.Tabs[index + 1].isDraggable and self.Tabs[index + 1]:GetLeft() + dragButton:GetWidth() * 0.4 < dragButton:GetLeft() + dragButton:GetWidth() and goingRight then
      dragButton:SetFrameStrata("MEDIUM") -- Revert strata change
      local old = allTabsData[index]
      allTabsData[index] = allTabsData[index + 1]
      allTabsData[index + 1] = old
      if self.chatFrame.tabIndex == index then
        self.chatFrame.tabIndex = index + 1
      elseif self.chatFrame.tabIndex == index + 1 then
        self.chatFrame.tabIndex = index
      end
      index = index + 1
      addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
    end

    self.dragIndex = index

    local dragButton = self.Tabs[index]
    if math.abs(dragButton:GetLeft() - prevLeft) > 0.05 then
      dragButton:AdjustPointsOffset(prevLeft - dragButton:GetLeft(), 0)
    end

    dragButton:SetFrameStrata("HIGH")
  end)
end

function addonTable.Display.TabsBarMixin:EndDragging(index)
  self.Tabs[self.dragIndex]:SetFrameStrata("MEDIUM")
  self:UnregisterEvent("GLOBAL_MOUSE_UP")
  self:SetScript("OnUpdate", nil)
  self:PositionTabs()
end

function addonTable.Display.TabsBarMixin:OnEvent()
  self:EndDragging()
end

function addonTable.Display.TabsBarMixin:SetupPool()
  self.tabsPool = CreateFramePool("Button", self, nil, nil, false,
    function(tabButton)
      tabButton:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
      tabButton:RegisterForDrag("LeftButton", "RightButton")
      tabButton:SetScript("OnDragStart", function(_, button)
        if addonTable.Config.Get(addonTable.Config.Options.LOCKED) then
          return
        end
        if tabButton:GetID() == 1 and button == "LeftButton" then
          self.chatFrame:StartMoving()
        elseif tabButton.isDraggable then
          self:StartDragging(tabButton:GetID())
        end
      end)
      tabButton:SetScript("OnDragStop", function()
        self.chatFrame:StopMovingOrSizing()
        self.chatFrame:SavePosition()
      end)
      function tabButton:SetSelected(state)
        self:SetFlashing(false)
        self.selected = state
      end
      function tabButton:SetColor(r, g, b)
        self.color = {r = r, g = g, b = b}
      end
      function tabButton:SetFlashing(state)
        self.flashing = state
      end
      addonTable.Skins.AddFrame("ChatTab", tabButton)
    end
  )
end

function addonTable.Display.TabsBarMixin:ApplyFlashing(newMessages)
  if not newMessages then
    return
  end
  local state = addonTable.Config.Get(addonTable.Config.Options.TAB_FLASH_ON)
  local messages = {}
  if state == "whispers" then
    while newMessages > 0 do
      newMessages = newMessages - 1
      local data = addonTable.Messages:GetMessageRaw(1 + #messages)
      if (data.typeInfo.type == "WHISPER" or data.typeInfo.type == "BN_WHISPER") and (not data.typeInfo.event or not data.typeInfo.event:match("_INFORM$")) then
        table.insert(messages, data)
      end
    end
    if #messages == 0 then
      return
    end
  elseif state == "all" then
    while newMessages > 0 do
      newMessages = newMessages - 1
      local data = addonTable.Messages:GetMessageRaw(1 + #messages)
      if not data.typeInfo.event or not data.typeInfo.event:match("_INFORM$") then
        table.insert(messages, data)
      end
    end
  else
    return
  end
  local tabsMatching = {}
  for index, tab in ipairs(self.Tabs) do
    if tab.filter and FindInTableIf(messages, tab.filter) ~= nil then
      tabsMatching[index] = true
    end
  end

  if state ~= "whispers" and tabsMatching[self.chatFrame.tabIndex] then
    return
  end

  for index in pairs(tabsMatching) do
    self.Tabs[index]:SetFlashing(true)
  end
end

function addonTable.Display.TabsBarMixin:GetFilter(tabData, tabTag)
  local func
  if tabData.invert then
    func = function(data)
      return tabData.groups[data.typeInfo.type] ~= false and (data.typeInfo.tabTag == nil or data.typeInfo.tabTag == tabTag) and
        (
        not data.typeInfo.channel or
        (tabData.channels[data.typeInfo.channel.name] == nil and data.typeInfo.channel.isDefault) or
        tabData.channels[data.typeInfo.channel.name]
      ) and ((data.typeInfo.type ~= "WHISPER" and data.typeInfo.type ~= "BN_WHISPER") or tabData.whispersTemp[data.typeInfo.player and data.typeInfo.player.name] ~= false)
      or (data.typeInfo.type == "ADDON" and tabData.groups["ADDON"] == false and tabData.addons[data.typeInfo.source] ~= false and (data.typeInfo.tabTag == nil or data.typeInfo.tabTag == tabTag))
    end
  else
    func = function(data)
      return tabData.groups[data.typeInfo.type] and (data.typeInfo.tabTag == nil or data.typeInfo.tabTag == tabTag) or
        (data.typeInfo.type == "WHISPER" or data.typeInfo.type == "BN_WHISPER") and tabData.whispersTemp[data.typeInfo.player and data.typeInfo.player.name] or
        tabData.channels[data.typeInfo.channel and data.typeInfo.channel.name] or
        data.typeInfo.type == "ADDON" and not tabData.groups["ADDON"] and tabData.addons[data.typeInfo.source] and (data.typeInfo.tabTag == nil or data.typeInfo.tabTag == tabTag)
    end
  end
  if #tabData.filters > 0 then
    local core = func
    func = function(data)
      if not core(data) then
        return false
      end

      for _, f in ipairs(tabData.filters) do
        if not f(data) then
          return false
        end
      end
      return true
    end
  end

  return func
end

function addonTable.Display.GetTabNameFromName(name)
  if type(_G[name]) == "string" then
    return _G[name]
  else
    return name or UNKNOWN
  end
end

function addonTable.Display.TabsBarMixin:RefreshTabs()
  local forceSelected = false
  if not self.chatFrame.tabsPool then
    forceSelected = true
  end
  self.tabsPool:ReleaseAll()
  local allTabs = {}
  for index, tabData in ipairs(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self.chatFrame:GetID()].tabs) do
    local tabButton = self.tabsPool:Acquire()
    tabButton.minWidth = false
    tabButton:SetID(index)
    tabButton:Show()
    tabButton:SetText(addonTable.Display.GetTabNameFromName(tabData.name))
    local tabColor = CreateColorFromRGBHexString(tabData.tabColor)
    local bgColor = CreateColorFromRGBHexString(tabData.backgroundColor)
    local tabTag = self.chatFrame:GetID() .. "_" .. index
    tabButton.filter = self:GetFilter(tabData, tabTag)
    tabButton.bgColor = bgColor
    tabButton.isDraggable = true
    tabButton:SetScript("OnClick", function(_, mouseButton)
      if mouseButton == "LeftButton" then
        for _, frame in pairs(self.customHolders) do
          frame:Hide()
        end
        for _, otherTab in ipairs(self.Tabs) do
          otherTab:SetSelected(false)
        end
        tabButton:SetSelected(true)

        self.chatFrame:SetBackgroundColor(tabButton.bgColor.r, tabButton.bgColor.g, tabButton.bgColor.b)

        if tabData.custom and addonTable.API.CustomTabs[tabData.custom] then
          self.chatFrame.ScrollingMessages:Hide()
          self.chatFrame:SetTabSelectedOnly(tabButton:GetID())
          if not self.customHolders[tabData.custom] then
            self.customHolders[tabData.custom] = CreateFrame("Frame", nil, self.chatFrame)
            self.customHolders[tabData.custom]:SetAllPoints(self.chatFrame.ScrollingMessages)
          end
          self.customHolders[tabData.custom]:Show()
          addonTable.API.CustomTabs[tabData.custom].install(self.customHolders[tabData.custom])
        else
          self.chatFrame.ScrollingMessages:Show()
          if self.chatFrame.tabIndex == tabButton:GetID() then
            self.chatFrame:SetFilter(tabButton.filter)
          else
            self.chatFrame:SetTabSelectedAndFilter(tabButton:GetID(), tabButton.filter)
          end
          self.chatFrame.ScrollingMessages:Render()
        end
      elseif mouseButton == "RightButton" then
        MenuUtil.CreateContextMenu(tabButton, function(_, rootDescription)
          if tabData.custom == "combat_log" then
            rootDescription:CreateButton(addonTable.Locales.BLIZZARD_SETTINGS, function()
              ShowUIPanel(ChatConfigFrame)
            end)
          else
            rootDescription:CreateButton(addonTable.Locales.TAB_SETTINGS, function()
              addonTable.CustomiseDialog.ToggleTabFilters(self.chatFrame:GetID(), tabButton:GetID())
            end)
          end
          rootDescription:CreateButton(addonTable.Locales.GLOBAL_SETTINGS, function()
            addonTable.CustomiseDialog.Toggle()
          end)
          rootDescription:CreateDivider()
          if tabData.isTemporary or not addonTable.Config.Get(addonTable.Config.Options.LOCKED) then
            rootDescription:CreateButton(addonTable.Locales.LOCK_CHAT, function()
              addonTable.Config.Set(addonTable.Config.Options.LOCKED, true)
            end)
            rootDescription:CreateButton(addonTable.Locales.RENAME_TAB, function()
              addonTable.Dialogs.ShowEditBox(addonTable.Locales.RENAME_X_MESSAGE:format(addonTable.Display.GetTabNameFromName(tabData.name)), ACCEPT, CANCEL, function(name)
                RenameTab(self.chatFrame:GetID(), tabButton:GetID(), name)
              end)
            end)
            do
              local oldColor = tabData.tabColor
              local colorInfo = {
                r = tabColor.r, g = tabColor.g, b = tabColor.b,
                swatchFunc = function()
                  tabColor.r, tabColor.g, tabColor.b =  ColorPickerFrame:GetColorRGB()
                  tabData.tabColor = tabColor:GenerateHexColorNoAlpha()
                  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
                end,
                cancelFunc = function()
                  tabData.tabColor = oldColor
                  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
                end,
              }
              rootDescription:CreateColorSwatch(addonTable.Locales.TAB_COLOR,
                function()
                  ColorPickerFrame:SetupColorPickerAndShow(colorInfo)
                end,
                colorInfo
              )
            end
            do
              local oldColor = tabData.backgroundColor
              local colorInfo = {
                r = bgColor.r, g = bgColor.g, b = bgColor.b,
                swatchFunc = function()
                  bgColor.r, bgColor.g, bgColor.b =  ColorPickerFrame:GetColorRGB()
                  tabData.backgroundColor = bgColor:GenerateHexColorNoAlpha()
                  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
                end,
                cancelFunc = function()
                  tabData.backgroundColor = oldColor
                  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
                end,
              }
              rootDescription:CreateColorSwatch(addonTable.Locales.BACKGROUND_COLOR,
                function()
                  ColorPickerFrame:SetupColorPickerAndShow(colorInfo)
                end,
                colorInfo
              )
            end
            if tabButton:GetID() ~= 1 then
              rootDescription:CreateButton(addonTable.Locales.MOVE_TO_NEW_WINDOW, function()
                local newChatFrame = addonTable.Core.MakeChatFrame()

                local windows = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)
                windows[newChatFrame:GetID()].tabs[1] = windows[self.chatFrame:GetID()].tabs[tabButton:GetID()]
                table.remove(windows[self.chatFrame:GetID()].tabs, tabButton:GetID())
                newChatFrame:Reset()
                newChatFrame.ScrollingMessages:Render()
                addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
              end)
            end
            if tabButton:GetID() == 1 and self.chatFrame:GetID() ~= 1 then
              rootDescription:CreateButton(addonTable.Locales.CLOSE_WINDOW, function()
                addonTable.Core.DeleteChatFrame(self.chatFrame:GetID())
              end)
            elseif tabButton:GetID() ~= 1 then
              rootDescription:CreateButton(addonTable.Locales.CLOSE_TAB, function()
                local allTabData = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self.chatFrame:GetID()].tabs
                table.remove(allTabData, tabButton:GetID())
                addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
              end)
            end
          else
            rootDescription:CreateButton(addonTable.Locales.UNLOCK_CHAT, function()
              addonTable.Config.Set(addonTable.Config.Options.LOCKED, false)
            end)
          end
        end)
      elseif mouseButton == "MiddleButton" and tabButton:GetID() ~= 1 then
        if tabData.isTemporary or not addonTable.Config.Get(addonTable.Config.Options.LOCKED) then
          local allTabData = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self.chatFrame:GetID()].tabs
          table.remove(allTabData, tabButton:GetID())
          addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
        end
      end
    end)

    tabButton:SetColor(tabColor.r, tabColor.g, tabColor.b)
    table.insert(allTabs, tabButton)
  end

  if not addonTable.Config.Get(addonTable.Config.Options.LOCKED) then
    local newTab = self.tabsPool:Acquire()
    newTab.minWidth = true
    newTab.isDraggable = false
    newTab:SetText(addonTable.Constants.NewTabMarkup)
    newTab:SetScript("OnClick", function()
      table.insert(addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self.chatFrame:GetID()].tabs, addonTable.Config.GetEmptyTabConfig(addonTable.Locales.NEW_TAB))
      addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
    end)
    newTab:Show()
    newTab:SetColor(0.3, 0.3, 0.3)
    table.insert(allTabs, newTab)
  end

  for _, tab in ipairs(allTabs) do
    tab:SetSelected(false)
  end
  self.Tabs = allTabs
  self:PositionTabs()
  local currentTab = self.chatFrame.tabIndex and math.min(self.chatFrame.tabIndex, #addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self.chatFrame:GetID()].tabs) or 1
  allTabs[currentTab]:Click()

  local show = addonTable.Config.Get(addonTable.Config.Options.SHOW_TABS)
  self:SetShown(show ~= "never")
  if show == "hover" then
    self.lockActive = false
    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", self.OnLeave)
    for _, b in ipairs(self.Tabs) do
      if not b.hooked then
        b.hooked = true
        b:HookScript("OnEnter", function()
          if not self.lockActive then
            self:OnEnter()
          end
        end)
        b:HookScript("OnLeave", function()
          if not self.lockActive then
            self:OnLeave()
          end
        end)

        self.active = false
        self:SetAlpha(0)
      end
    end
    if self.active then
      self:OnLeave() -- Hide if necessary
    end
  else
    self.active = true
    self.lockActive = true -- Prevent hooked stuff hiding the buttons
    self:SetScript("OnEnter", nil)
    self:SetScript("OnLeave", nil)
    if self.hideTimer then
      self.hideTimer:Cancel()
      self.hideTimer = nil
    end
    self:SetAlpha(1)
  end
end

function addonTable.Display.TabsBarMixin:OnEnter()
  if self.hideTimer then
    self.hideTimer:Cancel()
  end
  self.active = true
  self.fadeInterpolator:Interpolate(self:GetAlpha(), 1, 0.15, function(value)
    self:SetAlpha(value)
  end)
end

function addonTable.Display.TabsBarMixin:OnLeave()
  if self:IsMouseOver() then
    return
  end
  if self.hideTimer then
    self.hideTimer:Cancel()
  end
  self.hideTimer = C_Timer.NewTimer(2, function()
    self.fadeInterpolator:Interpolate(self:GetAlpha(), 0, 0.15, function(value)
      self:SetAlpha(value)
    end)
    self.active = false
  end)
end

addonTable.CallbackRegistry:RegisterCallback("Render", function(_, newMessages)
  local targetWindow = addonTable.Config.Get(addonTable.Config.Options.NEW_WHISPER_NEW_TAB)
  if targetWindow ~= 0 and newMessages then
    for i = 1, newMessages do
      local m = addonTable.Messages:GetMessageRaw(i)
      if m.typeInfo.type == "WHISPER" or m.typeInfo.type == "BN_WHISPER" then
        local window = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[targetWindow]
        local any = false
        for _, tab in ipairs(window.tabs) do
          if tab.whispersTemp[m.typeInfo.player.name] then
            any = true
            break
          end
        end
        if not any then
          local tabConfig = addonTable.Config.GetEmptyTabConfig(Ambiguate(m.typeInfo.player.name, "all"))
          local c = ChatTypeInfo[m.typeInfo.type]
          tabConfig.tabColor = CreateColor(c.r, c.g, c.b):GenerateHexColorNoAlpha()
          tabConfig.whispersTemp[m.typeInfo.player.name] = true
          tabConfig.isTemporary = true
          table.insert(window.tabs, tabConfig)
          addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
          addonTable.allChatFrames[targetWindow].TabsBar.Tabs[#window.tabs]:SetFlashing(true)
        end
      end
    end
  end
end)
