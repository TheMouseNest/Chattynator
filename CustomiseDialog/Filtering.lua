---@class addonTableChattynator
local addonTable = select(2, ...)

local LAYOUT = {
  MESSAGES = {
    {"SAY"},
    {"EMOTE"},
    {"YELL"},
    {"GUILD", GUILD_CHAT},
    {"OFFICER", OFFICER_CHAT},
    {"GUILD_ACHIEVEMENT"},
    {"ACHIEVEMENT"},
    {"WHISPER"},
    {"BN_WHISPER"},
    {"PARTY"},
    {"PARTY_LEADER"},
    {"RAID"},
    {"RAID_LEADER"},
    {"RAID_WARNING"},
    {"INSTANCE_CHAT"},
    {"INSTANCE_CHAT_LEADER"},
  },

  CHANNELS = {},

  OTHER_CREATURE = {
    {"MONSTER_SAY", SAY},
    {"MONSTER_EMOTE", EMOTE},
    {"MONSTER_YELL", YELL},
    {"MONSTER_WHISPER", WHISPER},
    {"MONSTER_BOSS_EMOTE"},
    {"MONSTER_BOSS_WHISPER"},
	},
  OTHER_COMBAT = {
--    {"COMBAT_XP_GAIN"},
    {"COMBAT_HONOR_GAIN"},
    {"COMBAT_FACTION_CHANGE"},
    {"SKILL", SKILLUPS},
    {"LOOT", ITEM_LOOT},
    {"CURRENCY", CURRENCY},
    {"MONEY", MONEY_LOOT},
--    {"TRADESKILLS"},
--    {"OPENING"},
--    {"PET_INFO"},
--    {"COMBAT_MISC_INFO"},
  },

  OTHER_PVP = {
    {"BG_HORDE", BG_SYSTEM_HORDE},
    {"BG_ALLIANCE", BG_SYSTEM_ALLIANCE},
    {"BG_NEUTRAL", BG_SYSTEM_NEUTRAL},
  },

  OTHER_SYSTEM = {
    {"SYSTEM", SYSTEM_MESSAGES},
    {"ERRORS"},
    {"IGNORED"},
    {"CHANNEL"},
    {"TARGETICONS"},
    {"BN_INLINE_TOAST_ALERT"},
    {"PET_BATTLE_COMBAT_LOG"},
    {"PET_BATTLE_INFO"},
    {"PING"},
  },

  ADDONS = {
    {"ADDON", addonTable.Locales.ADDON_MESSAGES},
    {"DUMP", addonTable.Locales.DATA_DUMPS},
  }
}

local order = {
  {CHAT, "MESSAGES"},
  {CHANNELS, nil},
  {CREATURE, "OTHER_CREATURE"},
  {addonTable.Locales.REWARDS, "OTHER_COMBAT"},
  {PVP, "OTHER_PVP"},
  {SYSTEM, "OTHER_SYSTEM"},
  {addonTable.Locales.ADDONS, "ADDONS", true},
}

local function GetChatColor(group)
  local info = ChatTypeInfo[group]
  if not info then
    for _, event in ipairs(ChatTypeGroup[group]) do
      info = ChatTypeInfo[(event:gsub("CHAT_MSG_", ""))]
      if info then
        break
      end
    end
  end
  if not info then
    return CreateColor(1, 1, 1)
  end
  return CreateColor(info.r, info.g, info.b)
end

