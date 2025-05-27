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
    {"BG_SYSTEM_HORDE"},
    {"BG_SYSTEM_ALLIANCE"},
    {"BG_SYSTEM_NEUTRAL"},
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
  }
}

local order = {
  {CHAT, "MESSAGES"},
  {CHANNELS, nil},
  {CREATURE, "OTHER_CREATURE"},
  {COMBAT, "OTHER_COMBAT"},
  {PVP, "OTHER_PVP"},
  {SYSTEM, "OTHER_SYSTEM"},
}

function addonTable.CustomiseDialog.SetupTabFilters(parent)
  local container = CreateFrame("Frame", nil, parent)
  local tab = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[1].tabs[1]

  local allFrames = {}
  local filtersHeader = addonTable.CustomiseDialog.Components.GetHeader(container, addonTable.Locales.MESSAGE_TYPES_TO_INCLUDE)
  filtersHeader:SetPoint("TOP")
  table.insert(allFrames, filtersHeader)

  for _, entry in ipairs(order) do
    local dropdown = addonTable.CustomiseDialog.Components.GetBasicDropdown(container, entry[1])
    dropdown:SetPoint("TOP", allFrames[#allFrames], "BOTTOM")
    dropdown.DropDown:SetDefaultText(addonTable.Locales.NONE_SELECTED)
    table.insert(allFrames, dropdown)
    local fields = LAYOUT[entry[2]]
    if not fields then
      fields = {}
      local map, count = addonTable.Messages:GetChannels()
      for index = 1, count do
        if map[index] then
          table.insert(fields, {map[index], map[index]})
        end
      end
      dropdown.DropDown:SetupMenu(function(_, rootDescription)
        if tab.invert then
          for _, f in ipairs(fields) do
            rootDescription:CreateCheckbox(f[2] or _G[f[1]],
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
            rootDescription:CreateCheckbox(f[2] or _G[f[1]],
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
        else
          for _, f in ipairs(fields) do
            rootDescription:CreateCheckbox(f[2] or _G[f[1]],
              function()
                return tab.groups[f[1]] == true
              end, function()
                tab.groups[f[1]] = not tab.groups[f[1]]
                addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
              end
            )
          end
        end
      end)
    end
  end
  container:SetSize(500, 500)

  function container:ShowSettings(tabData)
    tab = tabData
    for _, f in ipairs(allFrames) do
      if f.DropDown then
        f:SetValue()
      end
    end
  end

  return container
end
