-- PoisonChecker 1.4 (Turtle / Vanilla 1.12.x)
-- Two-line warnings, persistent /pc show, and chat feedback on /pc.

PoisonCheckerDB = PoisonCheckerDB or {}

local function PC_SavePosition(frame)
  local p, _, rp, x, y = frame:GetPoint(1)
  PoisonCheckerDB.point = p
  PoisonCheckerDB.relPoint = rp
  PoisonCheckerDB.x = x
  PoisonCheckerDB.y = y
end

local function PC_RestorePosition(frame)
  local d = PoisonCheckerDB
  frame:ClearAllPoints()
  if d and d.point and d.relPoint and d.x and d.y then
    frame:SetPoint(d.point, UIParent, d.relPoint, d.x, d.y)
  else
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
  end
end

-- Display
local PC_Frame = CreateFrame("Frame", "PoisonCheckerFrame", UIParent)
PC_Frame:SetWidth(300)
PC_Frame:SetHeight(40)
PC_RestorePosition(PC_Frame)

PC_Frame:SetMovable(true)
PC_Frame:EnableMouse(true)
PC_Frame:SetScript("OnMouseDown", function() this:StartMoving() end)
PC_Frame:SetScript("OnMouseUp",   function() this:StopMovingOrSizing(); PC_SavePosition(this) end)

local PC_Text = PC_Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
PC_Text:SetAllPoints(true)
PC_Text:SetJustifyH("CENTER")
PC_Text:SetJustifyV("MIDDLE")
PC_Text:SetTextColor(1, 0, 0, 1)
PC_Frame:Hide()

-- state flag: when true, we keep the frame shown with test text (for positioning)
PC_ForceShow = PC_ForceShow or false

local function PC_Show(msg)
  PC_Text:SetText(msg or "")
  PC_Frame:Show()
end

local function PC_Hide()
  PC_Frame:Hide()
end

-- Returns true if both hands are poisoned
local function PC_BothOK()
  local mh, _, _, oh = GetWeaponEnchantInfo()
  return (mh and oh) and true or false
end

-- Core check: builds two-line message when both missing
local function PC_Check()
  -- If user is forcing the frame (positioning), do not auto-hide/overwrite
  if PC_ForceShow then return end

  local mh, _, _, oh = GetWeaponEnchantInfo()
  local warnMH = not mh
  local warnOH = not oh

  if warnMH or warnOH then
    local msg
    if warnMH and warnOH then
      msg = "No Mainhand Poison!\nNo Offhand Poison!"
    elseif warnMH then
      msg = "No Mainhand Poison!"
    else
      msg = "No Offhand Poison!"
    end
    PC_Show(msg)
  else
    PC_Hide()
  end
end

-- Slash commands
local function PC_SlashHandler(msg)
  msg = string.lower(msg or "")
  if msg == "show" then
    PC_ForceShow = true
    PC_Show("PoisonChecker (drag to move)")
    return
  elseif msg == "hide" then
    PC_ForceShow = false
    PC_Hide()
    return
  elseif msg == "check" or msg == "" then
    -- run a check and give feedback if everything is OK
    PC_ForceShow = false
    PC_Check()
    if PC_BothOK() then
      DEFAULT_CHAT_FRAME:AddMessage("PoisonChecker: both weapons poisoned.", 0, 1, 0)
    end
    return
  end
  DEFAULT_CHAT_FRAME:AddMessage("PoisonChecker: /pc [check|show|hide]  (/poison works too)", 1, 1, 0)
end

local function PC_RegisterSlash()
  SlashCmdList = SlashCmdList or {}
  SLASH_POISONCHECKER1 = "/pc"
  SLASH_POISONCHECKER2 = "/poison"
  SlashCmdList["POISONCHECKER"] = PC_SlashHandler
end

PC_RegisterSlash() -- bind at load

-- Events
local PC_Events = CreateFrame("Frame")
PC_Events:RegisterEvent("PLAYER_LOGIN")
PC_Events:RegisterEvent("PLAYER_ENTERING_WORLD")
PC_Events:RegisterEvent("PLAYER_REGEN_ENABLED")
PC_Events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
PC_Events:RegisterEvent("UPDATE_INVENTORY_ALERTS")

PC_Events:SetScript("OnEvent", function()
  if event == "PLAYER_LOGIN" then
    PC_RestorePosition(PC_Frame)
    PC_RegisterSlash() -- ensure bound even if other addons load after

    -- login banner (poison-green)
    local r, g, b = 0.1, 0.9, 0.3
    DEFAULT_CHAT_FRAME:AddMessage("PoisonChecker v1.3 loaded!", r, g, b)
  end
  if not UnitAffectingCombat("player") then
    PC_Check()
  end
end)

-- Ticker (separate frame so it still runs if display is hidden)
local PC_Ticker = CreateFrame("Frame")
local PC_Accum = 0
PC_Ticker:SetScript("OnUpdate", function()
  local elapsed = arg1
  if type(elapsed) ~= "number" then return end
  PC_Accum = PC_Accum + elapsed
  if PC_Accum >= 5.0 then
    if not UnitAffectingCombat("player") then
      PC_Check()
    end
    PC_Accum = 0
  end
end)
