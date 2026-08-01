-- server/main.lua
-- kt_idcard_ui v3 — SERVER v3
-- Corrections :
--   [FIX-1] getCharacter() normalise toutes les structures Union connues
--   [FIX-2] Helpers isConnected/notify/hasItem/addItem déclarés avant tout usage
--   [FIX-3] Contrôles policiers + rate limiting anti-spam
--   [FIX-4] showToNearby : données correctes selon cardType (plus que identity)
--   [FIX-5] idcard:npc:interact et idcard:driving:interact routent vers la bonne carte
--   [FIX-6] idcard:license:check : feedback si le débit échoue (solde insuffisant)
--   [FIX-7] Numéros de badge/permis persistants via user_licenses_meta

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
-- ─────────────────────────────────────────────

local function getCharacter(src)
    if not src then return nil end

    local ok, raw = pcall(function()
        return exports[Config.resources.union]:GetCharacterState(src)
    end)

    if not ok or not raw or type(raw) ~= "table" then
        dprint("GetCharacterState failed for src=" .. tostring(src))
        return nil
    end

    if raw.data             and type(raw.data)             == "table" then return raw.data             end
    if raw.character        and type(raw.character)        == "table" then return raw.character        end
    if raw.currentCharacter and type(raw.currentCharacter) == "table" then return raw.currentCharacter end
    if raw.firstname or raw.unique_id then return raw end

    dprint("Unknown character structure for src=" .. tostring(src))
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
-- NUMÉROS PERSISTANTS [FIX-7]
-- Évite les math.random à chaque affichage.
-- La table user_licenses_meta est créée dans sql/migrations.sql
-- ─────────────────────────────────────────────

local function getPersistentNumber(uniqueId, prefix, cb)
    if not uniqueId then
        cb(("%s-%04d"):format(prefix, math.random(1000, 9999)))
        return
    end

    exports.oxmysql:scalar(
        "SELECT license_number FROM user_licenses_meta WHERE unique_id = ? LIMIT 1",
        { uniqueId },
        function(existing)
            if existing then
                cb(existing)
            else
                local number = ("%s-%04d"):format(prefix, math.random(1000, 9999))
                exports.oxmysql:execute(
                    "INSERT IGNORE INTO user_licenses_meta (unique_id, license_number) VALUES (?, ?)",
                    { uniqueId, number },
                    nil
                )
                cb(number)
            end
        end
    )
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
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:npc:interact", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end

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
-- BASIC ID CARD (inventaire)
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end

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
-- LICENSE CHECK (véhicule) [FIX-6]
-- Feedback explicite si le débit échoue
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:license:check", function(licType)
    local src = source
    if not isConnected(src) then return end

    local char = getCharacter(src)
    if not char or not char.unique_id then return end

    exports.oxmysql:scalar(
        "SELECT COUNT(*) FROM user_licenses WHERE unique_id = ? AND type = ?",
        { char.unique_id, licType },
        function(count)
            if not count or count < 1 then
                local fine = Config.licenses.fine or 1500
                notify(src,
                    ("Permis de catégorie %s requis. Tentative d'amende : $%d"):format(licType, fine),
                    "error")

                -- [FIX-6] Vérification du résultat du débit
                exports.oxmysql:execute(
                    "UPDATE bank_accounts SET balance = balance - ? WHERE unique_id = ? AND type = 'personal' AND balance >= ?",
                    { fine, char.unique_id, fine },
                    function(result)
                        if result and (result.affectedRows or 0) > 0 then
                            notify(src,
                                ("Amende de $%d prélevée pour conduite sans permis %s."):format(fine, licType),
                                "error")
                        else
                            notify(src,
                                "Solde insuffisant pour l'amende. Convocation au tribunal.",
                                "warning")
                        end
                    end
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

    getPersistentNumber(char.unique_id, "WPN", function(number)
        sendCard(src, "weapon", {
            type          = "weapon",
            firstname     = char.firstname,
            lastname      = char.lastname,
            licenseNumber = number,
        })
    end)
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

    getPersistentNumber(char.unique_id, "LSPD", function(number)
        sendCard(src, "police", {
            type        = "police",
            firstname   = char.firstname,
            lastname    = char.lastname,
            badgeNumber = number,
            rank        = char.job_grade_label or char.job or "Officer",
        })
    end)
end)

-- ─────────────────────────────────────────────
-- EMS CARD
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:ems:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end

    if not isInJobs(char, Config.emsJobs) then return end

    getPersistentNumber(char.unique_id, "EMS", function(number)
        sendCard(src, "ems", {
            type      = "ems",
            firstname = char.firstname,
            lastname  = char.lastname,
            emsNumber = number,
        })
    end)
end)

