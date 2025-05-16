local ChatFrame = CreateFrame("ScrollingMessageFrame", "MyTestChatFrame", UIParent, "MyTestChatFrameTemplate")
ChatFrame:SetPoint("CENTER")
ChatFrame:SetSize(500, 500)
ChatFrame:AddMessage("Testing: |cffffd000|Htrade:Player-0-0:25229:755|h[Jewelcrafting]|h|r")
ChatFrame:AddMessage("You receive loot: |cnIQ0:|Hitem:30821::::::::80:268:::::::::|h[Envenomed Scorpid Stinger]|h|r")
ChatFrame:SetFontObject(ChatFontNormal)
ChatFrame:Show()
ScrollUtil.InitScrollingMessageFrameWithScrollBar(ChatFrame, ChatFrame.ScrollBar, false)
ChatFrame:SetHyperlinksEnabled(true)
ChatFrame:SetJustifyH("LEFT")

ChatFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
ChatFrame:RegisterEvent("SETTINGS_LOADED");
ChatFrame:RegisterEvent("UPDATE_CHAT_COLOR");
--ChatFrame:RegisterEvent("UPDATE_CHAT_WINDOWS");
ChatFrame:RegisterEvent("CHAT_MSG_CHANNEL");
ChatFrame:RegisterEvent("CHAT_MSG_COMMUNITIES_CHANNEL");
ChatFrame:RegisterEvent("CLUB_REMOVED");
ChatFrame:RegisterEvent("UPDATE_INSTANCE_INFO");
ChatFrame:RegisterEvent("UPDATE_CHAT_COLOR_NAME_BY_CLASS");
ChatFrame:RegisterEvent("CHAT_SERVER_DISCONNECTED");
ChatFrame:RegisterEvent("CHAT_SERVER_RECONNECTED");
ChatFrame:RegisterEvent("BN_CONNECTED");
ChatFrame:RegisterEvent("BN_DISCONNECTED");
ChatFrame:RegisterEvent("PLAYER_REPORT_SUBMITTED");
ChatFrame:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT");
ChatFrame:RegisterEvent("ALTERNATIVE_DEFAULT_LANGUAGE_CHANGED");
ChatFrame:RegisterEvent("NEWCOMER_GRADUATION");
ChatFrame:RegisterEvent("CHAT_REGIONAL_STATUS_CHANGED");
ChatFrame:RegisterEvent("CHAT_REGIONAL_SEND_FAILED");
ChatFrame:RegisterEvent("NOTIFY_CHAT_SUPPRESSED");

for type, values in pairs(ChatTypeGroup) do
  for _, event in ipairs(values) do
    ChatFrame:RegisterEvent(event)
  end
end
