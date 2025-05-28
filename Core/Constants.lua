---@class addonTableChattynator
local addonTable = select(2, ...)

addonTable.Constants = {
  IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
  --IsMists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC,
  --IsCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC,
  --IsWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC,
  --IsEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC,
  IsClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE,

  NewTabMarkup = CreateTextureMarkup("Interface/AddOns/Chattynator/Assets/NewTab.png", 40, 40, 15, 15, 0, 1, 0, 1)
}
if addonTable.Constants.IsRetail then
  addonTable.Constants.ButtonFrameOffset = 5
else
  addonTable.Constants.ButtonFrameOffset = 0
end
addonTable.Constants.Events = {
  "ScrollToEndImmediate",
  "Render",

  "TabSelected",

  "SettingChanged",
  "RefreshStateChange",
  "MessageDisplayChanged"
}

addonTable.Constants.RefreshReason = {
  Tabs = 1,
  MessageFont = 2,
  MessageWidget = 3,
  Locked = 1000,
}
