-- Only the patterns (c) tannerng
local patterns = {
  -- X://Y most urls
  "%f[%S](%a[%w+.-]+://%S+)",
  -- www.X.Y domain and path
  "%f[%S](www%.[-%w_%%]+%.(%a%a+)/%S+)",
  -- www.X.Y domain
  "%f[%S](www%.[-%w_%%]+%.(%a%a+))",
}

---@class addonTableChattynator
local addonTable = select(2, ...)

local substitution = "|cff149bfd|Haddon:chattynatorurllink:%1|h[%1]|h|r"
local function URLs(data)
  if data.text:find("%swww%.") or data.text:find("://") then
    data.text = data.text:gsub(patterns[1], substitution)
    data.text = data.text:gsub(patterns[2], substitution)
    data.text = data.text:gsub(patterns[3], substitution)
  end
end

function addonTable.Modifiers.InitializeURLs()
  if addonTable.Config.Get(addonTable.Config.Options.LINK_URLS) then
    addonTable.Messages:AddLiveModifier(URLs)
  else
    addonTable.Messages:RemoveLiveModifier(URLs)
  end
  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.LINK_URLS then
      if addonTable.Config.Get(addonTable.Config.Options.LINK_URLS) then
        addonTable.Messages:AddLiveModifier(URLs)
      else
        addonTable.Messages:RemoveLiveModifier(URLs)
      end
    end
  end)
end

local urlDialog = "Chattynator_URL_Dialog"
StaticPopupDialogs[urlDialog] = {
  text = addonTable.Locales.CTRL_C_TO_COPY,
  button1 = DONE,
  hasEditBox = 1,
  OnShow = function(self, data)
    self.editBox:SetText(data)
    self.editBox:HighlightText()
  end,
  EditBoxOnEnterPressed = function(self)
    self:GetParent():Hide()
  end,
  EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
  editBoxWidth = 230,
  maxLetters = 0,
  timeout = 0,
  hideOnEscape = 1,
}

EventRegistry:RegisterCallback("SetItemRef", function(_, link)
  local url = link:match("^addon:chattynatorurllink:(.*)")
  if url then
    StaticPopup_Show(urlDialog, nil, nil, url)
  end
end)
