-- server/main.lua
-- Système de carte d'identité — item identity_card dans kt_inventory.
-- Quand un joueur utilise l'item, sa carte est montrée à tous les joueurs
-- dans un rayon défini par Config.identity.showRadius.

Identity        = {}
Identity.logger = Logger:child("IDENTITY")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HELPER : récupère les coordonnées serveur d'un joueur
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function getPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HELPER : label lisible du job
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function getJobLabel(jobName)
    if not jobName or jobName == "unemployed" then
        return "Sans emploi"
    end
    -- Essaie de récupérer le label en DB (asynchrone non bloquant — optionnel)
    -- Si absent, on retourne le nom brut
    return jobName
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SHOW : affiche la carte à tous les joueurs proches
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Identity.show(src)
    local player = PlayerManager.get(src)
    if not player or not player.currentCharacter then
        Identity.logger:warn("show: personnage introuvable pour src=" .. tostring(src))
        return false
    end

    local char   = player.currentCharacter
    local coords = getPlayerCoords(src)
    if not coords then
        Identity.logger:warn("show: coords introuvables pour src=" .. tostring(src))
        return false
    end

    local radius = Config.identity and Config.identity.showRadius or 5.0

    -- Données envoyées à la NUI
    local payload = {
        action      = "showIdentity",
        firstname   = char.firstname,
        lastname    = char.lastname,
        dateofbirth = char.dateofbirth,
        unique_id   = char.unique_id,
        ped_model   = char.ped_model,
        job         = char.job,
        job_label   = getJobLabel(char.job),
    }

    -- Le joueur lui-même voit sa propre carte (sans "montré par")
    TriggerClientEvent("identity:show", src, payload)

    -- Les joueurs proches voient la carte avec "montré par"
    local nearbyPayload = {}
    for k, v in pairs(payload) do nearbyPayload[k] = v end
    nearbyPayload.shown_by = char.firstname .. " " .. char.lastname

    local shown = 0
    for _, p in pairs(PlayerManager.getAll()) do
        if p.source ~= src then
            local targetCoords = getPlayerCoords(p.source)
            if targetCoords then
                local dist = #(coords - targetCoords)
                if dist <= radius then
                    TriggerClientEvent("identity:show", p.source, nearbyPayload)
                    shown = shown + 1
                end
            end
        end
    end

    Identity.logger:info(
        ("Carte montrée par %s (%s) — %d joueur(s) proche(s)"):format(
            player.name,
            char.unique_id,
            shown
        )
    )

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NET EVENT : usage de l'item côté client
-- Déclenché par kt_inventory quand l'item est utilisé
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("identity:use", function()
    local src = source
    Identity.show(src)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NET EVENT : fermeture NUI (callback depuis le client)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("identity:closed", function()
    -- Rien à faire côté serveur — log optionnel
    Identity.logger:debug("NUI fermée par src=" .. tostring(source))
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EXPORT : permet à d'autres ressources d'afficher la carte
-- Exemple : exports["union"]:ShowIdentity(src)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
exports("ShowIdentity", function(src)
    return Identity.show(tonumber(src))
end)

return Identity
