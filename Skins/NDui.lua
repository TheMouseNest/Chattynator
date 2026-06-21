---@class addonTableChattynator
local addonTable = select(2, ...)

local enableHooks = true

local intensity = 1
local hoverColor = { r = 1, g = 0.82, b = 0 }
local flashTabColor = { r = 247 / 255, g = 222 / 255, b = 61 / 255 }

local B, C, L, DB
local cr, cg, cb

local function ConvertTags(tags)
    local res = {}
    for _, tag in ipairs(tags) do
        res[tag] = true
    end
    return res
end

local toUpdate = {}

local UIScaleMonitor = CreateFrame("Frame")
UIScaleMonitor:RegisterEvent("UI_SCALE_CHANGED")
UIScaleMonitor:SetScript("OnEvent", function()
    for _, func in ipairs(toUpdate) do
        func()
    end
end)

local chatTabs = {}
local chatFrames = {}
local editBoxes = {}
local chatButtons = {}

local function CreateNDuiBackdrop(frame, alpha)
    if not frame.bg then
        frame.bg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.bg:SetOutside(frame)
        frame.bg:SetFrameLevel(frame:GetFrameLevel() - 1)
    end

    local bdTex = DB and DB.bdTex or "Interface\\ChatFrame\\ChatFrameBackground"
    local bgTex = DB and DB.bgTex

    frame.bg:SetBackdrop({
        bgFile = bdTex,
        edgeFile = bdTex,
        edgeSize = 1
    })

    frame.bg:SetBackdropColor(0, 0, 0, alpha or 0.5)
    frame.bg:SetBackdropBorderColor(0, 0, 0)

    if bgTex then
        if not frame.bg.texture then
            frame.bg.texture = frame.bg:CreateTexture(nil, "BACKGROUND", nil, 1)
            frame.bg.texture:SetAllPoints(frame.bg)
            frame.bg.texture:SetTexture(bgTex, true, true)
            frame.bg.texture:SetHorizTile(true)
            frame.bg.texture:SetVertTile(true)
            frame.bg.texture:SetBlendMode("ADD")
        end
        frame.bg.texture:Show()
    end

    return frame.bg
end

local function StripTextures(frame)
    for i = 1, frame:GetNumRegions() do
        local region = select(i, frame:GetRegions())
        if region:IsObjectType("Texture") then
            region:SetTexture(nil)
        end
    end
end

