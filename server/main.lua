-- kt_idcard_ui v3 — SERVER FIXED v2
-- Corrections :
--   [FIX-1] getCharacter() normalise toutes les structures connues du framework Union
--   [FIX-2] Helpers isConnected/notify/hasItem/addItem déclarés avant tout usage
--   [FIX-3] Contrôles policiers implémentés (checkIdentity, checkLicense, checkBadge)
--   [FIX-4] showToNearby implémenté côté serveur
--   [FIX-5] idcard:npc:interact et idcard:driving:interact routent vers la bonne carte

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
-- CHARACTER WRAPPER [FIX-1]
-- Normalise toutes les structures retournées par Union
-- ─────────────────────────────────────────────

local function getCharacter(src)
    if not src then return nil end

    local ok, raw = pcall(function()
        return exports[Config.resources.union]:GetCharacterState(src)
    end)

    if not ok then
        dprint("GetCharacterState ERROR for src=" .. tostring(src))
        return nil
    end

    if not raw then
        dprint("Character NIL for src=" .. tostring(src))
        return nil
    end

    if type(raw) ~= "table" then
        dprint("Character not a table for src=" .. tostring(src))
        return nil
    end

    -- Normalisation : toutes les structures connues de Union
    if raw.data        and type(raw.data)      == "table" then return raw.data      end
    if raw.character   and type(raw.character) == "table" then return raw.character end
    if raw.currentCharacter and type(raw.currentCharacter) == "table" then return raw.currentCharacter end

    -- Vérification minimale : doit avoir au moins firstname ou unique_id
    if raw.firstname or raw.unique_id then return raw end

    dprint("Character structure inconnue pour src=" .. tostring(src) .. " : " .. json.encode(raw):sub(1, 120))
    return nil
end

-- ─────────────────────────────────────────────
-- HELPERS [FIX-2]
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
        action   = "showCard",
        cardType = cardType,
        data     = data,
    })
end

-- ─────────────────────────────────────────────
-- NPC INTERACTIONS [FIX-5]
-- idcard:npc:interact     → carte d'identité
-- idcard:driving:interact → permis de conduire
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:npc:interact", function()
    local src  = source
    local char = getCharacter(src)
    if not char then
        dprint("NO CHAR on npc:interact for src=" .. tostring(src))
        return
    end

    -- Vérifier que le joueur possède (ou créer) la carte d'identité
    if not hasItem(src, Config.items.identity) then
        addItem(src, Config.items.identity)
        notify(src, "Votre carte d'identité a été créée.", "success")
    end

    sendCard(src, "identity", {
        type        = "identity",
        firstname   = char.firstname,
        lastname    = char.lastname,
        uniqueId    = char.unique_id,
        dateOfBirth = char.dateofbirth or char.dob or "—",
        nationality = "Française",
    })
end)

RegisterNetEvent("idcard:driving:interact", function()
    local src  = source
    local char = getCharacter(src)
    if not char then
        dprint("NO CHAR on driving:interact for src=" .. tostring(src))
        return
    end

    sendCard(src, "driver", {
        type          = "driver",
        firstname     = char.firstname,
        lastname      = char.lastname,
        licenseNumber = char.unique_id or "UNKNOWN",
        categories    = { "B" },
    })
end)

-- ─────────────────────────────────────────────
-- BASIC ID CARD (usage depuis inventaire)
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then
        dprint("NO CHAR on identity use for src=" .. tostring(src))
        return
    end

    sendCard(src, "identity", {
        type        = "identity",
        firstname   = char.firstname,
        lastname    = char.lastname,
        uniqueId    = char.unique_id,
        dateOfBirth = char.dateofbirth or char.dob or "—",
        nationality = "Française",
    })
end)

-- ─────────────────────────────────────────────
-- LICENSE CARD
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:license:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end

    sendCard(src, "driver", {
        type          = "driver",
        firstname     = char.firstname,
        lastname      = char.lastname,
        licenseNumber = char.unique_id or "UNKNOWN",
        categories    = { "B" },
    })
end)

-- ─────────────────────────────────────────────
-- LICENSE CHECK (véhicule)
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:license:check", function(licType)
    local src  = source
    if not isConnected(src) then return end

    local char = getCharacter(src)
    if not char or not char.unique_id then return end

    -- Vérifier en BDD si le joueur a le permis requis
    exports.oxmysql:scalar(
        "SELECT COUNT(*) FROM user_licenses WHERE unique_id = ? AND type = ?",
        { char.unique_id, licType },
        function(count)
            if not count or count < 1 then
                local fine = Config.licenses.fine or 1500
                notify(src,
                    ("Permis de catégorie %s requis. Amende : $%d"):format(licType, fine),
                    "error")
                -- Déduire l'amende du compte bancaire
                exports.oxmysql:execute(
                    "UPDATE bank_accounts SET balance = balance - ? WHERE unique_id = ? AND type = 'personal' AND balance >= ?",
                    { fine, char.unique_id, fine },
                    nil
                )
            end
        end
    )