function addonTable.CustomiseDialog.SetupTabFilters(parent)
  local container = CreateFrame("Frame", nil, parent)
  local windowIndex, tabIndex = 1, 1
  local tab = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[windowIndex].tabs[tabIndex]

  local allFrames = {}
  local filtersHeader = addonTable.CustomiseDialog.Components.GetHeader(container, addonTable.Locales.MESSAGE_TYPES)
  filtersHeader:SetPoint("TOP")
  table.insert(allFrames, filtersHeader)

  for _, entry in ipairs(order) do
    local dropdown = addonTable.CustomiseDialog.Components.GetBasicDropdown(container, entry[1])
    dropdown:SetPoint("TOP", allFrames[#allFrames], "BOTTOM")
    dropdown.DropDown:SetDefaultText(addonTable.Locales.NONE_SELECTED)
    table.insert(allFrames, dropdown)
    local fields = LAYOUT[entry[2]]
    local force = entry[3]
    if not fields then
      dropdown.DropDown:SetupMenu(function(_, rootDescription)
        fields = {}
        local map, count = addonTable.Messages:GetChannels()
        for index = 1, count do
          if map[index] then
            table.insert(fields, {map[index], map[index], index})
          end
        end
        if tab.invert then
          for _, f in ipairs(fields) do
            local color = GetChatColor("CHANNEL" .. f[3])
            rootDescription:CreateCheckbox(color:WrapTextInColorCode(f[2] or _G[f[1]]),
              function()
                return tab.channels[f[1]] ~= false
              end, function()
                if tab.channels[f[1]] == nil then
                  tab.channels[f[1]] = false
                else
                  tab.channels[f[1]] = not tab.channels[f[1]]
                end
                addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
              end
            )
          end
        else
          for _, f in ipairs(fields) do
            rootDescription:CreateCheckbox(f[2] or _G[f[1]],
              function()
                return tab.channels[f[1]] == true
              end, function()
                tab.channels[f[1]] = not tab.channels[f[1]]
                addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
              end
            )
          end
        end
      end)
    else
      dropdown.DropDown:SetupMenu(function(_, rootDescription)
        if tab.invert then
          for _, f in ipairs(fields) do
            if ChatTypeGroup[f[1]] or force then
              local color = not force and GetChatColor(f[1]) or NORMAL_FONT_COLOR
              rootDescription:CreateCheckbox(color:WrapTextInColorCode(f[2] or _G[f[1]]),
                function()
                  return tab.groups[f[1]] ~= false
                end, function()
                  if tab.groups[f[1]] == nil then
                    tab.groups[f[1]] = false
                  else
                    tab.groups[f[1]] = not tab.groups[f[1]]
                  end
                  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
                end
              )
            end
          end
        else
          for _, f in ipairs(fields) do
            if ChatTypeGroup[f[1]] or force then
              local color = not force and GetChatColor(f[1]) or NORMAL_FONT_COLOR
              rootDescription:CreateCheckbox(color:WrapTextInColorCode(f[2] or _G[f[1]]),
                function()
                  return tab.groups[f[1]] == true
                end, function()
                  tab.groups[f[1]] = not tab.groups[f[1]]
                  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
                end
              )
            end
          end
        end
      end)
    end
  end
  container:SetSize(500, 500)

  local function UpdateHeader()
    filtersHeader.text:SetText(addonTable.Locales.MESSAGE_TYPES .. " (" .. addonTable.Locales.WINDOW_X:format(windowIndex) .. ", " .. addonTable.Locales.TAB_X:format(_G[tab.name] or tab.name) .. ")")
  end

  function container:ShowSettings(newWindowIndex, newTabIndex)
    windowIndex = newWindowIndex
    tabIndex = newTabIndex
    local windows = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)
    tab = windows[windowIndex].tabs[tabIndex]
    UpdateHeader()
    for _, f in ipairs(allFrames) do
      if f.DropDown then
        f:SetValue()
      end
    end
  end

  addonTable.CallbackRegistry:RegisterCallback("RefreshStateChange", function(_, state)
    if state[addonTable.Constants.RefreshReason.Tabs] then
      local windowData = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[windowIndex]
      local tabData = windowData and windowData.tabs[tabIndex]
      if not tabData then
        container:ShowSettings(1, 1)
      else
        UpdateHeader()
      end
    end
  end)

  return container
end

local customisers = {}
function addonTable.CustomiseDialog.ToggleTabFilters(windowIndex, tabIndex)
  if customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)] then
    local frame = customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)]
    frame:Show()
    frame.filters:ShowSettings(windowIndex, tabIndex)
    return
  end

  local frame = CreateFrame("Frame", "ChattynatorCustomiseTabDialog" .. addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN), UIParent, "ButtonFrameTemplate")
  frame:SetToplevel(true)
  customisers[addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)] = frame
  table.insert(UISpecialFrames, frame:GetName())
  frame:SetSize(600, 700)
  frame:SetPoint("CENTER")
  frame:Raise()

  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function()
    frame:StartMoving()
    frame:SetUserPlaced(false)
  end)
  frame:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    frame:SetUserPlaced(false)
  end)

  ButtonFrameTemplate_HidePortrait(frame)
  ButtonFrameTemplate_HideButtonBar(frame)
  frame.Inset:Hide()
  frame:EnableMouse(true)
  frame:SetScript("OnMouseWheel", function() end)

  frame:SetTitle(addonTable.Locales.CUSTOMISE_CHATTYNATOR_TAB)

  frame.filters = addonTable.CustomiseDialog.SetupTabFilters(frame)
  frame.filters:SetPoint("TOPLEFT", 0 + addonTable.Constants.ButtonFrameOffset, -35)
  frame.filters:SetPoint("BOTTOMRIGHT")

  frame.filters:ShowSettings(windowIndex, tabIndex)

  addonTable.Skins.AddFrame("ButtonFrame", frame, {"customise"})
end