-- ─────────────────────────────────────────────
-- CONTRÔLES POLICIERS [FIX-3]
-- Rate limiting : un contrôle par joueur cible toutes les 10s par officier
-- ─────────────────────────────────────────────

local policeCheckCooldowns = {}

local function canPoliceCheck(officerSrc, targetSid, checkType)
    local key = tostring(officerSrc) .. "_" .. tostring(targetSid) .. "_" .. checkType
    local now = GetGameTimer()
    if policeCheckCooldowns[key] and (now - policeCheckCooldowns[key]) < 10000 then
        return false
    end
    policeCheckCooldowns[key] = now
    return true
end

-- Nettoyage périodique des cooldowns (toutes les 5 minutes)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000)
        local now = GetGameTimer()
        for k, t in pairs(policeCheckCooldowns) do
            if (now - t) > 60000 then
                policeCheckCooldowns[k] = nil
            end
        end
    end
end)

local function getTargetChar(targetSid)
    local sid = tonumber(targetSid)
    if not sid then return nil, nil end
    if not isConnected(sid) then return nil, nil end
    local char = getCharacter(sid)
    return sid, char
end

RegisterNetEvent("idcard:police:checkIdentity", function(targetSid)
    local src     = source
    local officer = getCharacter(src)
    if not officer or not isInJobs(officer, Config.policeJobs) then return end

    if not canPoliceCheck(src, targetSid, "identity") then
        notify(src, "Veuillez patienter avant un nouveau contrôle.", "warning")
        return
    end

    local tid, target = getTargetChar(targetSid)
    if not tid or not target then
        notify(src, "Joueur introuvable.", "error")
        return
    end

    if officer.unique_id and target.unique_id then
        exports.oxmysql:execute(
            "INSERT INTO police_checks_log (officer_uid, target_uid, check_type) VALUES (?, ?, 'identity')",
            { officer.unique_id, target.unique_id }, nil
        )
    end

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

    if not canPoliceCheck(src, targetSid, "license") then
        notify(src, "Veuillez patienter avant un nouveau contrôle.", "warning")
        return
    end

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
                    { officer.unique_id, target.unique_id }, nil
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

    if not canPoliceCheck(src, targetSid, "badge") then
        notify(src, "Veuillez patienter avant un nouveau contrôle.", "warning")
        return
    end

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
            { officer.unique_id, target.unique_id }, nil
        )
    end

    getPersistentNumber(target.unique_id, "LSPD", function(number)
        sendCard(src, "police", {
            type        = "police",
            firstname   = target.firstname,
            lastname    = target.lastname,
            badgeNumber = number,
            rank        = target.job_grade_label or target.job or "Officer",
        })
    end)
end)

-- ─────────────────────────────────────────────
-- SHOW TO NEARBY [FIX-4]
-- Données correctes selon cardType + vérification item/job
-- ─────────────────────────────────────────────

