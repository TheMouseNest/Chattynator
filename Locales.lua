---@class addonTableChattynator
local addonTable = select(2, ...)
local Locales = {
  enUS = {},
  frFR = {},
  deDE = {},
  ruRU = {},
  ptBR = {},
  esES = {},
  esMX = {},
  zhTW = {},
  zhCN = {},
  koKR = {},
  itIT = {},
}

CHATTYNATOR_LOCALES = Locales

local L = Locales.enUS

L["CHATTYNATOR"] = "Chattynator"
L["TO_OPEN_OPTIONS_X"] = "Access options with /chatty"
L["VERSION_COLON_X"] = "Version: %s"
L["OPEN_OPTIONS"] = "Open Options"
L["QUICK_CHAT"] = "Quick Chat"
L["COPY_CHAT"] = "Copy Chat"
L["UNKNOWN"] = "UNKNOWN"
L["CENSORED_CONTENTS_LOST"] = "Censored contents lost"
L["SCROLL_TO_END"] = "Scroll to end"
L["NEW_TAB"] = "New tab"
L["EMPTY_WINDOW"] = "Empty window"
L["MOVE_TO_NEW_WINDOW"] = "Move to new window"
L["CLOSE_TAB"] = "Close tab"
L["CLOSE_WINDOW"] = "Close window"
L["RENAME_TAB"] = "Rename tab"
L["TAB_SETTINGS"] = "Tab Settings"
L["BLIZZARD_SETTINGS"] = "Blizzard Settings"
L["GLOBAL_SETTINGS"] = "Global Settings"
L["UNLOCK_CHAT"] = "Unlock Chat"
L["LOCK_CHAT"] = "Lock Chat"
L["COPY_CHAT"] = "Copy Chat"
L["RENAME_X_MESSAGE"] = "Rename \"%s\" to:"
L["SEARCH_IN_X_MESSAGE"] = "Search in \"%s\" for:"

L["DISABLE_ADDON_X"] = "%s is incompatible with Chattynator and may cause glitches."

L["CANT_POPOUT_THIS_CHANNEL"] = "Can't popout this channel"

L["LAYOUT"] = "Layout"
L["DISPLAY"] = "Display"
L["FORMATTING"] = "Formatting"
L["MESSAGE_COLORS"] = "Message Colors"

L["CUSTOMISE_CHATTYNATOR"] = "Customise Chattynator"
L["CUSTOMISE_CHATTYNATOR_TAB"] = "Customise Chattynator Tab"
L["CTRL_C_TO_COPY"] = "Ctrl+C to copy"
L["JOIN_THE_DISCORD"] = "Join the Discord"
L["DISCORD_DESCRIPTION"] = "Updates, feature suggestions and support"
L["BY_PLUSMOUSE"] = "by plusmouse"
L["DEVELOPMENT_IS_TIME_CONSUMING"] = "|cff04cca4Development takes a huge amount of time|r"
L["DONATE"] = "Donate"
L["LINK"] = "Link"
L["SHOW_COMBAT_LOG"] = "Show Combat Log"
L["LOCK_CHAT"] = "Lock chat"
L["EDIT_BOX_POSITION"] = "Edit box position"
L["BOTTOM"] = "Bottom"
L["TOP"] = "Top"
L["KEEP_EDIT_BOX_VISIBLE"] = "Keep edit box visible"
L["SHOW_TABS"] = "Show tabs"
L["BUTTONS_POSITION"] = "Buttons position"
L["LEFT_OUTSIDE"] = "Left outside"
L["LEFT_INSIDE"] = "Left inside"
L["TABS_BELOW"] = "Below tabs"
L["TABS_ABOVE"] = "Above tabs"
L["SHOW_BUTTONS"] = "Show buttons"
L["NEW_WHISPERS_TO_NEW_TAB"] = "New whispers to new tab"
L["FLASH_TABS_ON"] = "Flash tabs on"
L["STORE_MESSAGES"] = "Store messages"
L["REMOVE_OLD_MESSAGES"] = "Remove old messages"
L["NEVER"] = "Never"
L["ALL_MESSAGES"] = "All messages"
L["WHISPERS_ONLY"] = "Whispers only"

L["MESSAGE_FONT_OUTLINE"] = "Message font outline"
L["MESSAGE_SPACING"] = "Message spacing"
L["LINE_SPACING"] = "Line spacing"
L["MESSAGE_FADE_TIME"] = "Message fade time"
L["MESSAGE_FONT_SHADOW"] = "Message font shadow"
L["ENABLE_MESSAGE_FADE"] = "Enable message fading"
L["TIMESTAMP"] = "Timestamp"
L["SHOW_VERTICAL_SEPARATOR"] = "Show vertical separator"
L["USE_CLASS_COLORS"] = "Use class colors"
L["THIN"] = "Thin"
L["THICK"] = "Thick"
L["ALWAYS"] = "Always"
L["MOUSEOVER"] = "Mouseover"
L["NEVER"] = "Never"

