---@class addonTableChattynator
local addonTable = select(2, ...)

local channel = addonTable.Constants.ChannelIDs
local channelMapping = {
  [channel.General] = "W",
  [channel.Trade] = "T",
  [channel.LocalDefense] = "D",
  [channel.LookingForGroup] = "LFG",
  [channel.NewcomerChat] = "NC",
  [channel.Services] = "S",
}

local function Shorten(data)
  data.text = data.text:gsub("(|Hplayer:.-%|h)%[(.-)%](|h)", "%1%2%3")
  if data.typeInfo.channel and data.typeInfo.type ~= "CHANNEL" then
    data.text = data.text:gsub("^(%|Hchannel%:channel%:.-%|h)%[(.-)%](%|h)", function(linkStart, linkMid, linkEnd)
      return linkStart .. "[" .. (channelMapping[data.typeInfo.channel.zoneID] or data.typeInfo.channel.name) .. "." .. (data.typeInfo.channel.index or 0) .. "]" .. linkEnd
    end)
  elseif data.typeInfo.type == "GUILD" and data.typeInfo.event == "CHAT_MSG_GUILD" then
    data.text = data.text:gsub("(|Hchannel:GUILD|h)%[(.-)%](|h)", "%1[G]%3")
  end
end

function addonTable.Core.InitializeShortenChannels()
  if addonTable.Config.Get(addonTable.Config.Options.SHORTEN_CHANNEL_NAMES) then
    addonTable.Messages:AddLiveModifier(Shorten)
  end
  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.SHORTEN_CHANNEL_NAMES then
      if addonTable.Config.Get(addonTable.Config.Options.SHORTEN_CHANNEL_NAMES) then
        addonTable.Messages:AddLiveModifier(Shorten)
      else
        addonTable.Messages:RemoveLiveModifier(Shorten)
      end
    end
  end)
end