-- Constructeurs de payload par type de carte
local function buildNearbyPayload(cardType, char, badgeNumber)
    if cardType == "identity" then
        return {
            type        = "identity",
            firstname   = char.firstname,
            lastname    = char.lastname,
            uniqueId    = char.unique_id,
            dateOfBirth = char.dateofbirth or char.dob or "—",
            nationality = "Française",
        }
    elseif cardType == "driver" then
        return {
            type          = "driver",
            firstname     = char.firstname,
            lastname      = char.lastname,
            licenseNumber = char.unique_id or "UNKNOWN",
            categories    = { "B" },
        }
    elseif cardType == "police" then
        return {
            type        = "police",
            firstname   = char.firstname,
            lastname    = char.lastname,
            badgeNumber = badgeNumber or "LSPD-0000",
            rank        = char.job_grade_label or char.job or "Officer",
        }
    else
        -- Fallback identity
        return {
            type        = "identity",
            firstname   = char.firstname,
            lastname    = char.lastname,
            uniqueId    = char.unique_id,
            dateOfBirth = char.dateofbirth or char.dob or "—",
            nationality = "Française",
        }
    end
end

RegisterNetEvent("idcard:showToNearby", function(cardType)
    local src  = source
    local char = getCharacter(src)
    if not char or not isConnected(src) then return end

    -- [FIX-4] Vérification : le joueur doit avoir le droit de montrer ce type
    if cardType == "police" then
        if not isInJobs(char, Config.policeJobs) then
            notify(src, "Vous n'avez pas de badge de police.", "error")
            return
        end
    elseif cardType == "identity" then
        if not hasItem(src, Config.items.identity) then
            notify(src, "Vous n'avez pas de carte d'identité.", "error")
            return
        end
    elseif cardType == "driver" then
        if not hasItem(src, Config.items.driver) then
            notify(src, "Vous n'avez pas de permis de conduire.", "error")
            return
        end
    end

    local srcCoords = GetEntityCoords(GetPlayerPed(src))
    local radius    = Config.showRadius or 5.0

    -- Pour la carte police, on récupère le numéro persistant
    if cardType == "police" then
        getPersistentNumber(char.unique_id, "LSPD", function(number)
            local payload = buildNearbyPayload(cardType, char, number)
            for _, playerId in ipairs(GetPlayers()) do
                local pid = tonumber(playerId)
                if pid and pid ~= src and isConnected(pid) then
                    local coords = GetEntityCoords(GetPlayerPed(pid))
                    if #(srcCoords - coords) <= radius then
                        TriggerClientEvent("idcard:show", pid, {
                            action   = "showCard",
                            cardType = cardType,
                            data     = payload,
                        })
                    end
                end
            end
        end)
    else
        local payload = buildNearbyPayload(cardType, char, nil)
        for _, playerId in ipairs(GetPlayers()) do
            local pid = tonumber(playerId)
            if pid and pid ~= src and isConnected(pid) then
                local coords = GetEntityCoords(GetPlayerPed(pid))
                if #(srcCoords - coords) <= radius then
                    TriggerClientEvent("idcard:show", pid, {
                        action   = "showCard",
                        cardType = cardType,
                        data     = payload,
                    })
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────
-- ÉVÉNEMENTS FERMÉS
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
    if not char then return end
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
    getPersistentNumber(char.unique_id, "WPN", function(number)
        sendCard(src, "weapon", {
            type          = "weapon",
            firstname     = char.firstname,
            lastname      = char.lastname,
            licenseNumber = number,
        })
    end)
end)

exports("UsePoliceCard", function(src)
    local char = getCharacter(src)
    if not char then return end
    if not isInJobs(char, Config.policeJobs) then return end
    getPersistentNumber(char.unique_id, "LSPD", function(number)
        sendCard(src, "police", {
            type        = "police",
            firstname   = char.firstname,
            lastname    = char.lastname,
            badgeNumber = number,
            rank        = char.job_grade_label or char.job or "Officer",
        })
    end)
end)

exports("UseEMSCard", function(src)
    local char = getCharacter(src)
    if not char then return end
    if not isInJobs(char, Config.emsJobs) then return end
    getPersistentNumber(char.unique_id, "EMS", function(number)
        sendCard(src, "ems", {
            type      = "ems",
            firstname = char.firstname,
            lastname  = char.lastname,
            emsNumber = number,
        })
    end)
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

log:info("kt_idcard_ui SERVER LOADED v3")