end)

-- ─────────────────────────────────────────────
-- WEAPON CARD
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:weapon:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end

    sendCard(src, "weapon", {
        type          = "weapon",
        firstname     = char.firstname,
        lastname      = char.lastname,
        licenseNumber = ("WPN-%04d"):format(math.random(1000, 9999)),
    })
end)

-- ─────────────────────────────────────────────
-- POLICE BADGE
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:police:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end

    if not isInJobs(char, Config.policeJobs) then
        notify(src, "Vous n'êtes pas policier.", "error")
        return
    end

    sendCard(src, "police", {
        type        = "police",
        firstname   = char.firstname,
        lastname    = char.lastname,
        badgeNumber = ("LSPD-%04d"):format(math.random(1000, 9999)),
        rank        = char.job_grade_label or char.job or "Officer",
    })
end)

-- ─────────────────────────────────────────────
-- EMS CARD
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:ems:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end

    if not isInJobs(char, Config.emsJobs) then return end

    sendCard(src, "ems", {
        type      = "ems",
        firstname = char.firstname,
        lastname  = char.lastname,
        emsNumber = ("EMS-%04d"):format(math.random(1000, 9999)),
    })
end)

-- ─────────────────────────────────────────────
-- CONTRÔLES POLICIERS [FIX-3]
-- ─────────────────────────────────────────────

-- Récupère la cible par serverId
local function getTargetChar(targetSid)
    local sid = tonumber(targetSid)
    if not sid then return nil, nil end
    if not isConnected(sid) then return nil, nil end
    local char = getCharacter(sid)
    return sid, char
end

RegisterNetEvent("idcard:police:checkIdentity", function(targetSid)
    local src      = source
    local officer  = getCharacter(src)
    if not officer or not isInJobs(officer, Config.policeJobs) then return end

    local tid, target = getTargetChar(targetSid)
    if not tid or not target then
        notify(src, "Joueur introuvable.", "error")
        return
    end

    -- Log du contrôle
    if officer.unique_id and target.unique_id then
        exports.oxmysql:execute(
            "INSERT INTO police_checks_log (officer_uid, target_uid, check_type) VALUES (?, ?, 'identity')",
            { officer.unique_id, target.unique_id },
            nil
        )
    end

    -- Envoyer la carte à l'officier
    sendCard(src, "identity", {
        type        = "identity",
        firstname   = target.firstname,
        lastname    = target.lastname,
        uniqueId    = target.unique_id,
        dateOfBirth = target.dateofbirth or target.dob or "—",
        nationality = "Française",
    })
end)

RegisterNetEvent("idcard:police:checkLicense", function(targetSid)
    local src     = source
    local officer = getCharacter(src)
    if not officer or not isInJobs(officer, Config.policeJobs) then return end

    local tid, target = getTargetChar(targetSid)
    if not tid or not target then
        notify(src, "Joueur introuvable.", "error")
        return
    end

    if not target.unique_id then
        notify(src, "Impossible de vérifier le permis.", "error")
        return
    end

    exports.oxmysql:execute(
        "SELECT type FROM user_licenses WHERE unique_id = ?",
        { target.unique_id },
        function(rows)
            if officer.unique_id then
                exports.oxmysql:execute(
                    "INSERT INTO police_checks_log (officer_uid, target_uid, check_type) VALUES (?, ?, 'license')",
                    { officer.unique_id, target.unique_id },
                    nil
                )
            end

            local cats = {}
            if rows and #rows > 0 then
                for _, row in ipairs(rows) do
                    table.insert(cats, row.type)
                end
            end

            sendCard(src, "driver", {
                type          = "driver",
                firstname     = target.firstname,
                lastname      = target.lastname,
                licenseNumber = target.unique_id,
                categories    = #cats > 0 and cats or {},
                valid         = #cats > 0,
            })
        end
    )
end)

