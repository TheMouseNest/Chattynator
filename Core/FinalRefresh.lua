---@class addonTableChattynator
local addonTable = select(2, ...)

EventFrame_FinalRefresh = CreateFrame("Frame")
EventFrame_FinalRefresh:RegisterEvent("ADDON_LOADED")
EventFrame_FinalRefresh:SetScript("OnEvent", function(self, event)
    addonTable.Constants.TabPadding = addonTable.Config.Get(addonTable.Config.Options.TABSIZE_PADDING)
    addonTable.Constants.TabSpacing = addonTable.Config.Get(addonTable.Config.Options.TABSIZE_SPACING)
    addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
EventFrame_FinalRefresh:UnregisterEvent("ADDON_LOADED")
end)
