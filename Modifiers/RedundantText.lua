---@class addonTableChattynator
local addonTable = select(2, ...)

local lootPatterns = {
  {"^" .. LOOT_ITEM_PUSHED_SELF:gsub("%%s", "(.-)"), addonTable.Locales.SHORT_LOOT},
  {"^" .. LOOT_ITEM_SELF:gsub("%%s", "(.-)"), addonTable.Locales.SHORT_LOOT},
  {"^" .. LOOT_ITEM_PUSHED_SELF_MULTIPLE:gsub("%%s", "(.-)"):gsub("%%d", "(.-)"), addonTable.Locales.SHORT_LOOT_MULTIPLE},
  {"^" .. LOOT_ITEM_SELF_MULTIPLE:gsub("%%s", "(.-)"):gsub("%%d", "(.-)"), addonTable.Locales.SHORT_LOOT_MULTIPLE},
  {"^" .. CHANGED_OWN_ITEM:gsub("%.", "%%."):gsub("%%s", "(.-)"), addonTable.Locales.SHORT_LOOT_CHANGED},
  {"^" .. LOOT_ITEM:gsub("%.", "%%."):gsub("%%s", "(.-)"), addonTable.Locales.SHORT_LOOT_OTHER},
  {"^" .. LOOT_ITEM_MULTIPLE:gsub("%.", "%%."):gsub("%%s", "(.-)"):gsub("%%d", "(.-)"), addonTable.Locales.SHORT_LOOT_OTHER_MULTIPLE},
}
local currencyPatterns = {
  {"^" .. CURRENCY_GAINED:gsub("%%s", "(.-)"), addonTable.Locales.SHORT_LOOT},
  {"^" .. CURRENCY_GAINED_MULTIPLE:gsub("%%s", "(.-)"):gsub("%%d", "(.-)"), addonTable.Locales.SHORT_LOOT_MULTIPLE},
}
local xpPatterns = {
  {"^" .. COMBATLOG_XPGAIN_EXHAUSTION1:gsub("([()])", "%%%1"):gsub("%%d", "(.-)"):gsub("%%s", "(.-)"), addonTable.Locales.SHORT_XP_FROM_MOB_BONUS},
  {"^" .. COMBATLOG_XPGAIN_QUEST:gsub("([()])", "%%%1"):gsub("%%d", "(.-)"):gsub("%%s", "(.-)"), addonTable.Locales.SHORT_XP_BONUS},
  {"^" .. COMBATLOG_XPGAIN_FIRSTPERSON:gsub("%%d", "(.-)"):gsub("%%s", "(.-)"), addonTable.Locales.SHORT_XP_FROM_MOB},
  {"^" .. ERR_QUEST_REWARD_EXP_I:gsub("%%d", "(.-)"), addonTable.Locales.SHORT_XP},
  {"^" .. COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED:gsub("%%d", "(.-)"), addonTable.Locales.SHORT_XP},
}

local patternsByEvent = {
  ["MONSTER_SAY"] = {"^" .. CHAT_MONSTER_SAY_GET:gsub("%%s", "(.-)"), "%1:\32"},
  ["MONSTER_YELL"] = {"^" .. CHAT_MONSTER_YELL_GET:gsub("%%s", "(.-)"), "%1:\32"},
  ["MONSTER_WHISPER"] = {"^" .. CHAT_MONSTER_WHISPER_GET:gsub("%%s", "(.-)"), "%1:\32"},
  ["MONSTER_WHISPER"] = {"^" .. CHAT_MONSTER_WHISPER_GET:gsub("%%s", "(.-)"), "%1:\32"},
  ["SAY"] = {"^" .. CHAT_SAY_GET:gsub("%%s", "(.-)"), "%1:\32"},
  ["WHISPER"] = {"^" .. CHAT_WHISPER_GET:gsub("%%s", "(.-)"), "%1:\32"},
  ["WHISPER_INFORM"] = {"^" .. CHAT_WHISPER_INFORM_GET:gsub("%%s", "(.-)"), addonTable.Locales.SHORT_WHISPER_SEND},
  ["BN_WHISPER"] = {"^" .. CHAT_BN_WHISPER_GET:gsub("%%s", "(.-)"), "%1:\32"},
  ["BN_WHISPER_INFORM"] = {"^" .. CHAT_BN_WHISPER_INFORM_GET:gsub("%%s", "(.-)"), addonTable.Locales.SHORT_WHISPER_SEND},
  ["LOOT"] = lootPatterns,
  ["CURRENCY"] = currencyPatterns,
  ["MONEY"] = {"^" .. YOU_LOOT_MONEY:gsub("%%s", "(.-)"), addonTable.Locales.SHORT_LOOT},
  ["COMBAT_XP_GAIN"] = xpPatterns,
}

local function Cleanup(data)
  local byEvent = patternsByEvent[data.typeInfo.type]
  if byEvent then
    if type(byEvent[1]) ~= "table" then
      data.text = data.text:gsub(byEvent[1], byEvent[2])
    else
      local count
      for _, group in ipairs(byEvent) do
        data.text, count = data.text:gsub(group[1], group[2])
        if count > 0 then
          break
        end
      end
    end
  end
end

function addonTable.Modifiers.InitializeRedundantText()
  if addonTable.Config.Get(addonTable.Config.Options.REDUCE_REDUNDANT_TEXT) then
    addonTable.Messages:AddLiveModifier(Cleanup)
  end
  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.REDUCE_REDUNDANT_TEXT then
      if addonTable.Config.Get(addonTable.Config.Options.REDUCE_REDUNDANT_TEXT) then
        addonTable.Messages:AddLiveModifier(Cleanup)
      else
        addonTable.Messages:RemoveLiveModifier(Cleanup)
      end
    end
  end)
end
