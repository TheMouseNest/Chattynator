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

function addonTable.CustomiseDialog.SetupTabFilters(parent)
  local container = CreateFrame("Frame", nil, parent)

  container.checkboxes = {}
  local lastCB
  for _, data in ipairs(LAYOUT.MESSAGES) do
    local cb = addonTable.CustomiseDialog.Components.GetCheckbox(container, data[2] or _G[data[1]] or UNKNOWN, nil, function(enabled)
      container.tabData.groups[data[1]] = enabled
      addonTable.CallbackRegistry:TriggerEvent("ScrollToEndImmediate")
      addonTable.CallbackRegistry:TriggerEvent("Render")
    end)
    cb:SetHeight(30)
    container.checkboxes[data[1]] = cb
    if lastCB then
      cb:SetPoint("TOP", lastCB, "BOTTOM")
    else
      cb:SetPoint("TOP")
    end
    lastCB = cb
  end
  container:SetSize(500, 500)

  function container:ShowSettings(tabData)
    container.tabData = tabData

    if tabData.invert then
      for group, checkbox in pairs(container.checkboxes) do
        checkbox:SetValue(tabData.groups[group] ~= false)
      end
    else
      for group, checkbox in pairs(container.checkboxes) do
        checkbox:SetValue(tabData.groups[group] == true)
      end
    end
  end

  return container
end
