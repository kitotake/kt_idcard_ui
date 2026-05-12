-- server/main.lua
-- kt_idcard_ui v3 — serveur
-- Gestion de 9 types de cartes

local log = Logger:child("IDCARD:SERVER")

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function isConnected(src)
    return GetPlayerEndpoint(src) ~= nil
end

local function getPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function getCharacter(src)
    local ok, char = pcall(function()
        return exports[Config.resources.union]:GetCharacterState(src)
    end)
    if ok and char then return char end
    return nil
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

local function getJobLabel(jobName, cb)
    if not jobName or jobName == "unemployed" then return cb("Sans emploi") end
    exports.oxmysql:scalar(
        "SELECT label FROM jobs WHERE name = ? LIMIT 1",
        { jobName }, function(label) cb(label or jobName) end
    )
end

-- Check job membership
local function isInJobs(char, jobList)
    if not char then return false end
    for _, j in ipairs(jobList) do
        if char.job == j then return true end
    end
    return false
end

-- ─── DB helpers ──────────────────────────────────────────────────────────────

local function getLicenses(uniqueId, cb)
    exports.oxmysql:fetch(
        "SELECT type FROM user_licenses WHERE unique_id = ?",
        { uniqueId }, function(rows)
            local r = {}
            if rows then for _, row in ipairs(rows) do r[row.type] = true end end
            cb(r)
        end
    )
end

local function grantLicense(src, uniqueId, ident, licType, cb)
    exports.oxmysql:scalar(
        "SELECT COUNT(*) FROM user_licenses WHERE unique_id = ? AND type = ?",
        { uniqueId, licType }, function(count)
            if count and count > 0 then
                if cb then cb(false, "already_have") end
                return
            end
            exports.oxmysql:execute(
                "INSERT IGNORE INTO user_licenses (identifier, unique_id, type) VALUES (?, ?, ?)",
                { ident, uniqueId, licType }, function(result)
                    if result then
                        addItem(src, "license_drive")
                        if cb then cb(true) end
                    else
                        if cb then cb(false, "db_error") end
                    end
                end
            )
        end
    )
end

-- Build expiry date (n years from now)
local function buildExpiry(years)
    local d = os.date("*t")
    d.year = d.year + years
    return ("%02d/%02d/%04d"):format(d.day, d.month, d.year)
end

local function buildIssued()
    local d = os.date("*t")
    return ("%02d/%02d/%04d"):format(d.day, d.month, d.year)
end

-- ─── SEND CARD helper ────────────────────────────────────────────────────────

local function sendCard(src, cardType, data)
    if not isConnected(src) then return end
    TriggerClientEvent("idcard:show", src, {
        action   = "showCard",
        cardType = cardType,
        data     = data,
    })
end

-- ─── 1. CARTE D'IDENTITÉ ──────────────────────────────────────────────────────

local function showIdentity(src, targetChar, callerName, isPolice)
    getJobLabel(targetChar.job, function(jobLabel)
        local data = {
            type        = "identity",
            firstname   = targetChar.firstname,
            lastname    = targetChar.lastname,
            gender      = (targetChar.ped_model == "mp_f_freemode_01") and "F" or "M",
            dateOfBirth = targetChar.dateofbirth or "—",
            height      = targetChar.height and (targetChar.height .. " cm") or "178 cm",
            nationality = "Française",
            uniqueId    = targetChar.unique_id,
            issued      = buildIssued(),
            expiry      = buildExpiry(10),
            signature   = targetChar.firstname:sub(1,1) .. ". " .. targetChar.lastname,
            shown_by    = callerName,
            is_police_check = isPolice,
        }
        sendCard(src, "identity", data)
    end)
end

-- ─── 2. PERMIS DE CONDUIRE ────────────────────────────────────────────────────

