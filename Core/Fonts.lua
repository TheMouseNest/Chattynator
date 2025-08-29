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

function addonTable.Core.GetFontByID(id)
  if not fonts[id .. GetOutlineKey()] then
    addonTable.Core.CreateFont(id, GetOutlineKey())
  end
  return fonts[id .. GetOutlineKey()] or fonts["default" .. GetOutlineKey()] or fonts["default"]
end

function addonTable.Core.OverwriteDefaultFont(id)
  if not fonts[id] then
    addonTable.Core.CreateFont(id, "")
  end

  fonts["default"] = fonts[id] or fonts["default"]
  -- Import outlines
  if fonts[id .. "OUTLINE"] then
    fonts["default" .. "OUTLINE"] = fonts[id .. "OUTLINE"]
  end
  if fonts[id .. "THICKOUTLINE"] then
    fonts["default" .. "THICKOUTLINE"] = fonts[id .. "THICKOUTLINE"]
  end

  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.MessageFont] = true})
end

function addonTable.Core.GetFontScalingFactor()
  return addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FONT_SIZE) / 14
end

function addonTable.Core.CreateFont(lsmPath, outline)
  if lsmPath == "default" then
    local alphabet = {"roman", "korean", "simplifiedchinese", "traditionalchinese", "russian"}
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
    local globalName = "ChattynatorFontdefault" .. outline
    CreateFontFamily(globalName, members)
    fonts["default" .. outline] = globalName
  else
    local key = lsmPath .. outline
    local globalName = "ChattynatorFont" .. key
    local path = LibSharedMedia:Fetch("font", lsmPath, true)
    if not path then
      return
    end
    local font = CreateFont(globalName)
    fonts[key] = globalName
    font:SetFont(path, 14, outline)
    font:SetTextColor(1, 1, 1)
  end
end

addonTable.Core.CreateFont("default", "") -- Clone the ChatFontNormal to avoid sizing issues
