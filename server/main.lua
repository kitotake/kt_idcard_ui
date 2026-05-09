-- server/main.lua
-- Module kt_idcard_ui v2
-- Features : carte d'identité + permis de conduire
-- Bridges  : union (GetCharacterState, Bank), kt_inventory (AddItem/GetItemCount), oxmysql

local log = Logger:child("IDCARD:SERVER")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HELPERS GÉNÉRAUX
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function isConnected(src)
    return GetPlayerEndpoint(src) ~= nil
end

local function getPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

-- Personnage actif via export Union statebag
local function getCharacter(src)
    local ok, char = pcall(function()
        return exports[Config.resources.union]:GetCharacterState(src)
    end)
    if ok and char then return char end
    log:warn("GetCharacterState introuvable src=" .. tostring(src))
    return nil
end

-- Label job via DB
local function getJobLabel(jobName, callback)
    if not jobName or jobName == "unemployed" then
        return callback("Sans emploi")
    end
    exports.oxmysql:scalar(
        "SELECT label FROM jobs WHERE name = ? LIMIT 1",
        { jobName },
        function(label) callback(label or jobName) end
    )
end

-- Notify client
local function notify(src, msg, nType)
    TriggerClientEvent("idcard:notify", src, msg, nType or "info")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HELPERS INVENTAIRE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function hasItem(src, itemName)
    local ok, count = pcall(function()
        return exports[Config.resources.inventory]:GetItemCount(src, itemName)
    end)
    return ok and count and count > 0
end

local function addItem(src, itemName)
    local ok, result = pcall(function()
        return exports[Config.resources.inventory]:AddItem(src, itemName, 1)
    end)
    return ok and result
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HELPERS DB LICENSES
-- Utilise la table user_licenses déjà dans union.sql
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Vérifie si un personnage a un type de permis en DB
local function hasLicense(uniqueId, licenseType, callback)
    exports.oxmysql:scalar(
        "SELECT COUNT(*) FROM user_licenses WHERE unique_id = ? AND type = ?",
        { uniqueId, licenseType },
        function(count)
            callback(count and count > 0)
        end
    )
end

-- Donne un permis en DB + item inventaire
local function grantLicense(src, uniqueId, identifier, licenseType, callback)
    local licCfg = Config.licenses.types[licenseType]
    if not licCfg then
        log:warn("grantLicense: type inconnu " .. tostring(licenseType))
        if callback then callback(false, "unknown_type") end
        return
    end

    hasLicense(uniqueId, licenseType, function(already)
        if already then
            if callback then callback(false, "already_have") end
            return
        end

        -- INSERT en DB
        exports.oxmysql:execute(
            "INSERT IGNORE INTO user_licenses (identifier, unique_id, type) VALUES (?, ?, ?)",
            { identifier, uniqueId, licenseType },
            function(result)
                if not result then
                    log:error("INSERT user_licenses échoué uid=" .. uniqueId)
                    if callback then callback(false, "db_error") end
                    return
                end

                -- Donne l'item kt_inventory
                addItem(src, licCfg.item)

                log:info(("Permis '%s' accordé à uid=%s"):format(licenseType, uniqueId))
                if callback then callback(true) end
            end
        )
    end)
end

