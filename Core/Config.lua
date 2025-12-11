---@class addonTableChattynator
local addonTable = select(2, ...)
addonTable.Config = {}

function addonTable.Config.GetEmptyTabConfig(name)
  return {
    name = name,
    groups = {},
    channels = {},
    addons = {},
    backgroundColor = "1a1a1a", tabColor = "b5926c",
    whispersTemp = {}, filters = {},
    isTemporary = false,
  }
end

function addonTable.Config.GetEmptyWindowConfig()
  return {
    position = {"CENTER", "UIParent", "CENTER", 0, 0},
    size = {500, 280},
    tabs = {}
  }
end

local settings = {
  WINDOWS = {key = "windows", default = {
    {
      position = {"BOTTOMLEFT", "UIParent", "BOTTOMLEFT", 0, 40},
      size = {500, 280},
      tabs = {
        {
          name = "GENERAL",
          groups = {
            ["TRADESKILLS"] = false,
            ["COMBAT_MISC_INFO"] = false,
            ["COMBAT_XP_GAIN"] = false,
            ["PET_BATTLE_COMBAT_LOG"] = false,
            ["PET_INFO"] = false,
            ["OPENING"] = false,
            ["VOICE_TEXT"] = false,
          },
          invert = true,
          channels = {}, backgroundColor = "1a1a1a", tabColor = "06a1ff",
          whispersTemp = {}, filters = {},
          isTemporary = false,
        },
        {
          name = "GUILD",
          groups = {
            ["GUILD"] = true,
            ["OFFICER"] = true,
            ["GUILD_ACHIEVEMENT"] = true,
          },
          channels = {}, backgroundColor = "1a1a1a", tabColor = "309944",
          whispersTemp = {}, filters = {},
          isTemporary = false,
        },
      },
    },
    --[[{
      position = {"TOPRIGHT", "UIParent", "TOPRIGHT", -200, -40},
      size = {500, 200},
      tabs = {
        {
          name = "LOOT",
          groups = {
            ["LOOT"] = true,
            ["CURRENCY"] = true,
            ["MONEY"] = true,
          },
          channels = {}, backgroundColor = "000000", tabColor = "111111",
          whispers = {}, filters = {}
        },
      },
    },]]
  },
    refresh = {addonTable.Constants.RefreshReason.Tabs}
  },

  EDIT_BOX_POSITION = {key = "edit_box_position", default = "bottom"},

  SKINS = {key = "skins", default = {}},
  DISABLED_SKINS = {key = "disabled_skins", default = {}},
  CURRENT_SKIN = {key = "current_skin", default = "dark"},

  STORE_MESSAGES = {key = "store_messages", default = true},
  REMOVE_OLD_MESSAGES = {key = "remove_old_messages", default = true},

  SHOW_COMBAT_LOG = {key = "show_combat_log", default = true, refresh = {addonTable.Constants.RefreshReason.Tabs}},
  COMBAT_LOG_MIGRATION = {key = "combat_log_migration", default = 0},

  LOCKED = {key = "locked", default = false, refresh = {addonTable.Constants.RefreshReason.Tabs, addonTable.Constants.RefreshReason.Locked}},

  LINE_SPACING = {key = "line_spacing_2", default = 0},
  MESSAGE_SPACING = {key = "message_spacing", default = 5},
  TIMESTAMP_FORMAT = {key = "timestamp_format", default = "%X"},
  SHOW_TIMESTAMP_SEPARATOR = {key = "show_timestamp_separator", default = true, refresh = {addonTable.Constants.RefreshReason.MessageWidget}},

  MESSAGE_FONT = {key = "message_font", default = "default", refresh = {addonTable.Constants.RefreshReason.MessageFont}},
  MESSAGE_FONT_SIZE = {key = "message_font_size", default = 14, refresh = {addonTable.Constants.RefreshReason.MessageFont}},
  MESSAGE_FONT_OUTLINE = {key = "message_font_outline", default = "none", refresh = {addonTable.Constants.RefreshReason.MessageFont}},
  MESSAGE_FADE_TIME = {key = "message_fade_time", default = 25},
  ENABLE_MESSAGE_FADE = {key = "enable_message_fade", default = true},
  ENABLE_SMOOTH_SCROLLING_COMBAT = {key = "enable_smooth_scrolling_combat", default = false},
  TAB_FLASH_ON = {key = "tab_flash_on", default = "all"},
  SHOW_FONT_SHADOW = {key = "show_font_shadow", default = false, refresh = {addonTable.Constants.RefreshReason.MessageFont}},

  SHORTEN_FORMAT = {key = "shorten_format", default = "none", refresh = {addonTable.Constants.RefreshReason.MessageModifier}},
  CLASS_COLORS = {key = "class_colors", default = true, refresh = {addonTable.Constants.RefreshReason.MessageModifier}},
  LINK_URLS = {key = "link_urls", default = true, refresh = {addonTable.Constants.RefreshReason.MessageModifier}},
  REDUCE_REDUNDANT_TEXT = {key = "reduce_redundant_text", default = false, refresh = {addonTable.Constants.RefreshReason.MessageModifier}},

  NEW_WHISPER_NEW_TAB = {key = "new_whisper_new_tab", default = 0},
  BUTTON_POSITION = {key = "button_position", default = "outside_left"},
  SHOW_BUTTONS = {key = "show_buttons", default = "unset"},
  SHOW_TABS = {key = "show_tabs_1", default = "always", refresh = {addonTable.Constants.RefreshReason.Tabs}},

  COPY_TIMESTAMPS = {key = "copy_timestamps", default = true},
  ENABLE_COMBAT_MESSAGES = {key = "enable_combat_messages", default = false},
  DEBUG = {key = "debug", default = false},

  APPLIED_MESSAGE_IDS = {key = "applied_message_ids", default = false, transfer = true},
  APPLIED_PLAYER_TABLE = {key = "applied_player_table_5", default = false, transfer = true},

  CHAT_COLORS = {key = "chat_colors", default = {}, refresh = {addonTable.Constants.RefreshReason.MessageColor}}
}

