---@class addonTableChattynator
local addonTable = select(2, ...)

local LibSharedMedia = LibStub("LibSharedMedia-3.0")

local fonts = {
  default = "ChatFontNormal",
}

function addonTable.Core.GetFontByID(id)
  if not fonts[id] then
    addonTable.Core.CreateFont(id)
  end
  return fonts[id] or fonts["default"]
end

function addonTable.Core.OverwriteDefaultFont(id)
  if not fonts[id] then
    addonTable.Core.CreateFont(id)
  end
  fonts["default"] = fonts[id] or fonts["default"]
  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.MessageFont] = true})
end

function addonTable.Core.GetFontScalingFactor()
  return addonTable.Config.Get(addonTable.Config.Options.MESSAGE_FONT_SIZE) / 14
end

function addonTable.Core.CreateFont(lsmPath)
  local key = lsmPath
  local globalName = "ChatanatorFont" .. key
  local path = LibSharedMedia:Fetch("font", lsmPath, true)
  if not path then
    return
  end
  local font = CreateFont(globalName)
  fonts[key] = globalName
  font:SetFont(path, 14, "")
  font:SetTextColor(1, 1, 1)
end
