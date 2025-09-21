---@class addonTableChattynator
local addonTable = select(2, ...)

function addonTable.Core.ApplyOverrides()
  -- Disable context menu to move channel to new window (for now, will add functionality back)
  hooksecurefunc("ChatChannelDropdown_Show", function(_, chatType, chatTarget, chatName)
    local actualChatFrame
    for _, frame in ipairs(addonTable.allChatFrames) do
      if frame:IsMouseOver() then
        actualChatFrame = frame
      end
    end
    MenuUtil.CreateContextMenu(nil, function(_, rootDescription)
      local channelNumber = tonumber(chatTarget)
      local channelName = addonTable.Messages.channelMap[channelNumber]
      if not channelName or chatType ~= "CHANNEL" then
        rootDescription:CreateTitle(GRAY_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.CANT_POPOUT_THIS_CHANNEL))
        return
      end
      rootDescription:CreateButton(MOVE_TO_NEW_WINDOW, function()
        local config = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[actualChatFrame:GetID()]
        local tabConfig = addonTable.Config.GetEmptyTabConfig(channelName)
        tabConfig.channels[channelName] = true
        table.insert(config.tabs, tabConfig)
        config.tabs[actualChatFrame.tabIndex].channels[channelName] = false
        actualChatFrame.TabsBar:RefreshTabs()
        actualChatFrame.TabsBar.Tabs[#config.tabs]:Click()
      end)
    end)
  end)

  do
    local actualChatFrame
    hooksecurefunc(UnitPopupPopoutChatButtonMixin, "GetText", function()
      for _, frame in ipairs(addonTable.allChatFrames) do
        if frame:IsMouseOver() then
          actualChatFrame = frame
        end
      end
    end)
    function FCF_OpenTemporaryWindow(chatType, chatTarget, _, _)
      if not debugstack():find("UnitPopupShared") or chatType ~= "WHISPER" and chatType ~= "BN_WHISPER" then
        return
      end
      if not actualChatFrame then
        return
      end
      local config = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[actualChatFrame:GetID()]
      local tabConfig = addonTable.Config.GetEmptyTabConfig(Ambiguate(chatTarget, "all"))
      tabConfig.whispersTemp[chatTarget] = true
      tabConfig.isTemporary = true
      local c = ChatTypeInfo[chatType]
      tabConfig.tabColor = CreateColor(c.r, c.g, c.b):GenerateHexColorNoAlpha()
      table.insert(config.tabs, tabConfig)
      config.tabs[actualChatFrame.tabIndex].whispersTemp[chatTarget] = false
      actualChatFrame.TabsBar:RefreshTabs()
      actualChatFrame.TabsBar.Tabs[#config.tabs]:Click()
      actualChatFrame = nil
    end
  end

  ChatFrame_ChatPageUp = function()
    addonTable.allChatFrames[1].ScrollingMessages:ScrollBy(200)
  end

  ChatFrame_ChatPageDown = function()
    addonTable.allChatFrames[1].ScrollingMessages:ScrollBy(-200)
  end

  ChatFrame_ScrollToBottom = function()
    addonTable.allChatFrames[1].ScrollingMessages:ScrollToEnd()
  end

  FloatingChatFrameManager:UnregisterAllEvents()

  -- Prevent custom tabs generated from Blizzard tabs getting hidden on login
  -- ie combat log is immediately hidden because the Blizz code thinks it is definitely not visible
  -- (we handle that ourselves)
  local oldSetScript = GeneralDockManager.SetScript
  GeneralDockManager:SetScript("OnSizeChanged", nil)
  hooksecurefunc(GeneralDockManager, "SetScript", function()
    oldSetScript(GeneralDockManager, "OnSizeChanged", nil)
    oldSetScript(GeneralDockManager, "OnUpdate", nil)
  end)


  -- We delay unregistering so that the chat frame colours get applied properly,
  -- and then ensure that chat colour events get processed, both to avoid errors
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
      frame:RegisterEvent("UPDATE_CHAT_WINDOWS")
      frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
      C_Timer.After(0, function()
        for _, tabName in pairs(CHAT_FRAMES) do
          local tab = _G[tabName]
          if tab:GetParent() == UIParent then
            tab:SetParent(addonTable.hiddenFrame)
          end
          if tabName ~= "ChatFrame2" then
            tab:UnregisterAllEvents()
            tab:RegisterEvent("UPDATE_CHAT_COLOR") -- Needed to prevent errors in OnUpdate from UIParent
            -- Workaround for addons trying to prevent messages showing in chat frame by unregistering and reregistering events
            hooksecurefunc(tab, "RegisterEvent", function(_, name)
              if name ~= "UPDATE_CHAT_COLOR" then
                tab:UnregisterEvent(name)
              end
            end)
          end
          tab:HookScript("OnEvent", function(_, e)
            if e == "UPDATE_CHAT_WINDOWS" then
              tab:UnregisterEvent("UPDATE_CHAT_WINDOWS")
              tab:UnregisterEvent("UPDATE_FLOATING_CHAT_WINDOWS")
            end
          end)
          local tabButton = _G[tabName .. "Tab"]
          tabButton:SetParent(addonTable.hiddenFrame)
          local SetParent = tabButton.SetParent
          hooksecurefunc(tabButton, "SetParent", function(self) SetParent(self, addonTable.hiddenFrame) end)
        end
        _G["ChatFrame1Tab"].IsVisible = function() return true end -- Workaround for TSM assuming chat tabs are always visible
      end)
    elseif event == "UPDATE_CHAT_WINDOWS" then
      frame:UnregisterEvent("UPDATE_CHAT_WINDOWS")
      GeneralDockManagerOverflowButton:SetParent(addonTable.hiddenFrame)
    end
  end)

  hooksecurefunc("ChatEdit_DeactivateChat", function(editBox)
    editBox:Hide()
  end)
  hooksecurefunc("ChatEdit_ActivateChat", function(editBox)
    editBox:Show()
  end)

  hooksecurefunc("ChatEdit_UpdateHeader", function(editBox)
    if editBox ~= ChatFrame1EditBox then
      return
    end
    local allColors = addonTable.Config.Get(addonTable.Config.Options.CHAT_COLORS)
    local chatType = editBox:GetAttribute("chatType")
    local color
    if chatType == "CHANNEL" then
      local channel = editBox:GetAttribute("channelTarget") and GetChannelName(editBox:GetAttribute("channelTarget")) or 0
      color = allColors[chatType .. channel] or allColors[chatType]
    else
      color = allColors[chatType]
    end
    if color then
      editBox:SetTextColor(color.r, color.g, color.b)
      for _, r in pairs({ChatFrame1EditBox:GetRegions()}) do
        if r:IsObjectType("FontString") and r:GetParentKey() == nil then
          r:SetTextColor(color.r, color.g, color.b)
        end
      end
      editBox.header:SetTextColor(color.r, color.g, color.b)
      editBox.headerSuffix:SetTextColor(color.r, color.g, color.b)
      if editBox.focusLeft then
        editBox.focusLeft:SetVertexColor(color.r, color.g, color.b)
        editBox.focusRight:SetVertexColor(color.r, color.g, color.b)
        editBox.focusMid:SetVertexColor(color.r, color.g, color.b)
      end
    end
  end)
end