local function showLicense(src, targetChar, callerName)
    getLicenses(targetChar.unique_id, function(licenses)
        local cats = {}
        if licenses["A"] or licenses["drive_bike"]  then cats[#cats+1] = "A" end
        if licenses["B"] or licenses["drive"]       then cats[#cats+1] = "B" end
        if licenses["C"] or licenses["drive_truck"] then cats[#cats+1] = "C" end
        if #cats == 0 then cats = { "—" } end

        local data = {
            type          = "driver",
            firstname     = targetChar.firstname,
            lastname      = targetChar.lastname,
            licenseNumber = ("FR-%03d-%d-%05d"):format(math.random(0,999), os.date("*t").year, math.random(0,99999)),
            categories    = cats,
            points        = math.random(6, 12),
            maxPoints     = 12,
            issued        = buildIssued(),
            expiry        = buildExpiry(10),
            signature     = targetChar.firstname:sub(1,1) .. ". " .. targetChar.lastname,
            checked_by    = callerName,
        }
        sendCard(src, "driver", data)
    end)
end

-- ─── Item usage callbacks ─────────────────────────────────────────────────────

RegisterNetEvent("idcard:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    showIdentity(src, char, nil, false)
end)

RegisterNetEvent("idcard:license:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    showLicense(src, char, nil)
end)

RegisterNetEvent("idcard:weapon:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    local data = {
        type              = "weapon",
        firstname         = char.firstname,
        lastname          = char.lastname,
        licenseNumber     = ("WPN-%04d-%d-FR"):format(math.random(0,9999), os.date("*t").year),
        authorizationType = "Port & Détention",
        accessLevel       = math.random(1, 3),
        legalStatus       = "VALID",
        allowedWeapons    = { "Pistolet semi-auto" },
        issued            = buildIssued(),
        expiry            = buildExpiry(3),
        signature         = char.firstname:sub(1,1) .. ". " .. char.lastname,
    }
    sendCard(src, "weapon", data)
end)

RegisterNetEvent("idcard:police:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    if not isInJobs(char, Config.policeJobs) then
        notify(src, "Vous n'êtes pas policier.", "error")
        return
    end
    getJobLabel(char.job, function(jobLabel)
        local data = {
            type           = "police",
            firstname      = char.firstname,
            lastname       = char.lastname,
            badgeNumber    = ("LSPD-%04d"):format(math.random(1000, 9999)),
            rank           = jobLabel,
            department     = "Los Santos Police Dept.",
            service        = char.jobGrade or "Patrol",
            accessLevel    = math.random(2, 4),
            authorizations = { "Arrestation", "Perquisition", "Usage de force", "Accès fichiers" },
            status         = "ACTIVE",
            issued         = buildIssued(),
            expiry         = buildExpiry(4),
            signature      = char.firstname:sub(1,1) .. ". " .. char.lastname,
        }
        sendCard(src, "police", data)
    end)
end)

RegisterNetEvent("idcard:ems:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    if not isInJobs(char, Config.emsJobs) then
        notify(src, "Vous n'êtes pas EMS.", "error")
        return
    end
    getJobLabel(char.job, function(jobLabel)
        local data = {
            type                 = "ems",
            firstname            = char.firstname,
            lastname             = char.lastname,
            emsNumber            = ("EMS-LS-%04d"):format(math.random(0, 9999)),
            medicalRank          = jobLabel,
            department           = "SAMU Los Santos",
            bloodGroup           = ({"A+","A-","B+","B-","O+","O-","AB+","AB-"})[math.random(1,8)],
            medicalAuthorizations = { "Triage", "Défibrillation", "Prescriptions" },
            status               = "ACTIVE",
            issued               = buildIssued(),
            expiry               = buildExpiry(2),
            signature            = char.firstname:sub(1,1) .. ". " .. char.lastname,
        }
        sendCard(src, "ems", data)
    end)
end)

RegisterNetEvent("idcard:mairie:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    getJobLabel(char.job, function(jobLabel)
        local data = {
            type              = "mairie",
            firstname         = char.firstname,
            lastname          = char.lastname,
            function_         = jobLabel,
            employeeId        = ("MRE-%d-%04d"):format(os.date("*t").year, math.random(0,9999)),
            officialSignature = "Mairie de Los Santos",
            issued            = buildIssued(),
            expiry            = buildExpiry(3),
            signature         = char.firstname:sub(1,1) .. ". " .. char.lastname,
        }
        -- Note: 'function' is a reserved word in Lua, use 'function_' in table then rename
        data["function"] = data.function_ ; data.function_ = nil
        sendCard(src, "mairie", data)
    end)
end)

RegisterNetEvent("idcard:gov:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    if not isInJobs(char, Config.govJobs) then
        notify(src, "Vous n'êtes pas membre du gouvernement.", "error")
        return
    end
    getJobLabel(char.job, function(jobLabel)
        local data = {
            type                   = "government",
            firstname              = char.firstname,
            lastname               = char.lastname,
            ["function"]           = jobLabel,
            govId                  = ("GOV-FR-%04d-ALPHA"):format(math.random(0,9999)),
            securityLevel          = 4,
            nationalDepartment     = "Gouvernement de l'État",
            specialAuthorizations  = { "Accès classifié", "Zone restreinte" },
            issued                 = buildIssued(),
            expiry                 = buildExpiry(5),
            signature              = char.firstname:sub(1,1) .. ". " .. char.lastname,
        }
        sendCard(src, "government", data)
    end)
end)

RegisterNetEvent("idcard:passport:use", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    local pNum = ("FRP%07d"):format(math.random(1000000, 9999999))
    local fn = (char.firstname or ""):gsub("[^A-Z]", "<"):upper()
    local ln = (char.lastname  or ""):gsub("[^A-Z]", "<"):upper()
    local data = {
        type           = "passport",
        firstname      = char.firstname,
        lastname       = char.lastname,
        nationality    = "Française",
        dateOfBirth    = char.dateofbirth or "01/01/1990",
        gender         = (char.ped_model == "mp_f_freemode_01") and "F" or "M",
        passportNumber = pNum,
        issuingCountry = "FRANCE",
        mrz            = ("P<FRA" .. ln .. "<<" .. fn .. "<<<<<<<<<<<"):sub(1,44) .. "\n" ..
                          pNum .. "2FRA900101M300101<<<<<<<<<4",
        issued         = buildIssued(),
        expiry         = buildExpiry(10),
        signature      = char.firstname:sub(1,1) .. ". " .. char.lastname,
    }
    sendCard(src, "passport", data)
end)

-- ─── Police check events ──────────────────────────────────────────────────────

RegisterNetEvent("idcard:police:checkIdentity", function(targetSrc)
    local src    = source
    local caller = getCharacter(src)
    if not caller then return end
    if not isInJobs(caller, Config.policeJobs) then
        notify(src, "Non autorisé.", "error") ; return
    end
    targetSrc = tonumber(targetSrc)
    if not targetSrc or not isConnected(targetSrc) then
        notify(src, "Joueur introuvable.", "error") ; return
    end
    local targetChar = getCharacter(targetSrc)
    if not targetChar then return end
    local callerName = caller.firstname .. " " .. caller.lastname
    showIdentity(src, targetChar, callerName, true)
end)

RegisterNetEvent("idcard:police:checkLicense", function(targetSrc)
    local src    = source
    local caller = getCharacter(src)
    if not caller then return end
    if not isInJobs(caller, Config.policeJobs) then
        notify(src, "Non autorisé.", "error") ; return
    end
    targetSrc = tonumber(targetSrc)
    if not targetSrc or not isConnected(targetSrc) then
        notify(src, "Joueur introuvable.", "error") ; return
    end
    local targetChar = getCharacter(targetSrc)
    if not targetChar then return end
    local callerName = caller.firstname .. " " .. caller.lastname
    showLicense(src, targetChar, callerName)
end)

RegisterNetEvent("idcard:police:checkBadge", function(targetSrc)
    local src    = source
    local caller = getCharacter(src)
    if not caller then return end
    if not isInJobs(caller, Config.policeJobs) then return end
    targetSrc = tonumber(targetSrc)
    if not targetSrc or not isConnected(targetSrc) then return end
    local targetChar = getCharacter(targetSrc)
    if not targetChar then return end
    if not isInJobs(targetChar, Config.policeJobs) then
        notify(src, "Ce joueur n'est pas policier.", "warning") ; return
    end
    getJobLabel(targetChar.job, function(jobLabel)
        local data = {
            type           = "police",
            firstname      = targetChar.firstname,
            lastname       = targetChar.lastname,
            badgeNumber    = ("LSPD-%04d"):format(math.random(1000,9999)),
            rank           = jobLabel,
            department     = "Los Santos Police Dept.",
            service        = "Patrol",
            accessLevel    = 2,
            authorizations = { "Arrestation", "Patrouille" },
            status         = "ACTIVE",
            issued         = buildIssued(),
            expiry         = buildExpiry(4),
            signature      = targetChar.firstname:sub(1,1) .. ". " .. targetChar.lastname,
        }
        sendCard(src, "police", data)
    end)
end)

-- ─── License check (en véhicule) ─────────────────────────────────────────────

RegisterNetEvent("idcard:license:check", function(licType)
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    exports.oxmysql:scalar(
        "SELECT COUNT(*) FROM user_licenses WHERE unique_id = ? AND type IN (?,?)",
        { char.unique_id, licType, "drive" },
        function(count)
            if not (count and count > 0) then
                local fine = Config.licenses.fine or 1500
                exports.oxmysql:execute(
                    "UPDATE bank_accounts SET balance = GREATEST(0, balance - ?) WHERE unique_id = ? AND type = 'personal'",
                    { fine, char.unique_id }, function(r)
                        local affected = type(r) == "table" and (r.affectedRows or 0) or (r or 0)
                        if affected and affected > 0 then
                            notify(src, ("Conduite sans permis — Amende $%d"):format(fine), "error")
                        end
                    end
                )
            end
        end
    )
end)

-- ─── NPC mairie → donne carte d'identité ─────────────────────────────────────

RegisterNetEvent("idcard:npc:interact", function()
    local src  = source
    local char = getCharacter(src)
    if not char then notify(src, "Aucun personnage actif.", "error") ; return end
    if hasItem(src, Config.items.identity) then
        notify(src, "Vous possédez déjà une carte d'identité.", "warning") ; return
    end
    if addItem(src, Config.items.identity) then
        notify(src, "Carte d'identité émise.", "success")
    else
        notify(src, "Erreur lors de l'émission.", "error")
    end
end)

-- ─── NPC auto-école → affiche menu permis ────────────────────────────────────

RegisterNetEvent("idcard:driving:interact", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    if not hasItem(src, Config.items.identity) then
        notify(src, "Vous devez d'abord obtenir une carte d'identité.", "warning") ; return
    end
    getLicenses(char.unique_id, function(owned)
        local list = {
            { type = "A", label = "Permis A — Moto",        owned = owned["A"] or owned["drive_bike"]  },
            { type = "B", label = "Permis B — Voiture",     owned = owned["B"] or owned["drive"]       },
            { type = "C", label = "Permis C — Poids lourd", owned = owned["C"] or owned["drive_truck"] },
        }
        TriggerClientEvent("idcard:driving:openMenu", src, list)
    end)
end)

RegisterNetEvent("idcard:driving:requestLicense", function(licType)
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    exports.oxmysql:scalar(
        "SELECT identifier FROM user_character WHERE unique_id = ? LIMIT 1",
        { char.unique_id }, function(ident)
            if not ident then notify(src, "Erreur.", "error") ; return end
            grantLicense(src, char.unique_id, ident, licType, function(ok, reason)
                if ok then
                    notify(src, ("Permis %s obtenu !"):format(licType), "success")
                elseif reason == "already_have" then
                    notify(src, "Vous possédez déjà ce permis.", "warning")
                else
                    notify(src, "Erreur lors de l'obtention.", "error")
                end
            end)
        end
    )
end)

-- ─── Exports publics ──────────────────────────────────────────────────────────

exports("ShowCard", function(src, cardType, data)
    sendCard(tonumber(src), cardType, data)
end)

exports("UseIdentityCard", function(src)
    local char = getCharacter(tonumber(src))
    if char then showIdentity(tonumber(src), char, nil, false) end
end)

exports("UseLicenseCard", function(src)
    local char = getCharacter(tonumber(src))
    if char then showLicense(tonumber(src), char, nil) end
end)

exports("UseWeaponCard", function(src)
    TriggerEvent("idcard:weapon:use", tonumber(src))
end)

exports("UsePoliceCard", function(src)
    TriggerEvent("idcard:police:use", tonumber(src))
end)

exports("UseEMSCard", function(src)
    TriggerEvent("idcard:ems:use", tonumber(src))
end)

exports("UsePassport", function(src)
    TriggerEvent("idcard:passport:use", tonumber(src))
end)

-- ─── NUI closed ──────────────────────────────────────────────────────────────

RegisterCommand("showbankcard", function()
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    local data = {
        type       = "bank",
        firstname  = char.firstname,
        lastname   = char.lastname,
        cardNumber = ("4000 %04d %04d %04d"):format(math.random(0,9999), math.random(0,9999), math.random(0,9999)),
        expiry     = ("%02d/%02d"):format(math.random(1,12), os.date("*t").year + math.random(2,5)),
        bankName   = "Union Bank",
        signature  = char.firstname:sub(1,1) .. ". " .. char.lastname,
    }
    sendCard(src, "bank", data)

end)


RegisterNetEvent("idcard:closed", function()
   log:debug("NUI fermée src=" .. tostring(source))
end)

log:info("kt_idcard_ui serveur chargé — 9 types de cartes")
