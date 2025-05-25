---@class addonTableChattynator
local addonTable = select(2, ...)
addonTable.Locales = CopyTable(CHATTYNATOR_LOCALES.enUS)
for key, translation in pairs(CHATTYNATOR_LOCALES[GetLocale()]) do
  addonTable.Locales[key] = translation
end
for key, translation in pairs(addonTable.Locales) do
  _G["CHATTYNATOR_L_" .. key] = translation

  if key:match("^BINDING") then
    _G["CHATTYNATOR_NAME_BAGANATOR_" .. key:match("BINDING_(.*)")] = translation
  end
end
