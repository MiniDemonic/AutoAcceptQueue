-- NOTES
-- GetLFGRoles() : isLeader, isTank, isHealer, isDPS - Returns the roles the player signed up for in the Dungeon Finder.
-- SetLFGRoles([leader, tank, healer, dps]) - Changes the selected roles.
-- GetSpecializationRoleByID(specID) : roleToken - Returns the role a specialization is intended to perform.
-- GetSpecialization() : specIndex
-- GetSpecializationInfo(specIndex) : Returns specID


-- SavedVariables
AutoAcceptQueueDB = AutoAcceptQueueDB or { enabled = true, debug = true, log = {} }

local addonName = "AutoAcceptQueue"
local frame = CreateFrame("Frame", addonName .. "Frame")

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99" .. addonName .. "|r: " .. tostring(msg))
end

local function Debug(msg)
    if AutoAcceptQueueDB.debug then
        Print(msg)
    end
end

local function LogEntry(entry)
    AutoAcceptQueueDB.log[#AutoAcceptQueueDB.log + 1] = date("%Y-%m-%d %H:%M:%S") .. " - " .. entry
    -- keep log reasonably small
    if #AutoAcceptQueueDB.log > 20 then
        for i = 1, #AutoAcceptQueueDB.log - 20 do
            table.remove(AutoAcceptQueueDB.log, 1)
        end
    end
end

local function UpdateRoles()
    local isLeader, _, _, _ = GetLFGRoles()
    local specRole = GetSpecializationRole(GetSpecialization())
    local wantTank = (specRole == "TANK")
    local wantHealer = (specRole == "HEALER")
    local wantDPS = (specRole == "DAMAGER")

    SetLFGRoles(isLeader, wantTank, wantHealer, wantDPS)
    return "Updated Roles: Leader = "..tostring(isLeader).." | Tank = "..tostring(wantTank).." | Healer = "..tostring(wantHealer).." | DPS = "..tostring(wantDPS)
end

-- Called when we detect a proposal; small delay to allow frames to be created
local function OnProposalDetected(source)
    if not AutoAcceptQueueDB.enabled then
        Debug("Proposal detected but auto-accept disabled.")
        return
    end

    if IsShiftKeyDown() then
        Debug("Proposal detected but shift was held down.")
        return
    end

    local roleResult = UpdateRoles()
    Debug(roleResult)
    LogEntry(roleResult)

    local checkResult = CompleteLFGRoleCheck(true)
    Debug("API: CompleteLFGRoleCheck(true) -> "..tostring(checkResult))
    LogEntry("API: CompleteLFGRoleCheck(true) -> "..tostring(checkResult))
end

-- Event handler: listen for LFG proposal event and also hook StaticPopup_Show
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "LFG_ROLE_CHECK_SHOW" then
        Debug("Event: LFG_ROLE_CHECK_SHOW")
        LogEntry("Event: LFG_ROLE_CHECK_SHOW")
        OnProposalDetected("LFG_ROLE_CHECK_SHOW")
    end
end)

frame:RegisterEvent("LFG_ROLE_CHECK_SHOW")

-- Slash commands
SLASH_AUTOACCEPTQUEUE1 = "/aaq"
SLASH_AUTOACCEPTQUEUE2 = "/autoq"
SlashCmdList["AUTOACCEPTQUEUE"] = function(msg)
    local cmd = msg:lower():gsub("^%s*(.-)%s*$","%1")
    if cmd == "on" then
        AutoAcceptQueueDB.enabled = true
        Print("Auto-accept enabled.")
    elseif cmd == "off" then
        AutoAcceptQueueDB.enabled = false
        Print("Auto-accept disabled.")
    elseif cmd == "debug on" then
        AutoAcceptQueueDB.debug = true
        Print("Debug enabled.")
    elseif cmd == "debug off" then
        AutoAcceptQueueDB.debug = false
        Print("Debug disabled.")
    elseif cmd == "debuglog" then
        if #AutoAcceptQueueDB.log == 0 then
            Print("No log entries.")
        else
            for i = 1, #AutoAcceptQueueDB.log do
                DEFAULT_CHAT_FRAME:AddMessage(AutoAcceptQueueDB.log[i])
            end
        end
    elseif cmd == "status" or cmd == "" then
        Print("Auto-accept is " .. (AutoAcceptQueueDB.enabled and "enabled" or "disabled") .. ". Debug is " .. (AutoAcceptQueueDB.debug and "on" or "off") .. ".")
    else
        Print("Usage: /autolfg on | off | status | debug on | debug off | debuglog | test")
    end
end