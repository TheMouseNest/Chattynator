---@class addonTableChatanator
local addonTable = select(2, ...)

ChatanatorHyperlinkHandler:SetScript("OnHyperlinkEnter", function(_, hyperlink)
  if hyperlink:match("battlepet:") or hyperlink:match("item:") then
    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_RIGHT")
    GameTooltip:SetHyperlink(hyperlink)
    GameTooltip:Show()
  end
end)

ChatanatorHyperlinkHandler:SetScript("OnHyperlinkLeave", function(_, hyperlink)
  GameTooltip:Hide()
end)

local ChatFrame = CreateFrame("Frame", nil, ChatanatorHyperlinkHandler)
addonTable.ChatFrame = ChatFrame
Mixin(ChatFrame, addonTable.ChatFrameMixin)
ChatFrame:SetScript("OnHyperlinkClick", function() print("frame") end)
ChatFrame:OnLoad()
ChatFrame:SetPoint("CENTER", UIParent)
ChatFrame:SetSize(600, 300)
ChatFrame:AddMessage("Testing: |cffffd000|Htrade:Player-1307-0AA53392:25229:755|h[Jewelcrafting]|h|r")
ChatFrame:AddMessage("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
ChatFrame:AddMessage("You receive loot: |cnIQ0:|Hitem:30821::::::::80:268:::::::::|h[Envenomed Scorpid Stinger]|h|r")
ChatFrame:AddMessage("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam convallis, nulla ac aliquet cursus, neque est tincidunt nunc, ac accumsan arcu lectus quis urna. Sed scelerisque dui tincidunt, aliquam tellus vulputate, tempor tortor. Sed ultrices mauris lacinia ex porttitor, ac laoreet lectus consequat. In vitae lorem vehicula elit consectetur ullamcorper. Donec tincidunt dui sed leo consequat tempor. Nulla sed purus at ante pharetra lobortis at id turpis. Duis accumsan erat sit amet magna rhoncus venenatis. Interdum et malesuada fames ac ante ipsum primis in faucibus. Maecenas non dui turpis. Aenean consequat erat neque, eu maximus tortor ornare eu. Nulla mollis tortor ligula, eget lacinia velit ornare quis.")
ChatFrame:AddMessage("Cras imperdiet, est vitae ullamcorper convallis, metus nisl eleifend tellus, id viverra neque eros non dui. Maecenas aliquam quam id quam lacinia vestibulum. Sed ac erat sapien. Ut auctor nisi sit amet orci ultricies, non hendrerit est volutpat. Pellentesque ullamcorper neque massa, non interdum justo suscipit in. Nunc aliquam, augue eget condimentum mattis, nulla turpis laoreet purus, ac hendrerit dolor enim sit amet nibh. Sed nec ante porta, venenatis quam a, egestas diam. Morbi ac tempus metus. Ut ullamcorper eleifend arcu nec commodo. Aliquam nec malesuada tellus. Nulla vel leo non sapien pellentesque vehicula. Vivamus eget pharetra risus. Vestibulum malesuada lectus dignissim felis gravida rutrum. Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
ChatFrame:AddMessage("Aenean vel nisl cursus dui dictum tincidunt vitae non diam. Duis mauris tellus, varius a bibendum eu, tempus eget diam. Nam non lobortis augue. Cras sodales blandit orci, nec volutpat lectus tristique eu. Vivamus id erat erat. Aliquam ipsum elit, condimentum id ornare vel, consequat eget turpis. Nunc hendrerit facilisis placerat. Donec sit amet enim at felis tempus euismod sit amet auctor neque. Mauris vel fermentum odio, et commodo turpis. Sed vel dolor suscipit, ultrices purus ut, bibendum nibh. Pellentesque massa dui, vulputate eget ante ut, egestas accumsan nisl. Integer viverra ultricies justo, sit amet varius purus tristique eu. Vivamus tristique odio a metus feugiat placerat. Cras scelerisque, ligula blandit fringilla mollis, elit ipsum lacinia velit, in pulvinar tellus augue a purus. Vestibulum nulla sapien, efficitur vel mi ac, porta auctor leo. Cras vehicula fermentum ex, sit amet dictum erat fringilla viverra.")
ChatFrame:AddMessage("Duis laoreet dolor et felis malesuada placerat. Donec rhoncus erat ultricies nulla posuere, ac blandit nunc sodales. Nulla aliquam quam vel turpis sodales euismod. Phasellus sagittis vulputate neque, quis efficitur elit. Fusce non erat sed sem rhoncus hendrerit. Nullam tempus, erat id fringilla posuere, dui magna luctus arcu, nec egestas nulla lorem non erat. In rutrum nisi elit, sit amet venenatis purus molestie id. Sed vel dignissim tortor. Duis eu quam a mauris tempor lacinia vulputate at quam. In quis diam vulputate, aliquet nulla id, facilisis mauris. Mauris orci enim, molestie molestie turpis quis, consectetur dapibus sapien.")
ChatFrame:AddMessage("Sed consectetur leo nunc, at euismod nisi semper at. Morbi vitae consectetur nisl. Mauris elementum augue ante, eget rutrum nibh suscipit a. Pellentesque consectetur purus eu tellus tincidunt semper. Integer lectus sem, lacinia quis odio id, finibus consectetur quam. Etiam a erat ut ante rutrum varius. Proin congue ac augue a feugiat. Proin ac elit dapibus, congue felis in, imperdiet leo. Cras sodales diam nec neque condimentum laoreet. Vestibulum elementum tellus odio, sit amet efficitur dui blandit id.")

ChatFrame:Show()

local resetButton = CreateFrame("Button", nil, ChatFrame, "UIPanelButtonTemplate")
resetButton:SetText("Reset")
resetButton:SetScript("OnClick", function()
  ChatFrame:SetFilter(nil)
  ChatFrame:Render()
end)
resetButton:Click()

local sayButton = CreateFrame("Button", nil, ChatFrame, "UIPanelButtonTemplate")
sayButton:SetText("Say")
sayButton:SetScript("OnClick", function()
  ChatFrame:SetFilter(function(data) return data.typeInfo.type == "CHAT_MSG_SAY" end)
  ChatFrame:Render()
end)

local guildButton = CreateFrame("Button", nil, ChatFrame, "UIPanelButtonTemplate")
guildButton:SetText("Guild")
guildButton:SetScript("OnClick", function()
  ChatFrame:SetFilter(function(data) return tIndexOf({"CHAT_MSG_GUILD", "GUILD_MOTD", "CHAT_MSG_OFFICER", "CHAT_MSG_GUILD_ACHIEVEMENT", "CHAT_MSG_GUILD_ITEM_LOOTED"}, data.typeInfo.type) ~= nil end)
  ChatFrame:Render()
end)

local systemButton = CreateFrame("Button", nil, ChatFrame, "UIPanelButtonTemplate")
systemButton:SetText("System")
systemButton:SetScript("OnClick", function()
  ChatFrame:SetFilter(function(data) return data.typeInfo.type == "RAW" and data.typeInfo.source == "SYSTEM" end)
  ChatFrame:Render()
end)

local tradeskillsButton = CreateFrame("Button", nil, ChatFrame, "UIPanelButtonTemplate")
tradeskillsButton:SetText("Tradeskills")
tradeskillsButton:SetScript("OnClick", function()
  ChatFrame:SetFilter(function(data) return data.typeInfo.type == "CHAT_MSG_TRADESKILLS" end)
  ChatFrame:Render()
end)

local addonButton = CreateFrame("Button", nil, ChatFrame, "UIPanelButtonTemplate")
addonButton:SetText("Addon")
addonButton:SetScript("OnClick", function()
  ChatFrame:SetFilter(function(data) return data.typeInfo.type == "RAW" and data.typeInfo.source == "ADDON" end)
  ChatFrame:Render()
end)

local buttons = { resetButton, sayButton, guildButton, systemButton, tradeskillsButton, addonButton}
local lastButton = nil
for _, b in ipairs(buttons) do
  if lastButton == nil then
    b:SetPoint("BOTTOMLEFT", ChatFrame, "TOPLEFT")
  else
    b:SetPoint("LEFT", lastButton, "RIGHT", 10, 0)
  end
  b:SetWidth(80)
  lastButton = b
end
