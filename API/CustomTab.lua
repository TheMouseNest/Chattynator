---@class addonTableChattynator
local addonTable = select(2, ...)

local delayedRegistrationFrame

local function CombatLogInstall(parent)
  if not CombatLogQuickButtonFrame_Custom then
    if not delayedRegistrationFrame then
      delayedRegistrationFrame = CreateFrame("Frame")
      delayedRegistrationFrame:RegisterEvent("UPDATE_CHAT_WINDOWS")
      delayedRegistrationFrame:SetScript("OnEvent", function()
        C_Timer.After(0, function()
          CombatLogInstall(parent)
        end)
        delayedRegistrationFrame:UnregisterEvent("UPDATE_CHAT_WINDOWS")
      end)
    end
    return
  end
  CombatLogQuickButtonFrame_Custom:SetParent(ChatFrame2)
  CombatLogQuickButtonFrame_Custom:ClearAllPoints()
  CombatLogQuickButtonFrame_Custom:SetPoint("TOPLEFT", parent, 0, 0)
  CombatLogQuickButtonFrame_Custom:SetPoint("TOPRIGHT", parent, 0, 0)
  ChatFrame2:SetParent(parent)
  if ChatFrame2ResizeButton then
    ChatFrame2ResizeButton:SetParent(addonTable.hiddenFrame)
  end
  ChatFrame2:ClearAllPoints()
  ChatFrame2:SetPoint("TOPLEFT", 0, -22)
  ChatFrame2:SetPoint("BOTTOMRIGHT", -15, 0)

  ChatFrame2Background:SetParent(addonTable.hiddenFrame)
  ChatFrame2BottomRightTexture:SetParent(addonTable.hiddenFrame)
  ChatFrame2BottomLeftTexture:SetParent(addonTable.hiddenFrame)
  ChatFrame2BottomTexture:SetParent(addonTable.hiddenFrame)
  ChatFrame2TopLeftTexture:SetParent(addonTable.hiddenFrame)
  ChatFrame2TopRightTexture:SetParent(addonTable.hiddenFrame)
  ChatFrame2TopTexture:SetParent(addonTable.hiddenFrame)
  ChatFrame2RightTexture:SetParent(addonTable.hiddenFrame)
  ChatFrame2LeftTexture:SetParent(addonTable.hiddenFrame)
  ChatFrame2:SetClampRectInsets(0, 0, 0, 0)
  if ChatFrame2ButtonFrameLeftTexture then
    ChatFrame2ButtonFrameLeftTexture:SetParent(addonTable.hiddenFrame)
  end
  if ChatFrame2ButtonFrameBackground then
    ChatFrame2ButtonFrameBackground:SetParent(addonTable.hiddenFrame)
    ChatFrame2ButtonFrameRightTexture:SetParent(addonTable.hiddenFrame)
  end
  if ChatFrame2ButtonFrameUpButton then
    ChatFrame2ButtonFrameUpButton:SetParent(addonTable.hiddenFrame)
    ChatFrame2ButtonFrameDownButton:SetParent(addonTable.hiddenFrame)
  end
  ChatFrame2:Show()
  hooksecurefunc(ChatFrame2, "Hide", function()
    print(debugstack())
  end)
end

Chattynator.API.RegisterCustomTab("COMBAT_LOG", "combat_log", CombatLogInstall)