local skinners = {
    ChatButton = function(button, tags)
        table.insert(chatButtons, button)

        button:SetSize(26, 28)
        button:ClearNormalTexture()
        button:ClearPushedTexture()
        button:ClearHighlightTexture()

        local alpha = addonTable.Config.Get("skins.ndui.chat_transparency") or 0.5
        button.nduiBg = CreateNDuiBackdrop(button, alpha)

        if tags.toasts then
            button.Icon = button.FriendsButton or button:CreateTexture(nil, "ARTWORK")
            button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/ChatSocial.png")
            button.Icon:SetVertexColor(intensity, intensity, intensity)
            button.Icon:SetDrawLayer("ARTWORK")
            button.Icon:SetSize(12, 12)
            button.Icon:ClearAllPoints()
            button.Icon:SetPoint("TOP", 0, -2)
            local countText = button.FriendCount or FriendsMicroButtonCount
            countText:SetTextColor(intensity, intensity, intensity)

            button:HookScript("OnEnter", function()
                if not enableHooks then return end
                button.Icon:SetVertexColor(hoverColor.r, hoverColor.g, hoverColor.b)
                countText:SetTextColor(hoverColor.r, hoverColor.g, hoverColor.b)
                if button.nduiBg then
                    button.nduiBg:SetBackdropColor(cr or 1, cg or 1, cb or 1, 0.25)
                end
            end)
            button:HookScript("OnLeave", function()
                if not enableHooks then return end
                button.Icon:SetVertexColor(intensity, intensity, intensity)
                countText:SetTextColor(intensity, intensity, intensity)
                if button.nduiBg then
                    local alpha = addonTable.Config.Get("skins.ndui.chat_transparency") or 0.5
                    button.nduiBg:SetBackdropColor(0, 0, 0, alpha)
                end
            end)
        elseif tags.channels then
            hooksecurefunc(button, "SetIconToState", function(self, state)
                if not enableHooks then return end
                button:ClearNormalTexture()
                button:ClearPushedTexture()
                button:ClearHighlightTexture()

                if state then
                    button.Icon:SetTexture("Interface/Addons/Chattynator/Assets/ChatChannelsVC.png")
                    button.Icon:SetVertexColor(33 / 255, 209 / 255, 45 / 255)
                else
                    button.Icon:SetTexture("Interface/Addons/Chattynator/Assets/ChatChannels.png")
                    button.Icon:SetVertexColor(intensity, intensity, intensity)
                end

                if button:IsMouseOver() then
                    button:GetScript("OnEnter")(button)
                end
            end)
            button:HookScript("OnLeave", function()
                if not enableHooks then return end
                button:UpdateVisibleState()
            end)
            button:UpdateVisibleState()
        elseif tags.voiceChatNoAudio or tags.voiceChatMuteMic then
            hooksecurefunc(button, "SetIconToState", function(self, state)
                if not enableHooks then return end
                button:ClearNormalTexture()
                button:ClearHighlightTexture()
                button:ClearPushedTexture()
                button.Icon:ClearAllPoints()
                button.Icon:SetPoint("CENTER")
            end)
        elseif tags.menu then
            button.Icon = button:CreateTexture(nil, "ARTWORK")
            button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/ChatMenu.png")
            button.Icon:SetVertexColor(intensity, intensity, intensity)
            button.Icon:SetPoint("CENTER")
            button.Icon:SetSize(15, 15)
        else
            button.Icon = button:CreateTexture(nil, "OVERLAY")
            if tags.search then
                button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/Search.png")
            elseif tags.copy then
                button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/Copy.png")
            elseif tags.settings then
                button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/SettingsCog.png")
            elseif tags.scrollToEnd then
                button.Icon:SetTexture("Interface/AddOns/Chattynator/Assets/ScrollToBottom.png")
            end
            button.Icon:SetPoint("CENTER")
            button.Icon:SetSize(15, 15)
            button.Icon:SetVertexColor(intensity, intensity, intensity)
        end

        if not tags.toasts then
            button:HookScript("OnEnter", function()
                if not enableHooks then return end
                button.Icon:SetVertexColor(hoverColor.r, hoverColor.g, hoverColor.b)
                if button.nduiBg then
                    button.nduiBg:SetBackdropColor(cr or 1, cg or 1, cb or 1, 0.25)
                end
            end)
            button:HookScript("OnLeave", function()
                if not enableHooks then return end
                button.Icon:SetVertexColor(intensity, intensity, intensity)
                if button.nduiBg then
                    local alpha = addonTable.Config.Get("skins.ndui.chat_transparency") or 0.5
                    button.nduiBg:SetBackdropColor(0, 0, 0, alpha)
                end
            end)
        end

        button:HookScript("OnMouseDown", function()
            if not enableHooks then return end
            button.Icon:AdjustPointsOffset(1, -1)
        end)
        button:HookScript("OnMouseUp", function()
            if not enableHooks then return end
            button.Icon:AdjustPointsOffset(-1, 1)
        end)
    end,

    ChatFrame = function(frame, tags)
        table.insert(chatFrames, frame)

        local alpha = addonTable.Config.Get("skins.ndui.chat_transparency") or 0.5

        frame.bg = CreateNDuiBackdrop(frame.ScrollingMessagesWrapper, alpha)
        if frame.bg then frame.bg:Show() end

        if frame.backgroundColor then
            frame:SetBackgroundColor(frame.backgroundColor.r, frame.backgroundColor.g, frame.backgroundColor.b)
        end
    end,

    ChatEditBox = function(editBox, tags)
        table.insert(editBoxes, editBox)

        for _, texName in ipairs({ "Left", "Right", "Mid", "FocusLeft", "FocusRight", "FocusMid" }) do
            local tex = _G[editBox:GetName() .. texName]
            if tex then
                tex:SetTexture(nil)
            end
        end

        local alpha = addonTable.Config.Get("skins.ndui.chat_transparency") or 0.5
        editBox.nduiBg = CreateNDuiBackdrop(editBox, alpha)

        if DB and DB.Font then
            editBox:SetFont(DB.Font[1], DB.Font[2], "")
            if editBox.header then
                editBox.header:SetFont(DB.Font[1], DB.Font[2], "")
            end
        end
    end,

    ChatTab = function(tab, tags)
        table.insert(chatTabs, tab)

        StripTextures(tab)

        tab:SetHeight(22)
        tab:SetAlpha(1)

        if tab:GetFontString() == nil then
            tab:SetText(" ")
        end

        local font, size = tab:GetFontString():GetFont()
        if DB and DB.Font then
            font = DB.Font[1]
            size = DB.Font[2] + 2
        end

        local outline = DB and DB.Font and DB.Font[3] or ""
        tab:GetFontString():SetFont(font, size, outline)
        tab:GetFontString():SetShadowColor(0, 0, 0, outline ~= "" and 0 or 1)

        tab:GetFontString():SetPoint("TOP", 0, -5)
        tab:GetFontString():SetWordWrap(false)
        tab:GetFontString():SetNonSpaceWrap(false)

        local fsWidth
        if tab.minWidth then
            fsWidth = tab:GetFontString():GetUnboundedStringWidth() + addonTable.Constants.TabPadding
        else
            fsWidth = math.max(
                tab:GetFontString():GetUnboundedStringWidth(),
                not tab:GetText():find("|K") and addonTable.Constants.MinTabWidth or 70
            ) + addonTable.Constants.TabPadding
        end
        tab:GetFontString():SetWidth(fsWidth)
        tab:SetWidth(fsWidth)

        hooksecurefunc(tab, "SetText", function()
            if not enableHooks then return end

            if tab.minWidth then
                fsWidth = tab:GetFontString():GetUnboundedStringWidth() + addonTable.Constants.TabPadding
            else
                fsWidth = math.max(
                    tab:GetFontString():GetUnboundedStringWidth(),
                    not tab:GetText():find("|K") and addonTable.Constants.MinTabWidth or 70
                ) + addonTable.Constants.TabPadding
            end
            tab:GetFontString():SetWidth(fsWidth)
            tab:SetWidth(fsWidth)
        end)

        hooksecurefunc(tab, "SetSelected", function(_, state)
            if not enableHooks then return end

            if state then
                tab:GetFontString():SetTextColor(cr or 1, cg or 0.52, cb or 0)
            else
                tab:GetFontString():SetTextColor(0.6, 0.6, 0.6)
            end
        end)

        hooksecurefunc(tab, "SetColor", function(_, r, g, b)
            tab.nduiColor = { r = r, g = g, b = b }
        end)

        if tab.selected ~= nil then
            tab:SetSelected(tab.selected)
        end

        tab.FlashAnimation = tab:CreateAnimationGroup()
        tab.FlashAnimation:SetLooping("BOUNCE")
        local alpha1 = tab.FlashAnimation:CreateAnimation("Alpha")
        alpha1:SetChildKey("Text")
        alpha1:SetFromAlpha(0.3)
        alpha1:SetToAlpha(1)
        alpha1:SetDuration(0.5)
        alpha1:SetOrder(1)

        hooksecurefunc(tab, "SetFlashing", function(_, state)
            if not enableHooks then return end
            tab.FlashAnimation:SetPlaying(state)
        end)

        table.insert(toUpdate, function()
            tab:SetText(tab:GetText())
            if tab.selected ~= nil then
                tab:SetSelected(tab.selected)
            end
        end)
    end,

    ResizeWidget = function(frame, tags)
        local tex = frame:CreateTexture(nil, "ARTWORK")
        tex:SetVertexColor(intensity, intensity, intensity)
        tex:SetTexture("Interface/AddOns/Chattynator/Assets/resize.png")
        tex:SetTexCoord(0, 1, 1, 0)
        tex:SetAllPoints()

        frame:SetScript("OnEnter", function()
            tex:SetVertexColor(hoverColor.r, hoverColor.g, hoverColor.b)
        end)
        frame:SetScript("OnLeave", function()
            tex:SetVertexColor(intensity, intensity, intensity)
        end)
    end,
}

