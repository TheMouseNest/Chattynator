---@class addonTableChatanator
local addonTable = select(2, ...)

local ChatFrame = CreateFrame("Frame", nil, ChatanatorHyperlinkHandler)
Mixin(ChatFrame, addonTable.ChatFrameMixin)
ChatFrame:SetScript("OnHyperlinkClick", function() print("frame") end)
ChatFrame:OnLoad()
ChatFrame:SetPoint("CENTER", UIParent)
ChatFrame:SetSize(500, 500)
ChatFrame:AddMessage("Testing: |cffffd000|Htrade:Player-1307-0AA53392:25229:755|h[Jewelcrafting]|h|r")
ChatFrame:AddMessage("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", r, g, b, id)
ChatFrame:AddMessage("You receive loot: |cnIQ0:|Hitem:30821::::::::80:268:::::::::|h[Envenomed Scorpid Stinger]|h|r")
ChatFrame:AddMessage("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam convallis, nulla ac aliquet cursus, neque est tincidunt nunc, ac accumsan arcu lectus quis urna. Sed scelerisque dui tincidunt, aliquam tellus vulputate, tempor tortor. Sed ultrices mauris lacinia ex porttitor, ac laoreet lectus consequat. In vitae lorem vehicula elit consectetur ullamcorper. Donec tincidunt dui sed leo consequat tempor. Nulla sed purus at ante pharetra lobortis at id turpis. Duis accumsan erat sit amet magna rhoncus venenatis. Interdum et malesuada fames ac ante ipsum primis in faucibus. Maecenas non dui turpis. Aenean consequat erat neque, eu maximus tortor ornare eu. Nulla mollis tortor ligula, eget lacinia velit ornare quis.")
ChatFrame:AddMessage("Cras imperdiet, est vitae ullamcorper convallis, metus nisl eleifend tellus, id viverra neque eros non dui. Maecenas aliquam quam id quam lacinia vestibulum. Sed ac erat sapien. Ut auctor nisi sit amet orci ultricies, non hendrerit est volutpat. Pellentesque ullamcorper neque massa, non interdum justo suscipit in. Nunc aliquam, augue eget condimentum mattis, nulla turpis laoreet purus, ac hendrerit dolor enim sit amet nibh. Sed nec ante porta, venenatis quam a, egestas diam. Morbi ac tempus metus. Ut ullamcorper eleifend arcu nec commodo. Aliquam nec malesuada tellus. Nulla vel leo non sapien pellentesque vehicula. Vivamus eget pharetra risus. Vestibulum malesuada lectus dignissim felis gravida rutrum. Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
ChatFrame:AddMessage("Aenean vel nisl cursus dui dictum tincidunt vitae non diam. Duis mauris tellus, varius a bibendum eu, tempus eget diam. Nam non lobortis augue. Cras sodales blandit orci, nec volutpat lectus tristique eu. Vivamus id erat erat. Aliquam ipsum elit, condimentum id ornare vel, consequat eget turpis. Nunc hendrerit facilisis placerat. Donec sit amet enim at felis tempus euismod sit amet auctor neque. Mauris vel fermentum odio, et commodo turpis. Sed vel dolor suscipit, ultrices purus ut, bibendum nibh. Pellentesque massa dui, vulputate eget ante ut, egestas accumsan nisl. Integer viverra ultricies justo, sit amet varius purus tristique eu. Vivamus tristique odio a metus feugiat placerat. Cras scelerisque, ligula blandit fringilla mollis, elit ipsum lacinia velit, in pulvinar tellus augue a purus. Vestibulum nulla sapien, efficitur vel mi ac, porta auctor leo. Cras vehicula fermentum ex, sit amet dictum erat fringilla viverra.")
ChatFrame:AddMessage("Duis laoreet dolor et felis malesuada placerat. Donec rhoncus erat ultricies nulla posuere, ac blandit nunc sodales. Nulla aliquam quam vel turpis sodales euismod. Phasellus sagittis vulputate neque, quis efficitur elit. Fusce non erat sed sem rhoncus hendrerit. Nullam tempus, erat id fringilla posuere, dui magna luctus arcu, nec egestas nulla lorem non erat. In rutrum nisi elit, sit amet venenatis purus molestie id. Sed vel dignissim tortor. Duis eu quam a mauris tempor lacinia vulputate at quam. In quis diam vulputate, aliquet nulla id, facilisis mauris. Mauris orci enim, molestie molestie turpis quis, consectetur dapibus sapien.")
ChatFrame:AddMessage("Sed consectetur leo nunc, at euismod nisi semper at. Morbi vitae consectetur nisl. Mauris elementum augue ante, eget rutrum nibh suscipit a. Pellentesque consectetur purus eu tellus tincidunt semper. Integer lectus sem, lacinia quis odio id, finibus consectetur quam. Etiam a erat ut ante rutrum varius. Proin congue ac augue a feugiat. Proin ac elit dapibus, congue felis in, imperdiet leo. Cras sodales diam nec neque condimentum laoreet. Vestibulum elementum tellus odio, sit amet efficitur dui blandit id.")

ChatFrame:Show()

ChatFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
ChatFrame:RegisterEvent("SETTINGS_LOADED");
--ChatFrame:RegisterEvent("UPDATE_CHAT_COLOR");
--ChatFrame:RegisterEvent("UPDATE_CHAT_WINDOWS");
ChatFrame:RegisterEvent("CHAT_MSG_CHANNEL");
ChatFrame:RegisterEvent("CHAT_MSG_COMMUNITIES_CHANNEL");
ChatFrame:RegisterEvent("CLUB_REMOVED");
ChatFrame:RegisterEvent("UPDATE_INSTANCE_INFO");
--ChatFrame:RegisterEvent("UPDATE_CHAT_COLOR_NAME_BY_CLASS");
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

ChatFrame:SetScript("OnEvent", ChatFrame_OnEvent)
