-- client/main.lua
-- Module kt_idcard_ui — client
-- Bridges : kt_lib (Logger, lib.notify), kt_interact (zone d'interaction PNJ)
--
-- Flux :
--   Au spawn du joueur → spawn du PNJ fonctionnaire
--   → enregistrement zone kt_interact autour du PNJ
--   → interaction → TriggerServerEvent("idcard:npc:interact")
--   Réception idcard:show → NUI affichée
--   Touche E → fermeture NUI

local log    = Logger:child("IDCARD:CLIENT")
local npcPed = nil       -- handle du PNJ spawné localement
local nuiOpen = false    -- état NUI

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function notify(msg, nType)
    lib.notify({ description = tostring(msg), type = nType or "info", duration = 4000 })
end

local function loadModel(hash)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) do
        Wait(50)
        if GetGameTimer() - t > 8000 then
            log:error("Timeout chargement modèle PNJ")
            return false
        end
    end
    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SPAWN DU PNJ FONCTIONNAIRE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function spawnNPC()
    if npcPed and DoesEntityExist(npcPed) then return end  -- déjà spawné

    local npcCfg = Config.npc
    local hash   = GetHashKey(npcCfg.model)

    if not loadModel(hash) then return end

    local c = npcCfg.coords
    npcPed  = CreatePed(4, hash, c.x, c.y, c.z - 1.0, npcCfg.heading, false, false)

    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(npcPed) then
        log:error("Impossible de créer le PNJ fonctionnaire")
        npcPed = nil
        return
    end

    -- Comportement statique
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    FreezeEntityPosition(npcPed, true)
    SetEntityVisible(npcPed, true, false)

    -- Animation assise ou debout au comptoir (optionnel)
    -- TaskStartScenarioInPlace(npcPed, "WORLD_HUMAN_CLIPBOARD", 0, true)

    log:info("PNJ fonctionnaire spawné")

    -- ── Enregistrement interaction kt_interact ──────────────────────
    -- kt_interact attend un event "client" ou "server" selon la config
    -- Ici on utilise un event client qui retransmet au serveur
    local interactCfg = npcCfg.interact

    -- Vérifie que kt_interact est disponible
    if GetResourceState("kt_interact") ~= "started" then
        log:warn("kt_interact non disponible — interaction PNJ désactivée")
        return
    end

    -- Enregistre une zone autour du PNJ
    -- kt_interact attend : id, type, label, icon, distance, coords, event_type, event_name
    exports["kt_interact"]:AddTargetEntity(npcPed, {
        options = {
            {
                label      = interactCfg.label,
                icon       = interactCfg.icon,
                distance   = interactCfg.distance,
                event      = "idcard:npc:clientInteract",  -- event client local
                -- ou directement server si kt_interact le supporte :
                -- serverEvent = "idcard:npc:interact",
            }
        }
    })

    log:info("Zone kt_interact enregistrée sur le PNJ")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- INTERACTION PNJ (event local → serveur)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

AddEventHandler("idcard:npc:clientInteract", function()
    TriggerServerEvent("idcard:npc:interact")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NETTOYAGE DU PNJ
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function removeNPC()
    if npcPed and DoesEntityExist(npcPed) then
        -- Retire la zone kt_interact avant de supprimer l'entité
        if GetResourceState("kt_interact") == "started" then
            pcall(function()
                exports["kt_interact"]:RemoveTargetEntity(npcPed)
            end)
        end
        SetEntityAsMissionEntity(npcPed, false, true)
        DeleteEntity(npcPed)
        npcPed = nil
        log:info("PNJ fonctionnaire supprimé")
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SPAWN AU CHARGEMENT DU PERSONNAGE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Union envoie union:player:spawned quand le personnage est prêt
RegisterNetEvent("union:player:spawned", function()
    Wait(500)  -- petit délai pour laisser le monde charger
    spawnNPC()
end)

-- Si kt_interact redémarre après union, on re-spawne le PNJ
AddEventHandler("onResourceStart", function(r)
    if r == "kt_interact" and npcPed and DoesEntityExist(npcPed) then
        -- Re-register l'interaction sur le PNJ existant
        Wait(300)
        local interactCfg = Config.npc.interact
        exports["kt_interact"]:AddTargetEntity(npcPed, {
            options = {
                {
                    label    = interactCfg.label,
                    icon     = interactCfg.icon,
                    distance = interactCfg.distance,
                    event    = "idcard:npc:clientInteract",
                }
            }
        })
        log:info("kt_interact redémarré — zone re-enregistrée")
    end
end)

-- Si kt_interact s'arrête, on loggue seulement
AddEventHandler("onResourceStop", function(r)
    if r == "kt_interact" then
        log:warn("kt_interact arrêté — interaction PNJ suspendue")
    end
end)

-- Nettoyage si le personnage est déchargé
AddEventHandler("union:character:unloaded", function()
    removeNPC()
    if nuiOpen then
        nuiOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "hideIdentity" })
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NUI — AFFICHAGE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNetEvent("idcard:show", function(data)
    if not data then return end
    nuiOpen = true
    SetNuiFocus(true, false)   -- capture touche E sans capturer la souris
    SendNUIMessage(data)
    log:info("Carte affichée")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NUI — FERMETURE (callback HTML touche E)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNUICallback("idcard:close", function(_, cb)
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hideIdentity" })
    TriggerServerEvent("idcard:closed")
    log:info("Carte fermée")
    cb({ ok = true })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NOTIFICATIONS depuis le serveur
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNetEvent("idcard:notify", function(msg, nType)
    notify(msg, nType)
end)

log:info("Module kt_idcard_ui client chargé")