-- Récupère tous les permis d'un personnage
local function getLicenses(uniqueId, callback)
    exports.oxmysql:fetch(
        "SELECT type FROM user_licenses WHERE unique_id = ?",
        { uniqueId },
        function(rows)
            local result = {}
            if rows then
                for _, row in ipairs(rows) do
                    result[row.type] = true
                end
            end
            callback(result)
        end
    )
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CARTE D'IDENTITÉ — SHOW
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function showIdentity(src)
    local char = getCharacter(src)
    if not char then return false end

    local coords = getPlayerCoords(src)
    if not coords then return false end

    getJobLabel(char.job, function(jobLabel)
        local payload = {
            action      = "showIdentity",
            firstname   = char.firstname,
            lastname    = char.lastname,
            dateofbirth = char.dateofbirth,
            unique_id   = char.unique_id,
            ped_model   = char.ped_model,
            job         = char.job,
            job_label   = jobLabel,
        }

        if isConnected(src) then
            TriggerClientEvent("idcard:show", src, payload)
        end

        local shownBy = (char.firstname or "") .. " " .. (char.lastname or "")
        local nearby  = {}
        for k, v in pairs(payload) do nearby[k] = v end
        nearby.shown_by = shownBy

        local count = 0
        for _, pid in ipairs(GetPlayers()) do
            pid = tonumber(pid)
            if pid ~= src then
                local tc = getPlayerCoords(pid)
                if tc and #(coords - tc) <= (Config.showRadius or 5.0) then
                    TriggerClientEvent("idcard:show", pid, nearby)
                    count = count + 1
                end
            end
        end

        log:info(("Carte de %s montrée — %d proche(s)"):format(shownBy, count))
    end)

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PERMIS — SHOW (affiche la liste des permis)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function showLicenses(src, targetSrc, callerName)
    -- targetSrc = joueur dont on affiche les permis
    -- callerName = nil si le joueur se montre lui-même, sinon nom du contrôleur
    local char = getCharacter(targetSrc)
    if not char then return false end

    getLicenses(char.unique_id, function(licenses)
        -- Construit la liste avec état (possédé / non possédé)
        local list = {}
        for licType, licCfg in pairs(Config.licenses.types) do
            list[#list + 1] = {
                type  = licType,
                label = licCfg.label,
                icon  = licCfg.icon,
                valid = licenses[licType] == true,
            }
        end

        local payload = {
            action      = "showLicenses",
            firstname   = char.firstname,
            lastname    = char.lastname,
            unique_id   = char.unique_id,
            licenses    = list,
            checked_by  = callerName,  -- nil = soi-même, sinon nom du policier
        }

        -- Si contrôle police : on l'envoie au policier, pas au conducteur
        local dest = callerName and src or targetSrc
        if isConnected(dest) then
            TriggerClientEvent("idcard:show", dest, payload)
        end

        log:info(("Permis de uid=%s affichés pour src=%d"):format(char.unique_id, dest))
    end)

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PERMIS — VÉRIFICATION + AMENDE
-- Appelé par le client quand il monte dans un véhicule
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNetEvent("idcard:license:check", function(licenseType)
    local src  = source
    local char = getCharacter(src)
    if not char then return end

    -- Vérifie si le type est dans notre config
    if not Config.licenses.types[licenseType] then return end

    hasLicense(char.unique_id, licenseType, function(valid)
        if valid then
            -- OK, rien à faire
            TriggerClientEvent("idcard:license:result", src, true, licenseType)
        else
            -- Pas de permis → amende
            local fine = Config.licenses.fine or 1500

            -- Prélève via Bank de Union
            exports.oxmysql:execute(
                "UPDATE bank_accounts SET balance = GREATEST(0, balance - ?) WHERE unique_id = ? AND type = 'personal'",
                { fine, char.unique_id },
                function(result)
                    local affected = type(result) == "table" and (result.affectedRows or 0) or (result or 0)
                    if affected and affected > 0 then
                        notify(src,
                            ("Conduite sans permis — Amende de $%d prélevée."):format(fine),
                            "error"
                        )
                        -- Log transaction Bank
                        exports.oxmysql:execute([[
                            INSERT INTO bank_transactions
                                (account_id, transaction_uuid, type, amount, balance_after, description)
                            SELECT id, ?, 'admin', ?, balance, ?
                            FROM bank_accounts
                            WHERE unique_id = ? AND type = 'personal'
                            LIMIT 1
                        ]], {
                            ("FINE_%d_%d"):format(src, os.time()),
                            fine,
                            "Amende conduite sans permis",
                            char.unique_id,
                        })
                    else
                        notify(src, "Conduite sans permis — solde insuffisant pour l'amende.", "warning")
                    end

                    TriggerClientEvent("idcard:license:result", src, false, licenseType)
                    log:info(("Amende $%d — uid=%s licenseType=%s"):format(fine, char.unique_id, licenseType))
                end
            )
        end
    end)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PNJ MAIRIE — GIVE CARTE D'IDENTITÉ
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNetEvent("idcard:npc:interact", function()
    local src  = source
    local char = getCharacter(src)
    if not char then
        notify(src, "Aucun personnage actif.", "error")
        return
    end

    if hasItem(src, Config.itemName) then
        notify(src, "Vous possédez déjà une carte d'identité.", "warning")
        return
    end

    if addItem(src, Config.itemName) then
        notify(src, "Votre carte d'identité a été émise.", "success")
    else
        notify(src, "Impossible d'émettre la carte. Réessayez.", "error")
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PNJ AUTO-ÉCOLE — MENU PERMIS
-- Le client envoie le type de permis choisi dans le menu
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNetEvent("idcard:driving:interact", function()
    local src  = source
    local char = getCharacter(src)
    if not char then
        notify(src, "Aucun personnage actif.", "error")
        return
    end

    -- Envoie la liste des permis disponibles + état actuel au client pour le menu
    getLicenses(char.unique_id, function(owned)
        local list = {}
        for licType, licCfg in pairs(Config.licenses.types) do
            list[#list + 1] = {
                type  = licType,
                label = licCfg.label,
                icon  = licCfg.icon,
                owned = owned[licType] == true,
            }
        end
        TriggerClientEvent("idcard:driving:openMenu", src, list)
    end)
end)

-- Joueur choisit un permis dans le menu → demande l'obtention
RegisterNetEvent("idcard:driving:requestLicense", function(licenseType)
    local src  = source
    local char = getCharacter(src)
    if not char then return end

    -- Sécurité : type valide ?
    if not Config.licenses.types[licenseType] then
        notify(src, "Type de permis invalide.", "error")
        return
    end

    -- Récupère l'identifier depuis union
    local ok, identifier = pcall(function()
        -- StateBag : le unique_id est dans le statebag, l'identifier vient du PlayerManager
        -- On le récupère via un export union ou directement depuis la DB
        return exports[Config.resources.union]:GetCharacterState(src)
    end)

    -- Fallback : récupère identifier depuis la DB via unique_id
    exports.oxmysql:scalar(
        "SELECT identifier FROM user_character WHERE unique_id = ? LIMIT 1",
        { char.unique_id },
        function(ident)
            if not ident then
                notify(src, "Erreur lors de l'obtention du permis.", "error")
                return
            end

            grantLicense(src, char.unique_id, ident, licenseType, function(success, reason)
                local licLabel = Config.licenses.types[licenseType].label
                if success then
                    notify(src,
                        ("Félicitations ! Vous avez obtenu le %s."):format(licLabel),
                        "success"
                    )
                elseif reason == "already_have" then
                    notify(src,
                        ("Vous possédez déjà le %s."):format(licLabel),
                        "warning"
                    )
                else
                    notify(src, "Erreur lors de l'obtention du permis.", "error")
                end
            end)
        end
    )
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CONTRÔLE POLICE — via kt_target sur un joueur
-- Le policier cible un joueur → affiche ses permis
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNetEvent("idcard:police:checkLicense", function(targetSrc)
    local src    = source
    local caller = getCharacter(src)
    if not caller then return end

    -- Vérif : le joueur est bien de la police
    local job = caller.job or "unemployed"
    if job ~= "police" then
        notify(src, "Vous n'êtes pas autorisé à effectuer un contrôle.", "error")
        return
    end

    targetSrc = tonumber(targetSrc)
    if not targetSrc or not isConnected(targetSrc) then
        notify(src, "Joueur introuvable.", "error")
        return
    end

    local callerName = (caller.firstname or "") .. " " .. (caller.lastname or "")
    showLicenses(src, targetSrc, callerName)
end)

-- Contrôle carte d'identité par la police
RegisterNetEvent("idcard:police:checkIdentity", function(targetSrc)
    local src    = source
    local caller = getCharacter(src)
    if not caller then return end

    if (caller.job or "unemployed") ~= "police" then
        notify(src, "Vous n'êtes pas autorisé à effectuer un contrôle.", "error")
        return
    end

    targetSrc = tonumber(targetSrc)
    if not targetSrc or not isConnected(targetSrc) then
        notify(src, "Joueur introuvable.", "error")
        return
    end

    local targetChar = getCharacter(targetSrc)
    if not targetChar then
        notify(src, "Ce joueur n'a pas de personnage actif.", "error")
        return
    end

    getJobLabel(targetChar.job, function(jobLabel)
        local callerName = (caller.firstname or "") .. " " .. (caller.lastname or "")
        local payload = {
            action      = "showIdentity",
            firstname   = targetChar.firstname,
            lastname    = targetChar.lastname,
            dateofbirth = targetChar.dateofbirth,
            unique_id   = targetChar.unique_id,
            ped_model   = targetChar.ped_model,
            job         = targetChar.job,
            job_label   = jobLabel,
            shown_by    = callerName,  -- "contrôlé par"
            is_police_check = true,
        }
        TriggerClientEvent("idcard:show", src, payload)
    end)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- USAGE ITEM CARTE — event + export
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNetEvent("idcard:use", function()
    showIdentity(source)
end)

exports("UseIdentityCard", function(src)
    showIdentity(tonumber(src))
end)

-- Usage item permis (affiche ses propres permis)
RegisterNetEvent("idcard:license:use", function()
    local src = source
    showLicenses(src, src, nil)
end)

exports("UseLicenseCard", function(src)
    src = tonumber(src)
    showLicenses(src, src, nil)
end)

-- Fermeture NUI
RegisterNetEvent("idcard:closed", function()
    log:debug("NUI fermée src=" .. tostring(source))
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMMANDES ADMIN
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- /giveid <id> — donne la carte d'identité
RegisterCommand("giveid", function(src, args)
    local targetId = tonumber(args[1])
    if not targetId then
        local m = "Usage: giveid <server_id>"
        if src == 0 then print("[IDCARD] " .. m) else notify(src, m, "error") end
        return
    end

    if not isConnected(targetId) then
        local m = "Joueur introuvable."
        if src == 0 then print("[IDCARD] " .. m) else notify(src, m, "error") end
        return
    end

    if addItem(targetId, Config.itemName) then
        local m = ("Carte d'identité donnée au joueur %d."):format(targetId)
        if src == 0 then print("[IDCARD] " .. m) else notify(src, m, "success") end
        notify(targetId, "Une carte d'identité vous a été attribuée.", "success")
    else
        local m = "Échec AddItem."
        if src == 0 then print("[IDCARD] " .. m) else notify(src, m, "error") end
    end
end, true)

-- /givepermis <id> <type> — donne un permis
RegisterCommand("givepermis", function(src, args)
    local targetId   = tonumber(args[1])
    local licType    = args[2]

    if not targetId or not licType then
        local types = {}
        for t in pairs(Config.licenses.types) do types[#types+1] = t end
        local m = "Usage: givepermis <id> <" .. table.concat(types, "|") .. ">"
        if src == 0 then print("[IDCARD] " .. m) else notify(src, m, "error") end
        return
    end

    if not Config.licenses.types[licType] then
        local m = "Type de permis inconnu : " .. licType
        if src == 0 then print("[IDCARD] " .. m) else notify(src, m, "error") end
        return
    end

    if not isConnected(targetId) then
        local m = "Joueur introuvable."
        if src == 0 then print("[IDCARD] " .. m) else notify(src, m, "error") end
        return
    end

    local char = getCharacter(targetId)
    if not char then
        local m = "Personnage introuvable pour ce joueur."
        if src == 0 then print("[IDCARD] " .. m) else notify(src, m, "error") end
        return
    end

    exports.oxmysql:scalar(
        "SELECT identifier FROM user_character WHERE unique_id = ? LIMIT 1",
        { char.unique_id },
        function(ident)
            if not ident then return end
            grantLicense(targetId, char.unique_id, ident, licType, function(success, reason)
                local licLabel = Config.licenses.types[licType].label
                local m = success
                    and ("%s donné au joueur %d."):format(licLabel, targetId)
                    or  ("Échec : %s"):format(tostring(reason))
                if src == 0 then print("[IDCARD] " .. m) else notify(src, m, success and "success" or "error") end
                if success then
                    notify(targetId, ("Vous avez obtenu le %s."):format(licLabel), "success")
                end
            end)
        end
    )
end, true)

log:info("Module kt_idcard_ui v2 serveur chargé")