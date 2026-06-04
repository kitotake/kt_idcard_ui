-- kt_idcard_ui v3 — SERVER FIXED

local log = Logger:child("IDCARD:SERVER")

-- ─────────────────────────────────────────────
-- DEBUG HELPER
-- ─────────────────────────────────────────────

local function dprint(...)
    if Config.debug then
        print("^3[kt_idcard_ui]^7", ...)
    end
end

-- ─────────────────────────────────────────────
-- CHARACTER WRAPPER (FIX PRINCIPAL)
-- ─────────────────────────────────────────────

local function getCharacter(src)
    if not src then return nil end

    local ok, raw = pcall(function()
        return exports[Config.resources.union]:GetCharacterState(src)
    end)

    if not ok then
        dprint("GetCharacterState ERROR for src", src)
        return nil
    end

    if not raw then
        dprint("Character NIL for src", src)
        return nil
    end

    -- normalisation structure (CRUCIAL FIX)
    if type(raw) == "table" then
        if raw.data then return raw.data end
        if raw.character then return raw.character end
        return raw
    end

    return nil
end

-- ─────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────

local function isConnected(src)
    return GetPlayerEndpoint(src) ~= nil
end

local function notify(src, msg, nType)
    TriggerClientEvent("idcard:notify", src, msg, nType or "info")
end

local function hasItem(src, item)
    local ok, n = pcall(function()
        return exports[Config.resources.inventory]:GetItemCount(src, item)
    end)
    return ok and n and n > 0
end

local function addItem(src, item)
    local ok, r = pcall(function()
        return exports[Config.resources.inventory]:AddItem(src, item, 1)
    end)
    return ok and r
end

local function isInJobs(char, jobList)
    if not char or not char.job then return false end
    for _, j in ipairs(jobList) do
        if char.job == j then return true end
    end
    return false
end

-- ─────────────────────────────────────────────
-- CARD SENDER
-- ─────────────────────────────────────────────

local function sendCard(src, cardType, data)
    if not isConnected(src) then return end

    TriggerClientEvent("idcard:show", src, {
        action = "showCard",
        cardType = cardType,
        data = data,
    })
end

-- ─────────────────────────────────────────────
-- BASIC ID CARD
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:use", function()
    local src = source
    local char = getCharacter(src)

    if not char then
        dprint("NO CHAR on identity use for", src)
        return
    end

    sendCard(src, "identity", {
        type = "identity",
        firstname = char.firstname,
        lastname = char.lastname,
        uniqueId = char.unique_id,
        dateOfBirth = char.dateofbirth or "—",
        nationality = "Française",
    })
end)

-- ─────────────────────────────────────────────
-- LICENSE CARD
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:license:use", function()
    local src = source
    local char = getCharacter(src)

    if not char then return end

    sendCard(src, "driver", {
        type = "driver",
        firstname = char.firstname,
        lastname = char.lastname,
        licenseNumber = char.unique_id or "UNKNOWN",
        categories = { "B" },
    })
end)

-- ─────────────────────────────────────────────
-- WEAPON CARD
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:weapon:use", function()
    local src = source
    local char = getCharacter(src)
    if not char then return end

    sendCard(src, "weapon", {
        type = "weapon",
        firstname = char.firstname,
        lastname = char.lastname,
        licenseNumber = ("WPN-%04d"):format(math.random(1000,9999)),
    })
end)

-- ─────────────────────────────────────────────
-- POLICE BADGE
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:police:use", function()
    local src = source
    local char = getCharacter(src)
    if not char then return end

    if not isInJobs(char, Config.policeJobs) then
        notify(src, "Vous n'êtes pas policier.", "error")
        return
    end

    sendCard(src, "police", {
        type = "police",
        firstname = char.firstname,
        lastname = char.lastname,
        badgeNumber = ("LSPD-%04d"):format(math.random(1000,9999)),
        rank = char.job or "Officer",
    })
end)

-- ─────────────────────────────────────────────
-- EMS CARD
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:ems:use", function()
    local src = source
    local char = getCharacter(src)
    if not char then return end

    if not isInJobs(char, Config.emsJobs) then return end

    sendCard(src, "ems", {
        type = "ems",
        firstname = char.firstname,
        lastname = char.lastname,
        emsNumber = ("EMS-%04d"):format(math.random(1000,9999)),
    })
end)

-- ─────────────────────────────────────────────
-- EXPORTS FIXED (IMPORTANT)
-- ─────────────────────────────────────────────

exports("UseIdentityCard", function(src)
    local char = getCharacter(src)
    if not char then
        dprint("EXPORT identity failed: no char", src)
        return
    end

    sendCard(src, "identity", {
        type = "identity",
        firstname = char.firstname,
        lastname = char.lastname,
        uniqueId = char.unique_id,
        nationality = "Française",
    })
end)

exports("UseLicenseCard", function(src)
    local char = getCharacter(src)
    if not char then return end

    sendCard(src, "driver", {
        type = "driver",
        firstname = char.firstname,
        lastname = char.lastname,
        licenseNumber = char.unique_id,
    })
end)

exports("UseWeaponCard", function(src)
    local char = getCharacter(src)
    if not char then return end

    sendCard(src, "weapon", {
        type = "weapon",
        firstname = char.firstname,
        lastname = char.lastname,
    })
end)

exports("UsePoliceCard", function(src)
    local char = getCharacter(src)
    if not char then return end
    if not isInJobs(char, Config.policeJobs) then return end

    sendCard(src, "police", {
        type = "police",
        firstname = char.firstname,
        lastname = char.lastname,
        badgeNumber = "LSPD-TEST",
    })
end)

exports("UseEMSCard", function(src)
    local char = getCharacter(src)
    if not char then return end
    if not isInJobs(char, Config.emsJobs) then return end

    sendCard(src, "ems", {
        type = "ems",
        firstname = char.firstname,
        lastname = char.lastname,
    })
end)

-- ─────────────────────────────────────────────
-- INIT LOG
-- ─────────────────────────────────────────────

dprint("kt_idcard_ui SERVER LOADED (FIXED VERSION)")