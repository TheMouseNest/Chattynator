---@class addonTableChatanator
local addonTable = select(2, ...)
addonTable.Locales = CopyTable(CHATANATOR_LOCALES.enUS)
for key, translation in pairs(CHATANATOR_LOCALES[GetLocale()]) do
  addonTable.Locales[key] = translation
end
for key, translation in pairs(addonTable.Locales) do
  _G["CHATANATOR_L_" .. key] = translation

  if key:match("^BINDING") then
    _G["CHATANATOR_NAME_BAGANATOR_" .. key:match("BINDING_(.*)")] = translation
  end
end
