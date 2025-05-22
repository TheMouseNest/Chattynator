---@class addonTableChatanator
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

local function GetTypeCheckbox(parent, typeData, callback)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetHeight(30)
  holder:SetPoint("LEFT", parent)
  holder:SetPoint("RIGHT", parent)
  local checkBox = CreateFrame("CheckButton", nil, holder, "SettingsCheckboxTemplate")

  checkBox:SetPoint("LEFT", holder, "CENTER", -15, 0)
  checkBox:SetText(typeData[2] or _G[typeData[1]] or UNKNOWN)
  checkBox:SetNormalFontObject(GameFontHighlight)
  checkBox:GetFontString():SetPoint("RIGHT", holder, "CENTER", -30, 0)

  addonTable.Skins.AddFrame("CheckBox", checkBox)

  function holder:SetValue(value)
    checkBox:SetChecked(value)
  end

  holder:SetScript("OnEnter", function()
    checkBox:OnEnter()
  end)

  holder:SetScript("OnLeave", function()
    checkBox:OnLeave()
  end)

  holder:SetScript("OnMouseUp", function()
    checkBox:Click()
  end)

  checkBox:SetScript("OnClick", function()
    callback(typeData[1], checkBox:GetChecked())
  end)

  return holder
end

function addonTable.CustomiseDialog.SetupTabFilters(parent)
  local container = CreateFrame("Frame", nil, parent)

  container.checkboxes = {}
  local lastCB
  for _, data in ipairs(LAYOUT.MESSAGES) do
    local cb = GetTypeCheckbox(container, data, function(group, enabled)
      container.tabData.groups[group] = enabled
      addonTable.CallbackRegistry:TriggerEvent("Render")
    end)
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
