---@class addonTableChattynator
local addonTable = select(2, ...)

local playerPattern = "(|Hplayer:[^|]+|h%[?)([^|%[%]][^c%[%]][^%[%]]-)(%]?|h)"
local function Color(data)
  if data.typeInfo.player and data.typeInfo.player.class then
    local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[data.typeInfo.player.class]
    local hex = CreateColor(color.r, color.g, color.b):GenerateHexColorMarkup()
    data.text = data.text:gsub(playerPattern, "%1" .. hex .. "%2|r%3")
  end
end

local function StripColor(data)
  if not data.typeInfo.player then
    return
  end
  data.text = data.text:gsub("(|Hplayer:.-|h[^|]-)|c[fF][fF]%x%x%x%x%x%x(.-)|r([^|]-|h)", "%1%2%3")
end

function addonTable.Modifiers.InitializeClassColors()
  if addonTable.Config.Get(addonTable.Config.Options.CLASS_COLORS) then
    addonTable.Messages:AddLiveModifier(Color)
  else
    addonTable.Messages:AddLiveModifier(StripColor)
  end
  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.CLASS_COLORS then
      if addonTable.Config.Get(addonTable.Config.Options.CLASS_COLORS) then
        addonTable.Messages:AddLiveModifier(Color)
        addonTable.Messages:RemoveLiveModifier(StripColor)
      else
        addonTable.Messages:RemoveLiveModifier(Color)
        addonTable.Messages:AddLiveModifier(StripColor)
      end
    end
  end)
end
