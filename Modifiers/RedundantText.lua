---@class addonTableChattynator
local addonTable = select(2, ...)

local function Clean(text)
  return "^" .. text:gsub("([%^$().%[%]*+-?)])", "%%%1"):gsub("%%s", "(.-)"):gsub("%%d", "(.-)")
end

local lootPatterns = {
  {Clean(LOOT_ITEM_PUSHED_SELF), addonTable.Locales.SHORT_LOOT},
  {Clean(LOOT_ITEM_SELF), addonTable.Locales.SHORT_LOOT},
  {Clean(LOOT_ITEM_PUSHED_SELF_MULTIPLE), addonTable.Locales.SHORT_LOOT_MULTIPLE},
  {Clean(LOOT_ITEM_SELF_MULTIPLE), addonTable.Locales.SHORT_LOOT_MULTIPLE},
  {Clean(CHANGED_OWN_ITEM), addonTable.Locales.SHORT_LOOT_CHANGED},
  {Clean(LOOT_ITEM), addonTable.Locales.SHORT_LOOT_OTHER},
  {Clean(LOOT_ITEM_MULTIPLE), addonTable.Locales.SHORT_LOOT_OTHER_MULTIPLE},
}
local currencyPatterns = {
  {Clean(CURRENCY_GAINED), addonTable.Locales.SHORT_LOOT},
  {Clean(CURRENCY_GAINED_MULTIPLE), addonTable.Locales.SHORT_LOOT_MULTIPLE},
}
local xpPatterns = {
  {Clean(COMBATLOG_XPGAIN_EXHAUSTION1), addonTable.Locales.SHORT_XP_FROM_MOB_BONUS},
  {Clean(COMBATLOG_XPGAIN_QUEST), addonTable.Locales.SHORT_XP_BONUS},
  {Clean(COMBATLOG_XPGAIN_FIRSTPERSON), addonTable.Locales.SHORT_XP_FROM_MOB},
  {Clean(COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED), addonTable.Locales.SHORT_XP},
}
local questPatterns = {
  {Clean(ERR_QUEST_REWARD_EXP_I), addonTable.Locales.SHORT_XP},
  {Clean(ERR_QUEST_REWARD_MONEY_S), addonTable.Locales.SHORT_LOOT},
}

local patternsByEvent = {
  ["MONSTER_SAY"] = {Clean(CHAT_MONSTER_SAY_GET), "%1:\32"},
  ["MONSTER_YELL"] = {Clean(CHAT_MONSTER_YELL_GET), "%1:\32"},
  ["MONSTER_WHISPER"] = {Clean(CHAT_MONSTER_WHISPER_GET), "%1:\32"},
  ["SAY"] = {Clean(CHAT_SAY_GET), "%1:\32"},
  ["WHISPER"] = {Clean(CHAT_WHISPER_GET), "%1:\32"},
  ["WHISPER_INFORM"] = {Clean(CHAT_WHISPER_INFORM_GET), addonTable.Locales.SHORT_WHISPER_SEND},
  ["BN_WHISPER"] = {Clean(CHAT_BN_WHISPER_GET), "%1:\32"},
  ["BN_WHISPER_INFORM"] = {Clean(CHAT_BN_WHISPER_INFORM_GET), addonTable.Locales.SHORT_WHISPER_SEND},
  ["LOOT"] = lootPatterns,
  ["CURRENCY"] = currencyPatterns,
  ["MONEY"] = {Clean(YOU_LOOT_MONEY), addonTable.Locales.SHORT_LOOT},
  ["COMBAT_XP_GAIN"] = xpPatterns,
  ["SYSTEM"] = questPatterns,
  ["GUILD_ACHIEVEMENT"] = {Clean(ACHIEVEMENT_BROADCAST), addonTable.Locales.SHORT_ACHIEVEMENT_OTHER},
  ["ACHIEVEMENT"] = {Clean(ACHIEVEMENT_BROADCAST), addonTable.Locales.SHORT_ACHIEVEMENT_OTHER},
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
