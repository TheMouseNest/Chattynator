---@class addonTableChattynator
local addonTable = select(2, ...)

local channelMapping = {
  ["General"] = "W",
  ["Trade"] = "T",
  ["LocalDefense"] = "D",
  ["LookingForGroup"] = "LFG",
  ["NewcomerChat"] = "NC",
  ["Services"] = "S",
}

function addonTable.Core.InitializeShortenChannels()
  addonTable.Messages:AddLiveModifier(function(data)
    data.text = data.text:gsub("(|Hplayer:.-%|h)%[(.-)%](|h)", "%1%2%3")
    if data.typeInfo.channel and data.typeInfo.type ~= "CHANNEL" then
      data.text = data.text:gsub("^(%|Hchannel%:channel%:.-%|h)%[(.-)%](%|h)", function(linkStart, linkMid, linkEnd)
        return linkStart .. "[" .. (channelMapping[data.typeInfo.channel.name] or data.typeInfo.channel.name) .. "]" .. linkEnd
      end)
    elseif data.typeInfo.type == "GUILD" and data.typeInfo.event == "CHAT_MSG_GUILD" then
      data.text = data.text:gsub("(|Hchannel:GUILD|h)%[(.-)%](|h)", "%1[G]%3")
    end
    return data
  end)
end
