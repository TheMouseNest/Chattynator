---@class addonTableChatanator
local addonTable = select(2, ...)

addonTable.CustomiseDialog.Components = {}

function addonTable.CustomiseDialog.Components.GetCheckbox(parent, label, spacing, callback)
  spacing = spacing or 0
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetHeight(40)
  holder:SetPoint("LEFT", parent, "LEFT", 30, 0)
  holder:SetPoint("RIGHT", parent, "RIGHT", -15, 0)
  local checkBox = CreateFrame("CheckButton", nil, holder, "SettingsCheckboxTemplate")

  checkBox:SetPoint("LEFT", holder, "CENTER", -15 - spacing, 0)
  checkBox:SetText(label)
  checkBox:SetNormalFontObject(GameFontHighlight)
  checkBox:GetFontString():SetPoint("RIGHT", holder, "CENTER", -30 - spacing, 0)

  addonTable.Skins.AddFrame("CheckBox", checkBox)

  function holder:SetValue(value)
    checkBox:SetChecked(value)
  end

  holder:SetScript("OnEnter", function()
    checkBox:OnEnter()
  end)

  holder:SetScript("OnLeave", function()
    checkBox:OnLeave()
  end)

  holder:SetScript("OnMouseUp", function()
    checkBox:Click()
  end)

  checkBox:SetScript("OnClick", function()
    callback(checkBox:GetChecked())
  end)

  return holder
end

function addonTable.CustomiseDialog.Components.GetHeader(parent, text)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetPoint("LEFT", 30, 0)
  holder:SetPoint("RIGHT", -30, 0)
  holder.text = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  holder.text:SetText(text)
  holder.text:SetPoint("LEFT", 20, -1)
  holder.text:SetPoint("RIGHT", 20, -1)
  holder:SetHeight(40)
  return holder
end

function addonTable.CustomiseDialog.Components.GetTab(parent)
  local tab
  if addonTable.Constants.IsRetail then
    tab = CreateFrame("Button", nil, parent, "PanelTopTabButtonTemplate")
    tab:SetScript("OnShow", function(self)
      PanelTemplates_TabResize(self, 15, nil, 10)
      PanelTemplates_DeselectTab(self)
    end)
  else
    tab = CreateFrame("Button", nil, parent, "TabButtonTemplate")
    tab:SetScript("OnShow", function(self)
      PanelTemplates_TabResize(self, 0, nil, 0)
      PanelTemplates_DeselectTab(self)
    end)
  end
  addonTable.Skins.AddFrame("TopTabButton", tab)
  return tab
end