L["NONE"] = "None"
L["SHORTEN_STYLE_1"] = "Style 1: [1] [|cff00ff00Character|r]:"
L["SHORTEN_STYLE_2"] = "Style 2: W. |cff00ff00Character|r:"
L["SHORTEN_CHANNELS"] = "Shorten channels"
L["REDUCE_REDUNDANT_TEXT"] = "Reduce redundant text"
L["ABBREV_GENERAL_WORLD"] = "W"
L["ABBREV_TRADE"] = "T"
L["ABBREV_LOCAL_DEFENSE"] = "LD"
L["ABBREV_LOOKING_FOR_GROUP"] = "LFG"
L["ABBREV_NEWCOMER_CHAT"] = "NC"
L["ABBREV_SERVICES"] = "S"
L["ABBREV_GUILD"] = "G"
L["ABBREV_OFFICER"] = "O"
L["ABBREV_PARTY"] = "P"
L["ABBREV_PARTY_LEADER"] = "PL"
L["ABBREV_INSTANCE"] = "I"
L["ABBREV_INSTANCE_LEADER"] = "IL"
L["ABBREV_RAID"] = "R"
L["ABBREV_RAID_LEADER"] = "RL"
L["SHORT_LOOT"] = "Loot: %1"
L["SHORT_LOOT_MULTIPLE"] = "Loot: %1x%2"
L["SHORT_LOOT_CHANGED"] = "Changed: %1 to %2"
L["SHORT_LOOT_OTHER"] = "%1 looted: %2"
L["SHORT_LOOT_OTHER_MULTIPLE"] = "%1 looted: %2x%3"
L["SHORT_WHISPER_SEND"] = "To %1:\32"
L["SHORT_XP"] = "XP: %1"
L["SHORT_XP_BONUS"] = "XP: %1%2 (%3)"
L["SHORT_XP_FROM_MOB"] = "XP: %2, from %1"
L["SHORT_XP_FROM_MOB_BONUS"] = "XP: %2%3 (%4), from %1"
L["SHORT_ACHIEVEMENT_OTHER"] = "%1 earned %2"

L["MESSAGE_FONT"] = "Message font"
L["MESSAGE_FONT_SIZE"] = "Message font size"

L["ALL_ADDONS"] = "All Addons"
L["SPECIFIC_ADDONS"] = "Specific Addons"
L["LEAVE_UNTICKED_ADDONS"] = "Leave unticked to control which addons show"
L["ADDONS"] = "Addons"
L["DATA_DUMPS"] = "Data Dumps"
L["RUN_OR_WA"] = "/run or WAs"

L["SELECT_TYPE_TO_CHANGE"] = "Select type to change?"

L["BLIZZARD"] = "Blizzard"
L["DARK"] = "Dark"
L["GW2_UI"] = "GW2 UI"
L["ELVUI"] = "ElvUI"
L["THEME"] = "Theme"
L["RELOAD_REQUIRED"] = "Reload required. Reload now?"
L["RELOAD"] = "Reload"
L["FADE_CHAT_WHEN_NOT_IN_USE"] = "Fade chat when not in use"

L["TAB_TRANSPARENCY"] = "Tab transparency"
L["CHAT_TRANSPARENCY"] = "Chat transparency"
L["SOLID_CHAT_BACKGROUND"] = "Solid chat background"
L["BACKGROUND_COLOR"] = "Background Color"
L["TAB_COLOR"] = "Tab Color"

L["MESSAGE_TYPES"] = "Message types"
L["NONE_SELECTED"] = "None Selected"
L["REWARDS"] = "Rewards"
L["WINDOW_X"] = "Window %s"
L["TAB_X"] = "%s Tab"
L["RENAMING_TAB_X"] = "Renaming tab \"%s\""

L["ENTER_PROFILE_NAME"] = "Enter Profile Name:"
L["PROFILES"] = "Profiles"
L["NEW_PROFILE_CLONE"] = "New Profile (clone current)"
L["NEW_PROFILE_BLANK"] = "New Profile (blank)"
L["CONFIRM_DELETE_PROFILE_X"] = "Are you sure you want to delete profile \"%s\"?"

L["SPECIAL_TABS"] = "Special tabs"
L["TOGGLE_COMBAT_LOG_ETC"] = "Toggle combat log, etc."

L["SLASH_RESET"] = "reset"
L["SLASH_RESET_HELP"] = "Reset all Chattynator settings, then reload."
L["SLASH_HELP"] = "Open the Chattynator settings."
L["SLASH_UNKNOWN_COMMAND"] = "Unknown command '%s'"

L["TABSIZE_PADDING"] = "Tab Padding"
L["TABSIZE_SPACING"] = "Tab Spacing"

local L = Locales.frFR
--@localization(locale="frFR", format="lua_additive_table")@

local L = Locales.deDE
--@localization(locale="deDE", format="lua_additive_table")@

local L = Locales.ruRU
--@localization(locale="ruRU", format="lua_additive_table")@

local L = Locales.ptBR
--@localization(locale="ptBR", format="lua_additive_table")@

local L = Locales.esES
--@localization(locale="esES", format="lua_additive_table")@

local L = Locales.esMX
--@localization(locale="esMX", format="lua_additive_table")@

local L = Locales.zhTW
--@localization(locale="zhTW", format="lua_additive_table")@

local L = Locales.zhCN
--@localization(locale="zhCN", format="lua_additive_table")@

local L = Locales.koKR
--@localization(locale="koKR", format="lua_additive_table")@

local L = Locales.itIT
--@localization(locale="itIT", format="lua_additive_table")@
