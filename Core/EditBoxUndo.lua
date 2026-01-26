---@class addonTableChattynator
local addonTable = select(2, ...)

addonTable.Core.EditBoxUndo = {}

local trackedEditBoxes = {}
local defaultDebounceSeconds = 0.3

local function NormalizeLimit(value)
  value = tonumber(value) or 0
  value = math.floor(value)
  if value < 1 then
    value = 1
  end
  return value
end

local function GetHistoryLimit()
  return NormalizeLimit(addonTable.Config.Get(addonTable.Config.Options.EDIT_BOX_UNDO_HISTORY))
end

local function TrimHistory(state)
  local overflow = #state.history - state.max
  if overflow <= 0 then
    return
  end
  for _ = 1, overflow do
    table.remove(state.history, 1)
  end
  state.index = math.max(1, state.index - overflow)
end

local function ClearPending(state)
  if state.pendingTimer then
    state.pendingTimer:Cancel()
    state.pendingTimer = nil
  end
  state.pendingText = nil
  state.pendingCursor = nil
end

local function PushHistory(state, text, cursor)
  local last = state.history[state.index]
  if last and last.text == text then
    return
  end
  for i = #state.history, state.index + 1, -1 do
    table.remove(state.history, i)
  end
  table.insert(state.history, { text = text, cursor = cursor })
  state.index = #state.history
  TrimHistory(state)
end

local function FlushPending(state)
  if not state.pendingText then
    return
  end
  local text = state.pendingText
  local cursor = state.pendingCursor
  ClearPending(state)
  PushHistory(state, text, cursor)
end

local function ScheduleCommit(state, text, cursor)
  state.pendingText = text
  state.pendingCursor = cursor
  if state.pendingTimer then
    state.pendingTimer:Cancel()
  end
  state.pendingTimer = C_Timer.NewTimer(state.debounceSeconds, function()
    state.pendingTimer = nil
    if state.pendingText then
      local pendingText = state.pendingText
      local pendingCursor = state.pendingCursor
      state.pendingText = nil
      state.pendingCursor = nil
      PushHistory(state, pendingText, pendingCursor)
    end
  end)
end

local function ApplyEntry(editBox, state, entry)
  state.ignore = true
  editBox:SetText(entry.text)
  local cursor = entry.cursor or #entry.text
  if cursor > #entry.text then
    cursor = #entry.text
  end
  editBox:SetCursorPosition(cursor)
  state.ignore = false
end

local function Undo(editBox, state)
  FlushPending(state)
  if state.index <= 1 then
    return false
  end
  state.index = state.index - 1
  ApplyEntry(editBox, state, state.history[state.index])
  return true
end

local function Redo(editBox, state)
  FlushPending(state)
  if state.index >= #state.history then
    return false
  end
  state.index = state.index + 1
  ApplyEntry(editBox, state, state.history[state.index])
  return true
end

local function EnsureState(editBox, options)
  if editBox.ChattynatorUndo then
    return editBox.ChattynatorUndo
  end
  local state = {
    history = {},
    index = 0,
    max = NormalizeLimit((options and options.max) or GetHistoryLimit()),
    debounceSeconds = (options and options.debounceSeconds) or defaultDebounceSeconds,
    pendingTimer = nil,
    pendingText = nil,
    pendingCursor = nil,
    ignore = false,
    hooked = false,
  }
  local text = editBox:GetText() or ""
  local cursor = editBox:GetCursorPosition() or 0
  if cursor > #text then
    cursor = #text
  end
  state.history[1] = { text = text, cursor = cursor }
  state.index = 1
  editBox.ChattynatorUndo = state
  trackedEditBoxes[editBox] = true
  return state
end

local function CanEditBoxInput(editBox)
  if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
    return false
  end
  return editBox:IsVisible()
end

function addonTable.Core.EditBoxUndo.Attach(editBox, options)
  if not editBox then
    return
  end
  local state = EnsureState(editBox, options)
  if state.hooked then
    return
  end
  state.hooked = true

  editBox:HookScript("OnTextChanged", function(self)
    if state.ignore then
      return
    end
    local text = self:GetText() or ""
    local last = state.history[state.index]
    if last and last.text == text then
      ClearPending(state)
      return
    end
    local cursor = self:GetCursorPosition() or 0
    if cursor > #text then
      cursor = #text
    end
    ScheduleCommit(state, text, cursor)
  end)

  editBox:HookScript("OnEditFocusLost", function()
    FlushPending(state)
  end)

  editBox:HookScript("OnHide", function()
    FlushPending(state)
  end)

  editBox:HookScript("OnKeyDown", function(self, key)
    if not CanEditBoxInput(self) then
      return
    end
    if not IsControlKeyDown() or IsAltKeyDown() then
      return
    end
    if key == "Z" then
      if IsShiftKeyDown() then
        Redo(self, state)
      else
        Undo(self, state)
      end
    elseif key == "Y" then
      Redo(self, state)
    end
  end)
end

function addonTable.Core.EditBoxUndo.RefreshHistoryLimit()
  local max = GetHistoryLimit()
  for editBox in pairs(trackedEditBoxes) do
    if editBox.ChattynatorUndo then
      editBox.ChattynatorUndo.max = max
      TrimHistory(editBox.ChattynatorUndo)
    end
  end
end

function addonTable.Core.EditBoxUndo.Reset(editBox)
  if not editBox or not editBox.ChattynatorUndo then
    return
  end
  local state = editBox.ChattynatorUndo
  ClearPending(state)
  state.history = {}
  state.index = 1
  local text = editBox:GetText() or ""
  local cursor = editBox:GetCursorPosition() or 0
  if cursor > #text then
    cursor = #text
  end
  state.history[1] = { text = text, cursor = cursor }
end

function addonTable.Core.EditBoxUndo.Initialize()
  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.EDIT_BOX_UNDO_HISTORY then
      addonTable.Core.EditBoxUndo.RefreshHistoryLimit()
    end
  end)
  addonTable.Core.EditBoxUndo.Attach(ChatFrame1EditBox)
end