RegisterNetEvent("idcard:police:checkBadge", function(targetSid)
    local src     = source
    local officer = getCharacter(src)
    if not officer or not isInJobs(officer, Config.policeJobs) then return end

    local tid, target = getTargetChar(targetSid)
    if not tid or not target then
        notify(src, "Joueur introuvable.", "error")
        return
    end

    if not isInJobs(target, Config.policeJobs) then
        notify(src, "Cette personne n'est pas agent de police.", "warning")
        return
    end

    if officer.unique_id and target.unique_id then
        exports.oxmysql:execute(
            "INSERT INTO police_checks_log (officer_uid, target_uid, check_type) VALUES (?, ?, 'badge')",
            { officer.unique_id, target.unique_id },
            nil
        )
    end

    sendCard(src, "police", {
        type        = "police",
        firstname   = target.firstname,
        lastname    = target.lastname,
        badgeNumber = ("LSPD-%04d"):format(math.random(1000, 9999)),
        rank        = target.job_grade_label or target.job or "Officer",
    })
end)

-- ─────────────────────────────────────────────
-- SHOW TO NEARBY [FIX-4]
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:showToNearby", function(cardType)
    local src  = source
    local char = getCharacter(src)
    if not char or not isConnected(src) then return end

    local srcCoords = GetEntityCoords(GetPlayerPed(src))
    local radius    = Config.showRadius or 5.0

    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if pid and pid ~= src and isConnected(pid) then
            local ped    = GetPlayerPed(pid)
            local coords = GetEntityCoords(ped)
            if #(srcCoords - coords) <= radius then
                TriggerClientEvent("idcard:show", pid, {
                    action   = "showCard",
                    cardType = cardType,
                    data     = {
                        type        = cardType,
                        firstname   = char.firstname,
                        lastname    = char.lastname,
                        uniqueId    = char.unique_id,
                        dateOfBirth = char.dateofbirth or char.dob or "—",
                        nationality = "Française",
                    },
                })
            end
        end
    end
end)

-- ─────────────────────────────────────────────
-- ÉVÉNEMENTS FERMÉS (notifications client)
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:closed",   function() end)
RegisterNetEvent("bankcard:closed", function() end)

-- ─────────────────────────────────────────────
-- EXPORTS
-- ─────────────────────────────────────────────

exports("ShowCard", function(src, cardType, data)
    sendCard(src, cardType, data)
end)

exports("UseIdentityCard", function(src)
    local char = getCharacter(src)
    if not char then
        dprint("EXPORT identity failed: no char for src=" .. tostring(src))
        return
    end
    sendCard(src, "identity", {
        type        = "identity",
        firstname   = char.firstname,
        lastname    = char.lastname,
        uniqueId    = char.unique_id,
        dateOfBirth = char.dateofbirth or char.dob or "—",
        nationality = "Française",
    })
end)

exports("UseLicenseCard", function(src)
    local char = getCharacter(src)
    if not char then return end
    sendCard(src, "driver", {
        type          = "driver",
        firstname     = char.firstname,
        lastname      = char.lastname,
        licenseNumber = char.unique_id,
        categories    = { "B" },
    })
end)

exports("UseWeaponCard", function(src)
    local char = getCharacter(src)
    if not char then return end
    sendCard(src, "weapon", {
        type          = "weapon",
        firstname     = char.firstname,
        lastname      = char.lastname,
        licenseNumber = ("WPN-%04d"):format(math.random(1000, 9999)),
    })
end)

exports("UsePoliceCard", function(src)
    local char = getCharacter(src)
    if not char then return end
    if not isInJobs(char, Config.policeJobs) then return end
    sendCard(src, "police", {
        type        = "police",
        firstname   = char.firstname,
        lastname    = char.lastname,
        badgeNumber = ("LSPD-%04d"):format(math.random(1000, 9999)),
        rank        = char.job_grade_label or char.job or "Officer",
    })
end)

exports("UseEMSCard", function(src)
    local char = getCharacter(src)
    if not char then return end
    if not isInJobs(char, Config.emsJobs) then return end
    sendCard(src, "ems", {
        type      = "ems",
        firstname = char.firstname,
        lastname  = char.lastname,
        emsNumber = ("EMS-%04d"):format(math.random(1000, 9999)),
    })
end)

exports("UsePassport", function(src)
    local char = getCharacter(src)
    if not char then return end
    sendCard(src, "identity", {
        type        = "identity",
        firstname   = char.firstname,
        lastname    = char.lastname,
        uniqueId    = char.unique_id,
        dateOfBirth = char.dateofbirth or char.dob or "—",
        nationality = "Française",
        isPassport  = true,
    })
end)

log:info("kt_idcard_ui SERVER LOADED v2")