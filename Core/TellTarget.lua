---@class addonTableChattynator
local addonTable = select(2, ...)

local ChatEdit_UpdateHeader = _G.ChatEdit_UpdateHeader or _G.ChatFrameEditBoxMixin.UpdateHeader

function addonTable.Core.InitializeTellTarget()
  local function OnTextChanged(editBox)
    if not addonTable.Config.Get(addonTable.Config.Options.ENABLE_TELL_TARGET) then
      return
    end
    local text = editBox:GetText()
    local command, msg = text:match("^(/%S+)%s(.*)$")
    if command == "/tt" or command == "/telltarget" then
      local unitname, realm, fullname
      if UnitIsPlayer("target") then
        unitname, realm = UnitName("target")
        if unitname then
          if realm and UnitRealmRelationship("target") ~= LE_REALM_RELATION_SAME then
            fullname = unitname .. "-" .. realm
          else
            fullname = unitname
          end
        end
      end

      if fullname then
        local target = fullname:gsub(" ", "")
        editBox:SetAttribute("chatType", "WHISPER")
        editBox:SetAttribute("tellTarget", target)
        editBox:SetText(msg or "")
        ChatEdit_UpdateHeader(editBox)
      else
        if not UnitExists("target") then
          addonTable.Utilities.Message(addonTable.Locales.TT_NO_TARGET or "No target selected.")
        elseif not UnitIsPlayer("target") then
          addonTable.Utilities.Message(addonTable.Locales.TT_NOT_PLAYER or "Target is not a player.")
        end
        editBox:SetText("")
      end
    end
  end

  ChatFrame1EditBox:HookScript("OnTextChanged", OnTextChanged)

  SlashCmdList["ChattynatorTellTarget"] = function(msg)
    if not addonTable.Config.Get(addonTable.Config.Options.ENABLE_TELL_TARGET) then
      return
    end
    local unitname, realm, fullname
    if UnitIsPlayer("target") then
      unitname, realm = UnitName("target")
      if unitname then
        if realm and UnitRealmRelationship("target") ~= LE_REALM_RELATION_SAME then
          fullname = unitname .. "-" .. realm
        else
          fullname = unitname
        end
      end
    end

    if fullname then
      local target = fullname:gsub(" ", "")
      ChatFrame1EditBox:SetAttribute("chatType", "WHISPER")
      ChatFrame1EditBox:SetAttribute("tellTarget", target)
      ChatFrame1EditBox:SetText(msg or "")
      ChatEdit_UpdateHeader(ChatFrame1EditBox)
      ChatFrame_OpenChat(msg or "", ChatFrame1)
    else
      if not UnitExists("target") then
        addonTable.Utilities.Message(addonTable.Locales.TT_NO_TARGET or "No target selected.")
      elseif not UnitIsPlayer("target") then
        addonTable.Utilities.Message(addonTable.Locales.TT_NOT_PLAYER or "Target is not a player.")
      end
    end
  end
  SLASH_ChattynatorTellTarget1 = "/tt"
  SLASH_ChattynatorTellTarget2 = "/telltarget"
end
