---@class addonTableChattynator
local addonTable = select(2, ...)
addonTable.ProfileExport = {}

-----------------------------------------------------------------------
-- Base64
-----------------------------------------------------------------------
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Base64Encode(data)
  local out = {}
  local len = #data
  for i = 1, len, 3 do
    local a = string.byte(data, i)
    local b = i + 1 <= len and string.byte(data, i + 1) or 0
    local c = i + 2 <= len and string.byte(data, i + 2) or 0
    local n = a * 65536 + b * 256 + c
    out[#out + 1] = string.sub(b64chars, math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
    out[#out + 1] = string.sub(b64chars, math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
    out[#out + 1] = (i + 1 <= len) and string.sub(b64chars, math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1) or "="
    out[#out + 1] = (i + 2 <= len) and string.sub(b64chars, n % 64 + 1, n % 64 + 1) or "="
  end
  return table.concat(out)
end

local b64lookup = {}
for i = 1, 64 do
  b64lookup[string.byte(b64chars, i)] = i - 1
end

local function Base64Decode(data)
  data = data:gsub("[%s]", "")
  local out = {}
  local len = #data
  for i = 1, len, 4 do
    local c1 = b64lookup[string.byte(data, i)] or 0
    local c2 = b64lookup[string.byte(data, i + 1)] or 0
    local c3 = b64lookup[string.byte(data, i + 2)]
    local c4 = b64lookup[string.byte(data, i + 3)]
    local n = c1 * 262144 + c2 * 4096 + (c3 or 0) * 64 + (c4 or 0)
    out[#out + 1] = string.char(math.floor(n / 65536) % 256)
    if c3 then out[#out + 1] = string.char(math.floor(n / 256) % 256) end
    if c4 then out[#out + 1] = string.char(n % 256) end
  end
  return table.concat(out)
end

-----------------------------------------------------------------------
-- Table serializer (safe subset: tables, strings, numbers, booleans)
-----------------------------------------------------------------------
local function SerializeValue(val, depth)
  depth = depth or 0
  if depth > 50 then return "nil" end
  local t = type(val)
  if t == "string" then
    return string.format("%q", val)
  elseif t == "number" then
    if val == math.floor(val) and val >= -2^53 and val <= 2^53 then
      return tostring(val)
    end
    return string.format("%.17g", val)
  elseif t == "boolean" then
    return val and "true" or "false"
  elseif t == "table" then
    local parts = {}
    local arrayLen = #val
    local arrayKeys = {}
    for i = 1, arrayLen do
      arrayKeys[i] = true
      parts[#parts + 1] = SerializeValue(val[i], depth + 1)
    end
    for k, v in pairs(val) do
      if not arrayKeys[k] then
        local keyStr
        if type(k) == "string" then
          keyStr = k:match("^[%a_][%w_]*$") and k or ("[" .. string.format("%q", k) .. "]")
        elseif type(k) == "number" then
          keyStr = "[" .. tostring(k) .. "]"
        elseif type(k) == "boolean" then
          keyStr = "[" .. tostring(k) .. "]"
        end
        if keyStr then
          parts[#parts + 1] = keyStr .. "=" .. SerializeValue(v, depth + 1)
        end
      end
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "nil"
end

local function DeserializeData(str)
  local func, err = loadstring("return " .. str)
  if not func then
    return nil, "Parse error: " .. (err or "unknown")
  end
  setfenv(func, {})
  local ok, result = pcall(func)
  if not ok then
    return nil, "Load error: " .. tostring(result)
  end
  if type(result) ~= "table" then
    return nil, "Expected table, got " .. type(result)
  end
  return result
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------
local EXPORT_PREFIX = "!CTNRP1!"

function addonTable.ProfileExport.Encode(tbl)
  return EXPORT_PREFIX .. Base64Encode(SerializeValue(tbl))
end

function addonTable.ProfileExport.Decode(str)
  str = str:gsub("^%s+", ""):gsub("%s+$", "")
  if str:sub(1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then
    return nil, "Invalid export string (missing header)"
  end
  local decoded = Base64Decode(str:sub(#EXPORT_PREFIX + 1))
  if not decoded or decoded == "" then
    return nil, "Base64 decode failed"
  end
  return DeserializeData(decoded)
end

-----------------------------------------------------------------------
-- Export/Import dialog (shared frame, reused for both modes)
-----------------------------------------------------------------------
local dialogFrame

local function GetDialog()
  if dialogFrame then return dialogFrame end

  local f = CreateFrame("Frame", "ChattynatorProfileExportDialog", UIParent, "ButtonFrameTemplate")
  f:SetSize(600, 450)
  f:SetPoint("CENTER")
  f:SetToplevel(true)
  f:SetFrameStrata("DIALOG")
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  table.insert(UISpecialFrames, "ChattynatorProfileExportDialog")

  ButtonFrameTemplate_HidePortrait(f)
  ButtonFrameTemplate_HideButtonBar(f)
  if f.Inset then f.Inset:Hide() end

  f.TitleText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  f.TitleText:SetPoint("TOP", 0, -6)

  f.ScrollBox = CreateFrame("Frame", nil, f, "ScrollingEditBoxTemplate")
  f.ScrollBox:SetPoint("TOPLEFT", 15, -35)
  f.ScrollBox:SetPoint("BOTTOMRIGHT", -15, 80)
  local editBox = f.ScrollBox:GetEditBox()
  editBox:SetAutoFocus(false)
  editBox:SetFontObject(ChatFontNormal)
  editBox:SetMaxLetters(0)

  -- Name input row (import only)
  f.NameRow = CreateFrame("Frame", nil, f)
  f.NameRow:SetPoint("BOTTOMLEFT", 15, 45)
  f.NameRow:SetPoint("BOTTOMRIGHT", -15, 45)
  f.NameRow:SetHeight(28)

  f.NameLabel = f.NameRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.NameLabel:SetPoint("LEFT")
  f.NameLabel:SetText(addonTable.Locales.PROFILE_NAME or "Profile name:")

  f.NameEditBox = CreateFrame("EditBox", nil, f.NameRow, "InputBoxTemplate")
  f.NameEditBox:SetAutoFocus(false)
  f.NameEditBox:SetSize(250, 24)
  f.NameEditBox:SetPoint("LEFT", f.NameLabel, "RIGHT", 8, 0)
  f.NameEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  f.NameRow:Hide()

  -- Buttons
  f.CloseBtn = CreateFrame("Button", nil, f, "UIPanelDynamicResizeButtonTemplate")
  f.CloseBtn:SetText(CLOSE)
  DynamicResizeButton_Resize(f.CloseBtn)
  f.CloseBtn:SetPoint("BOTTOMRIGHT", -15, 12)
  f.CloseBtn:SetScript("OnClick", function() f:Hide() end)

  f.ActionBtn = CreateFrame("Button", nil, f, "UIPanelDynamicResizeButtonTemplate")
  f.ActionBtn:SetPoint("BOTTOMRIGHT", f.CloseBtn, "BOTTOMLEFT", -8, 0)

  f.InfoLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.InfoLabel:SetPoint("BOTTOMLEFT", 15, 18)
  f.InfoLabel:SetJustifyH("LEFT")

  addonTable.Skins.AddFrame("ButtonFrame", f, {"profileExport"})

  dialogFrame = f
  return f
end

-----------------------------------------------------------------------
-- Export current profile
-----------------------------------------------------------------------
function addonTable.ProfileExport.ShowExport()
  local profileName = CHATTYNATOR_CURRENT_PROFILE or "DEFAULT"
  local profileData = CHATTYNATOR_CONFIG and CHATTYNATOR_CONFIG.Profiles and CHATTYNATOR_CONFIG.Profiles[profileName]
  if not profileData then
    addonTable.Utilities.Message("|cffff4444" .. (addonTable.Locales.PROFILE_NOT_FOUND or "Profile not found.") .. "|r")
    return
  end

  local payload = {
    _v = 1,
    _profile = profileName,
    _date = date("%Y-%m-%d %H:%M:%S"),
    _char = UnitName("player") .. "-" .. GetRealmName(),
    data = profileData,
  }

  local exportString = addonTable.ProfileExport.Encode(payload)
  if not exportString then
    addonTable.Utilities.Message("|cffff4444" .. (addonTable.Locales.EXPORT_FAILED or "Export failed.") .. "|r")
    return
  end

  local dialog = GetDialog()
  dialog.TitleText:SetText((addonTable.Locales.EXPORT_PROFILE or "Export Profile") .. ": |cff00ccff" .. profileName .. "|r")
  dialog.InfoLabel:SetText("|cff00ccff" .. #exportString .. "|r " .. (addonTable.Locales.CHARACTERS or "characters"))
  dialog.InfoLabel:Show()
  dialog.NameRow:Hide()
  dialog.ScrollBox:SetPoint("BOTTOMRIGHT", -15, 50)
  dialog.ScrollBox:SetText(exportString)

  local eb = dialog.ScrollBox:GetEditBox()
  dialog.ActionBtn:SetText(addonTable.Locales.SELECT_ALL or "Select All")
  DynamicResizeButton_Resize(dialog.ActionBtn)
  dialog.ActionBtn:SetScript("OnClick", function()
    eb:SetFocus()
    eb:HighlightText(0, #eb:GetText())
  end)

  dialog:Show()
  C_Timer.After(0.05, function()
    eb:SetFocus()
    eb:HighlightText(0, #eb:GetText())
  end)
end

-----------------------------------------------------------------------
-- Import profile (two-step: validate → name → apply)
-----------------------------------------------------------------------
local function ApplyImport(importData, targetName)
  if not CHATTYNATOR_CONFIG or not CHATTYNATOR_CONFIG.Profiles then return false end

  local finalName = targetName
  if CHATTYNATOR_CONFIG.Profiles[finalName] then
    local i = 1
    local base = finalName
    while CHATTYNATOR_CONFIG.Profiles[finalName] do
      finalName = base .. " (" .. i .. ")"
      i = i + 1
    end
  end

  CHATTYNATOR_CONFIG.Profiles[finalName] = importData
  addonTable.Utilities.Message("|cff44ff44" .. (addonTable.Locales.PROFILE_IMPORTED or "Profile imported:") .. "|r " .. finalName)
  return true
end

function addonTable.ProfileExport.ShowImport()
  local dialog = GetDialog()
  dialog.TitleText:SetText(addonTable.Locales.IMPORT_PROFILE or "Import Profile")
  dialog.InfoLabel:SetText("|cff00ccff" .. (addonTable.Locales.PASTE_AND_VALIDATE or "Paste the export string, then click Validate.") .. "|r")
  dialog.InfoLabel:Show()
  dialog.NameRow:Hide()
  dialog.ScrollBox:SetPoint("BOTTOMRIGHT", -15, 50)
  dialog.ScrollBox:SetText("")

  local eb = dialog.ScrollBox:GetEditBox()

  dialog.ActionBtn:SetText(addonTable.Locales.VALIDATE or "Validate")
  DynamicResizeButton_Resize(dialog.ActionBtn)
  dialog.ActionBtn:SetScript("OnClick", function()
    local text = eb:GetText()
    if not text or text == "" then
      addonTable.Utilities.Message("|cffff4444" .. (addonTable.Locales.NOTHING_TO_IMPORT or "Nothing to import.") .. "|r")
      return
    end

    local payload, err = addonTable.ProfileExport.Decode(text)
    if not payload then
      addonTable.Utilities.Message("|cffff4444" .. (err or "Decode failed.") .. "|r")
      return
    end
    if not payload.data or type(payload.data) ~= "table" then
      addonTable.Utilities.Message("|cffff4444" .. (addonTable.Locales.INVALID_PROFILE_DATA or "Invalid profile data.") .. "|r")
      return
    end

    local sourceName = payload._profile or "Imported"
    local sourceChar = payload._char or "?"
    local sourceDate = payload._date or "?"

    -- Step 2: name input
    dialog.TitleText:SetText(addonTable.Locales.IMPORT_PROFILE or "Import Profile")
    dialog.InfoLabel:SetText((addonTable.Locales.FROM or "From") .. ": |cff00ccff" .. sourceChar .. "|r  " .. sourceDate)
    dialog.NameRow:Show()
    dialog.NameEditBox:SetText(sourceName)
    dialog.NameEditBox:SetFocus()
    dialog.NameEditBox:HighlightText()
    dialog.ScrollBox:SetPoint("BOTTOMRIGHT", -15, 80)
    eb:ClearFocus()

    dialog.ActionBtn:SetText(addonTable.Locales.IMPORT or "Import")
    DynamicResizeButton_Resize(dialog.ActionBtn)
    dialog.ActionBtn:SetScript("OnClick", function()
      local name = dialog.NameEditBox:GetText():gsub("^%s+", ""):gsub("%s+$", "")
      if name == "" then
        addonTable.Utilities.Message("|cffff4444" .. (addonTable.Locales.ENTER_PROFILE_NAME or "Enter a profile name.") .. "|r")
        return
      end
      if ApplyImport(payload.data, name) then
        dialog:Hide()
      end
    end)
    dialog.NameEditBox:SetScript("OnEnterPressed", function(self)
      self:ClearFocus()
      dialog.ActionBtn:Click()
    end)
  end)

  dialog:Show()
  C_Timer.After(0.05, function() eb:SetFocus() end)
end
