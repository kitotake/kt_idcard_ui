-- server/main.lua
-- Module kt_idcard_ui — serveur
-- Bridges : union (GetCharacterState, GetJobState), kt_inventory (AddItem, GetItemCount), oxmysql
--
-- Flux :
--   PNJ spawné côté client
--   → kt_interact déclenche idcard:npc:interact
--   → serveur vérifie si le joueur a déjà la carte
--   → donne l'item via kt_inventory si absent
--   Usage item → idcard:use (event) ou UseIdentityCard (export)
--   → NUI diffusée à tous les joueurs proches

local log = Logger:child("IDCARD:SERVER")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function isConnected(src)
    return GetPlayerEndpoint(src) ~= nil
end

local function getPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

-- Récupère le personnage actif depuis Union via export statebag
local function getCharacter(src)
    local ok, char = pcall(function()
        return exports[Config.resources.union]:GetCharacterState(src)
    end)
    if ok and char then return char end
    log:warn("GetCharacterState introuvable pour src=" .. tostring(src))
    return nil
end

-- Label lisible du job via oxmysql (async)
local function getJobLabel(jobName, callback)
    if not jobName or jobName == "unemployed" then
        return callback("Sans emploi")
    end
    exports.oxmysql:scalar(
        "SELECT label FROM jobs WHERE name = ? LIMIT 1",
        { jobName },
        function(label)
            callback(label or jobName)
        end
    )
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SHOW : diffuse la NUI à tous les joueurs proches
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function showIdentity(src)
    local char = getCharacter(src)
    if not char then
        log:warn("showIdentity: personnage introuvable src=" .. tostring(src))
        return false
    end

    local coords = getPlayerCoords(src)
    if not coords then return false end

    local radius = Config.showRadius or 5.0

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

        -- Propriétaire — voit sa propre carte sans "montré par"
        if isConnected(src) then
            TriggerClientEvent("idcard:show", src, payload)
        end

        -- Joueurs proches — voient la carte avec "montré par"
        local shownByName = (char.firstname or "") .. " " .. (char.lastname or "")
        local nearby = {}
        for k, v in pairs(payload) do nearby[k] = v end
        nearby.shown_by = shownByName

        local count = 0
        for _, playerId in ipairs(GetPlayers()) do
            local pid = tonumber(playerId)
            if pid ~= src then
                local targetCoords = getPlayerCoords(pid)
                if targetCoords and #(coords - targetCoords) <= radius then
                    TriggerClientEvent("idcard:show", pid, nearby)
                    count = count + 1
                end
            end
        end

        log:info(("Carte de %s montrée — %d joueur(s) proche(s)"):format(shownByName, count))
    end)

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- GIVE CARD : donne l'item identity_card via kt_inventory
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function giveIdentityCard(src, callback)
    local itemName = Config.itemName or "identity_card"

    -- Vérif possession via export kt_inventory
    local hasCard = false
    local okCount, count = pcall(function()
        return exports[Config.resources.inventory]:GetItemCount(src, itemName)
    end)
    if okCount and count and count > 0 then hasCard = true end

    if hasCard then
        log:info("src=" .. tostring(src) .. " possède déjà la carte")
        if callback then callback(false, "already_have") end
        return
    end

    -- Ajout item via export kt_inventory
    local okGive, result = pcall(function()
        return exports[Config.resources.inventory]:AddItem(src, itemName, 1)
    end)

    if okGive and result then
        log:info("Carte donnée à src=" .. tostring(src))
        if callback then callback(true) end
    else
        log:error("AddItem échoué src=" .. tostring(src) .. " err=" .. tostring(result))
        if callback then callback(false, "give_failed") end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NET EVENTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Interaction PNJ → kt_interact déclenche cet event côté client,
-- qui le transmet au serveur via TriggerServerEvent
RegisterNetEvent("idcard:npc:interact", function()
    local src  = source
    local char = getCharacter(src)

    if not char then
        TriggerClientEvent("idcard:notify", src, "Aucun personnage actif.", "error")
        return
    end

    giveIdentityCard(src, function(success, reason)
        if success then
            TriggerClientEvent("idcard:notify", src,
                "Votre carte d'identité a été émise.", "success")
        elseif reason == "already_have" then
            TriggerClientEvent("idcard:notify", src,
                "Vous possédez déjà une carte d'identité.", "warning")
        else
            TriggerClientEvent("idcard:notify", src,
                "Impossible d'émettre la carte. Réessayez.", "error")
        end
    end)
end)

-- Usage item via EVENT (kt_inventory event-based)
-- Dans config kt_inventory : server = { event = "idcard:use" }
RegisterNetEvent("idcard:use", function()
    showIdentity(source)
end)

-- Fermeture NUI
RegisterNetEvent("idcard:closed", function()
    log:debug("NUI fermée par src=" .. tostring(source))
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EXPORTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Usage item via EXPORT (kt_inventory export-based)
-- Dans config kt_inventory : server = { export = "kt_idcard_ui.UseIdentityCard" }
exports("UseIdentityCard", function(src)
    showIdentity(tonumber(src))
end)

-- Affichage externe depuis n'importe quelle ressource
-- exports["kt_idcard_ui"]:ShowIdentity(src)
exports("ShowIdentity", function(src)
    return showIdentity(tonumber(src))
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMMANDE ADMIN : /giveid <id>
-- Console ou ACE admin uniquement (true = restricted)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterCommand("giveid", function(src, args)
    local targetId = tonumber(args[1])
    if not targetId then
        local msg = "Usage: giveid <server_id>"
        if src == 0 then print("[IDCARD] " .. msg) else
            TriggerClientEvent("idcard:notify", src, msg, "error")
        end
        return
    end

    if not isConnected(targetId) then
        local msg = "Joueur " .. targetId .. " introuvable."
        if src == 0 then print("[IDCARD] " .. msg) else
            TriggerClientEvent("idcard:notify", src, msg, "error")
        end
        return
    end

    giveIdentityCard(targetId, function(success, reason)
        local msg = success
            and ("Carte donnée au joueur %d."):format(targetId)
            or  ("Échec pour joueur %d : %s"):format(targetId, tostring(reason))
        if src == 0 then
            print("[IDCARD] " .. msg)
        else
            TriggerClientEvent("idcard:notify", src, msg, success and "success" or "error")
        end
    end)
end, true)

log:info("Module kt_idcard_ui serveur chargé")