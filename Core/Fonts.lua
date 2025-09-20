---@class addonTableChattynator
local addonTable = select(2, ...)

local LibSharedMedia = LibStub("LibSharedMedia-3.0")

local fonts = {
  default = "ChatFontNormal",
}

local function GetOutlineKey()
  local outline = addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FONT_OUTLINE)
  if outline == "thin" then
    return "OUTLINE"
  elseif outline == "thick" then
    return "THICKOUTLINE"
  else
    return ""
  end
end

local function GetShadowKey()
  local shadow = addonTable.Config.Get(addonTable.Config.Options.SHOW_FONT_SHADOW)
  if shadow then
    return "SHADOW"
  else
    return ""
  end
end

function addonTable.Core.GetFontByID(id)
  if not fonts[id .. GetOutlineKey() .. GetShadowKey()] then
    addonTable.Core.CreateFont(id, GetOutlineKey(), GetShadowKey())
  end
  return fonts[id .. GetOutlineKey() .. GetShadowKey()] or fonts["default" .. GetOutlineKey() .. GetShadowKey()] or fonts["default"]
end

local modes = {
  {"", ""},
  {"", "SHADOW"},
  {"OUTLINE", ""},
  {"OUTLINE", "SHADOW"},
  {"THICKOUTLINE", ""},
  {"THICKOUTLINE", "SHADOW"},
}

function addonTable.Core.OverwriteDefaultFont(id)
  for _, m in ipairs(modes) do
    local key = m[1] .. m[2]
    if not fonts[id .. key] and fonts["default" .. key] then
      addonTable.Core.CreateFont(id, m[1], m[2])
    end
    fonts["default" .. key] = fonts[id .. key] or fonts["default" .. key]
  end

  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.MessageFont] = true})
end

function addonTable.Core.GetFontScalingFactor()
  return addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FONT_SIZE) / 14
end

local alphabet = {"roman", "korean", "simplifiedchinese", "traditionalchinese", "russian"}

local function GetDefaultMembers(outline)
  local members = {}
  local coreFont = _G[fonts["default"]]
  for _, a in ipairs(alphabet) do
    local forAlphabet = coreFont:GetFontObjectForAlphabet(a)
    if forAlphabet then
      local file, height, flags = forAlphabet:GetFont()
      table.insert(members, {
        alphabet = a,
        file = file,
        height = height,
        flags = outline,
      })
    end
  end

  return members
end

function addonTable.Core.CreateFont(lsmPath, outline, shadow, force)
  local key = lsmPath .. outline .. shadow
  if fonts[key] and not force then
    error("duplicate font creation " .. key)
  end
  local globalName = "ChattynatorFont" .. key
  local lowerGlobal = globalName:lower()

  --Protection against different lsmPaths with different capitalisation clashing when trying to make a font family
  local val = FindValueInTableIf(GetFonts(), function(a) return a:lower() == lowerGlobal:lower() end)
  if val then
    fonts[key] = val
    return
  end
  if lsmPath == "default" then
    CreateFontFamily(globalName, GetDefaultMembers(outline))
  else
    local path = LibSharedMedia:Fetch("font", lsmPath, true)
    if not path then
      return
    end

    local font = CreateFontFamily(globalName, GetDefaultMembers(outline))
    font:SetFont(path, 14, outline)
    font:SetTextColor(1, 1, 1)
  end

  fonts[key] = globalName

  local fontFamily = _G[globalName]

  if shadow == "SHADOW" then
    for _, a in ipairs(alphabet) do
      local font = fontFamily:GetFontObjectForAlphabet(a)
      font:SetShadowOffset(1, -1)
      font:SetShadowColor(0, 0, 0, 0.8)
    end
  end
end

addonTable.Core.CreateFont("default", "", "", true) -- Clone the ChatFontNormal to avoid sizing issues
