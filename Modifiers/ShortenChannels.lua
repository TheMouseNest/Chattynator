---@class addonTableChattynator
local addonTable = select(2, ...)

local channel = addonTable.Constants.ChannelIDs
local channelMapping = {
  [channel.General] = addonTable.Locales.ABBREV_GENERAL_WORLD,
  [channel.Trade] = addonTable.Locales.ABBREV_TRADE,
  [channel.LocalDefense] = addonTable.Locales.ABBREV_LOCAL_DEFENSE,
  [channel.WorldDefense] = addonTable.Locales.ABBREV_LOCAL_DEFENSE,
  [channel.LookingForGroup] = addonTable.Locales.ABBREV_LOOKING_FOR_GROUP,
  [channel.NewcomerChat] = addonTable.Locales.ABBREV_NEWCOMER_CHAT,
  [channel.Services] = addonTable.Locales.ABBREV_SERVICES,
}

local letterStyle = {
  player = {
    p = "(|Hplayer%w*:[^|]-|h)%[([^%[%]]-)%](|h)",
    r = "%1%2%3",
  },
  channel = {
    p = "(%|Hchannel:channel:.-|h)%[?.-%]?(|h)",
    r = function(data)
      local index = data.typeInfo.channel.index or 0
      local map = channelMapping[data.typeInfo.channel.zoneID]
      return "%1" .. (map or index) .. ".%2"
    end,
  },
  guild = {
    p = "(|Hchannel:GUILD|h).-(|h)",
    r = "%1" .. addonTable.Locales.ABBREV_GUILD .. ".%2",
  },
  officer = {
    p = "(|Hchannel:OFFICER|h).-(|h)",
    r = "%1" .. addonTable.Locales.ABBREV_OFFICER .. ".%2",
  },
  party = {
    p = "(|Hchannel:PARTY|h).-(|h)",
    r = "%1" .. addonTable.Locales.ABBREV_PARTY .. ".%2",
  },
  partyLeader = {
    p = "(|Hchannel:PARTY|h).-(|h)",
    r = "%1" .. addonTable.Locales.ABBREV_PARTY_LEADER .. ".%2",
  },
  instance = {
    p = "(|Hchannel:INSTANCE_CHAT|h).-(|h)",
    r = "%1" .. addonTable.Locales.ABBREV_INSTANCE .. ".%2",
  },
  instanceLeader = {
    p = "(|Hchannel:INSTANCE_CHAT|h).-(|h)",
    r = "%1" .. addonTable.Locales.ABBREV_INSTANCE_LEADER .. ".%2",
  },
  raid = {
    p = "(|Hchannel:RAID|h).-(|h)",
    r = "%1" .. addonTable.Locales.ABBREV_RAID .. ".%2",
  },
  raidLeader = {
    p = "(|Hchannel:RAID|h).-(|h)",
    r = "%1" .. addonTable.Locales.ABBREV_RAID_LEADER .. ".%2",
  },
}

local numberStyle = {
  player = {
    p = "(|Hplayer:[^|]-%|h)([^%[%]]-)(|h)",
    r = "%1[%2]%3",
  },
  channel = {
    p = "(%|Hchannel%:channel%:[^|]-%|h)%[?[^%[%]]-%]?(%|h)",
    r = function(data)
      local index = data.typeInfo.channel.index or 0
      return "%1[" .. index .. "]%2"
    end,
  },
  guild = {
    p = "(|Hchannel:GUILD|h).-(|h)",
    r = "%1[" .. addonTable.Locales.ABBREV_GUILD .. "]%2",
  },
  officer = {
    p = "(|Hchannel:OFFICER|h).-(|h)",
    r = "%1[" .. addonTable.Locales.ABBREV_OFFICER .. "]%2",
  },
  party = {
    p = "(|Hchannel:PARTY|h).-(|h)",
    r = "%1[" .. addonTable.Locales.ABBREV_PARTY .. "]%2",
  },
  partyLeader = {
    p = "(|Hchannel:PARTY|h).-(|h)",
    r = "%1[" .. addonTable.Locales.ABBREV_PARTY_LEADER .. "]%2",
  },
  instance = {
    p = "(|Hchannel:INSTANCE_CHAT|h).-(|h)",
    r = "%1[" .. addonTable.Locales.ABBREV_INSTANCE .. "]%2",
  },
  instanceLeader = {
    p = "(|Hchannel:INSTANCE_CHAT|h).-(|h)",
    r = "%1[" .. addonTable.Locales.ABBREV_INSTANCE_LEADER .. "]%2",
  },
  raid = {
    p = "(|Hchannel:RAID|h).-(|h)",
    r = "%1[" .. addonTable.Locales.ABBREV_RAID .. "]%2",
  },
  raidLeader = {
    p = "(|Hchannel:RAID|h).-(|h)",
    r = "%1[" .. addonTable.Locales.ABBREV_RAID_LEADER .. "]%2",
  },
}

local typeToPattern = {
  ["none"] = nil,
  ["letter"] = letterStyle,
  ["number"] = numberStyle,
}

local chatTypeToPatterns = {
  OFFICER = "officer",
  PARTY = "party",
  PARTY_LEADER = "partyLeader",
  INSTANCE_CHAT = "instance",
  INSTANCE_CHAT_LEADER = "instanceLeader",
  RAID = "raid",
  RAID_LEADER = "raidLeader",
}

local patterns

local function Shorten(data)
  data.text = data.text:gsub(patterns.player.p, patterns.player.r, 1)
  if data.typeInfo.channel and data.typeInfo.type ~= "CHANNEL" then
    data.text = data.text:gsub(patterns.channel.p, patterns.channel.r(data), 1)
  elseif data.typeInfo.type == "GUILD" and data.typeInfo.event == "CHAT_MSG_GUILD" then
    data.text = data.text:gsub(patterns.guild.p, patterns.guild.r, 1)
  elseif chatTypeToPatterns[data.typeInfo.type] then
    local p = patterns[chatTypeToPatterns[data.typeInfo.type]]
    data.text = data.text:gsub(p.p, p.r, 1)
  end
end

function addonTable.Modifiers.InitializeShortenChannels()
  local value = addonTable.Config.Get(addonTable.Config.Options.SHORTEN_FORMAT)
  if typeToPattern[value] then
    patterns  = typeToPattern[value]
    addonTable.Messages:AddLiveModifier(Shorten)
  end
  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.SHORTEN_FORMAT then
      addonTable.Messages:RemoveLiveModifier(Shorten)
      value = addonTable.Config.Get(addonTable.Config.Options.SHORTEN_FORMAT)
      if typeToPattern[value] then
        patterns = typeToPattern[value]
        addonTable.Messages:AddLiveModifier(Shorten)
      end
    end
  end)
end