local function SkinFrame(details)
    local func = skinners[details.regionType]
    if func then
        func(details.region, details.tags and ConvertTags(details.tags) or {})
    end
end

local function SetConstants()
    addonTable.Constants.ButtonFrameOffset = 0
end

local function LoadSkin()
    local ND = _G["NDui"]

    if ND then
        B, C, L, DB = unpack(ND)

        if DB and DB.r then
            cr, cg, cb = DB.r, DB.g, DB.b
            hoverColor = { r = cr, g = cg, b = cb }
        end
    end

    addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
        if settingName == "skins.ndui.chat_transparency" then
            local value = addonTable.Config.Get(settingName) or 0.5
            local alpha = value
            for _, frame in ipairs(chatFrames) do
                if frame.bg then
                    frame.bg:SetBackdropColor(0, 0, 0, alpha)
                end
            end
            for _, editBox in ipairs(editBoxes) do
                if editBox.nduiBg then
                    editBox.nduiBg:SetBackdropColor(0, 0, 0, alpha)
                end
            end
            for _, button in ipairs(chatButtons) do
                if button.nduiBg then
                    button.nduiBg:SetBackdropColor(0, 0, 0, alpha)
                end
            end
        end
    end)
end

if addonTable.Skins.IsAddOnLoading("NDui") then
    addonTable.Skins.RegisterSkin(addonTable.Locales.NDUI, "ndui", LoadSkin, SkinFrame, SetConstants, {
        {
            type = "slider",
            text = addonTable.Locales.CHAT_TRANSPARENCY,
            option = "chat_transparency",
            min = 0,
            max = 100,
            default = 0.5,
            lowText = "0%",
            highText = "100%",
            scale = 100,
            valuePattern = "%s%%",
        },
    }, true)
end