addonTable.Config.RefreshType = {}

addonTable.Config.Options = {}
addonTable.Config.Defaults = {}
local transferToProfile = {}

for key, details in pairs(settings) do
  if details.refresh then
    local refreshType = {}
    for _, r in ipairs(details.refresh) do
      refreshType[r] = true
    end
    addonTable.Config.RefreshType[details.key] = refreshType
  end
  if details.transfer then
    transferToProfile[details.key] = true
  end
  addonTable.Config.Options[key] = details.key
  addonTable.Config.Defaults[details.key] = details.default
end

function addonTable.Config.IsValidOption(name)
  for _, option in pairs(addonTable.Config.Options) do
    if option == name then
      return true
    end
  end
  return false
end

local function RawSet(name, value)
  local tree = {strsplit(".", name)}
  if addonTable.Config.CurrentProfile == nil then
    error("CHATTYNATOR_CONFIG not initialized")
  elseif not addonTable.Config.IsValidOption(tree[1]) then
    error("Invalid option '" .. name .. "'")
  elseif #tree == 1 then
    local oldValue = addonTable.Config.CurrentProfile[name]
    addonTable.Config.CurrentProfile[name] = value
    if value ~= oldValue then
      return true
    end
  else
    local root = addonTable.Config.CurrentProfile
    for i = 1, #tree - 1 do
      root = root[tree[i]]
      if type(root) ~= "table" then
        error("Invalid option '" .. name .. "', broke at [" .. i .. "]")
      end
    end
    local tail = tree[#tree]
    if root[tail] == nil then
      error("Invalid option '" .. name .. "', broke at [tail]")
    end
    local oldValue = root[tail]
    root[tail] = value
    if value ~= oldValue then
      return true
    end
  end
  return false
end

function addonTable.Config.Set(name, value)
  if RawSet(name, value) then
    addonTable.CallbackRegistry:TriggerEvent("SettingChanged", name)
    if addonTable.Config.RefreshType[name] then
      addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", addonTable.Config.RefreshType[name])
    end
  end
end

-- Set multiple settings at once and after all are set fire the setting changed
-- events
function addonTable.Config.MultiSet(nameValueMap)
  local changed = {}
  for name, value in pairs(nameValueMap) do
    if RawSet(name, value) then
      table.insert(changed, name)
    end
  end

  local refreshState = {}
  for _, name in ipairs(changed) do
    addonTable.CallbackRegistry:TriggerEvent("SettingChanged", name)
    if addonTable.Config.RefreshType[name] then
      refreshState = Mixin(refreshState, addonTable.Config.RefreshType[name])
    end
  end
  if next(refreshState) ~= nil then
    addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", refreshState)
  end
end

local addedInstalledNestedToList = {}
local installedNested = {}

function addonTable.Config.Install(name, defaultValue)
  if CHATTYNATOR_CONFIG == nil then
    error("CHATTYNATOR_CONFIG not initialized")
  elseif name:find("%.") == nil then
    if addonTable.Config.CurrentProfile[name] == nil then
      addonTable.Config.CurrentProfile[name] = defaultValue
    end
  else
    if not addedInstalledNestedToList[name] then
      addedInstalledNestedToList[name] = true
      table.insert(installedNested, name)
    end
    local tree = {strsplit(".", name)}
    local root = addonTable.Config.CurrentProfile
    for i = 1, #tree - 1 do
      if not root[tree[i]] then
        root[tree[i]] = {}
      end
      root = root[tree[i]]
    end
    if root[tree[#tree]] == nil then
      root[tree[#tree]] = defaultValue
    end
  end
end

function addonTable.Config.ResetOne(name)
  local newValue = addonTable.Config.Defaults[name]
  if newValue == nil then
    error("Can't reset that", name)
  else
    if type(newValue) == "table" then
      newValue = CopyTable(newValue)
    end
    addonTable.Config.Set(name, newValue)
  end
end

function addonTable.Config.Reset()
  CHATTYNATOR_CONFIG = {
    Profiles = {
      DEFAULT = {},
    },
    CharacterSpecific = {},
    Version = 1,
  }
  addonTable.Config.InitializeData()
end

local function ImportDefaultsToProfile()
  for option, value in pairs(addonTable.Config.Defaults) do
    if addonTable.Config.CurrentProfile[option] == nil then
      if type(value) == "table" then
        addonTable.Config.CurrentProfile[option] = CopyTable(value)
      else
        addonTable.Config.CurrentProfile[option] = value
      end
    end
  end
end

function addonTable.Config.InitializeData()
  if CHATTYNATOR_CONFIG == nil then
    addonTable.Config.Reset()
    return
  end

  if CHATTYNATOR_CONFIG.Profiles == nil then
    CHATTYNATOR_CONFIG = {
      Profiles = {
        DEFAULT = CHATTYNATOR_CONFIG,
      },
      CharacterSpecific = {},
      Version = 1,
    }
  end

  if CHATTYNATOR_CONFIG.Profiles.DEFAULT == nil then
    CHATTYNATOR_CONFIG.Profiles.DEFAULT = {}
  end
  if CHATTYNATOR_CONFIG.Profiles[CHATTYNATOR_CURRENT_PROFILE] == nil then
    CHATTYNATOR_CURRENT_PROFILE = "DEFAULT"
  end

  addonTable.Config.CurrentProfile = CHATTYNATOR_CONFIG.Profiles[CHATTYNATOR_CURRENT_PROFILE]
  ImportDefaultsToProfile()
end

function addonTable.Config.GetProfileNames()
  return GetKeysArray(CHATTYNATOR_CONFIG.Profiles)
end

function addonTable.Config.MakeProfile(newProfileName, clone)
  assert(tIndexOf(addonTable.Config.GetProfileNames(), newProfileName) == nil, "Existing Profile")
  if clone then
    CHATTYNATOR_CONFIG.Profiles[newProfileName] = CopyTable(addonTable.Config.CurrentProfile)
  else
    CHATTYNATOR_CONFIG.Profiles[newProfileName] = {}
    for key in pairs(transferToProfile) do
      CHATTYNATOR_CONFIG.Profiles[newProfileName][key] = addonTable.Config.Get(key)
    end
  end
  addonTable.Config.ChangeProfile(newProfileName)
end

function addonTable.Config.DeleteProfile(profileName)
  assert(profileName ~= "DEFAULT" and profileName ~= CHATTYNATOR_CURRENT_PROFILE)

  CHATTYNATOR_CONFIG.Profiles[profileName] = nil
end

function addonTable.Config.ChangeProfile(newProfileName)
  assert(tIndexOf(addonTable.Config.GetProfileNames(), newProfileName) ~= nil, "Invalid Profile")

  local changedOptions = {}
  local refreshState = {}
  local newProfile = CHATTYNATOR_CONFIG.Profiles[newProfileName]

  for name, value in pairs(addonTable.Config.CurrentProfile) do
    if value ~= newProfile[name] then
      table.insert(changedOptions, name)
      Mixin(refreshState, addonTable.Config.RefreshType[name] or {})
    end
  end

  tAppendAll(changedOptions, installedNested)

  addonTable.Config.CurrentProfile = newProfile
  CHATTYNATOR_CURRENT_PROFILE = newProfileName

  ImportDefaultsToProfile()

  addonTable.Core.MigrateSettings()

  for _, name in ipairs(changedOptions) do
    addonTable.CallbackRegistry:TriggerEvent("SettingChanged", name)
  end
  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", refreshState)
end

-- characterName is optional, only use if need a character specific setting for
-- a character other than the current one.
function addonTable.Config.Get(name)
  -- This is ONLY if a config is asked for before variables are loaded
  if addonTable.Config.CurrentProfile == nil then
    return addonTable.Config.Defaults[name]
  elseif name:find("%.") == nil then
    return addonTable.Config.CurrentProfile[name]
  else
    local tree = {strsplit(".", name)}
    local root = addonTable.Config.CurrentProfile
    for i = 1, #tree do
      root = root[tree[i]]
      if root == nil then
        break
      end
    end
    return root
  end
end
