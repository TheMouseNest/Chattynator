--[[
    ChatLinkIcons integration.
    You can turn off each individual icon type off in in ChatLinkIcons options.

    Thanks to SDPhantom for making API functions!
]]
EventUtil.ContinueOnAddOnLoaded("ChatLinkIcons", function()
    local ConvertLinks = ChatLinkIcons.ConvertLinks
    Chattynator.API.AddModifier(function(data) 
        data.text = ConvertLinks(data.text) 
    end)
end)