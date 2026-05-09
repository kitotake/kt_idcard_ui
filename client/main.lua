-- client/main.lua
-- Module kt_idcard_ui v2 — client
-- Features : carte d'identité + permis (menu, vérif conduite, contrôle police)

local log     = Logger:child("IDCARD:CLIENT")
local nuiOpen = false
local npcId   = nil        -- handle PNJ mairie
local npcDrivingId = nil   -- handle PNJ auto-école

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
            log:error("Timeout modèle PNJ")
            return false
        end
    end
    return true
end

local function isInteractAvailable()
    return GetResourceState(Config.resources.interact) == "started"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SPAWN PNJ GÉNÉRIQUE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function spawnPed(cfg, interactEvent)
    local hash = GetHashKey(cfg.model)
    if not loadModel(hash) then return nil end

    local c   = cfg.coords
    local ped = CreatePed(4, hash, c.x, c.y, c.z - 1.0, cfg.heading, false, false)
    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(ped) then
        log:error("CreatePed échoué — " .. cfg.model)
        return nil
    end

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)

    -- Enregistrement interaction kt_interact
    if isInteractAvailable() then
        local ok, err = pcall(function()
            exports[Config.resources.interact]:AddTargetEntity(ped, {
                options = {
                    {
                        label    = cfg.interact.label,
                        icon     = cfg.interact.icon,
                        distance = cfg.interact.distance,
                        event    = interactEvent,
                    }
                }
            })
        end)
        if not ok then log:warn("AddTargetEntity échoué : " .. tostring(err)) end
    else
        log:warn("kt_interact non disponible — interaction désactivée")
    end

    return ped
end

local function removePed(ped)
    if not ped or not DoesEntityExist(ped) then return end
    if isInteractAvailable() then
        pcall(function()
            exports[Config.resources.interact]:RemoveTargetEntity(ped)
        end)
    end
    SetEntityAsMissionEntity(ped, false, true)
    DeleteEntity(ped)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SPAWN DES DEUX PNJ AU SPAWN JOUEUR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function spawnAllNPCs()
    Wait(500)

    if not (npcId and DoesEntityExist(npcId)) then
        npcId = spawnPed(Config.npc, "idcard:npc:clientInteract")
        if npcId then log:info("PNJ mairie spawné") end
    end

    if not (npcDrivingId and DoesEntityExist(npcDrivingId)) then
        npcDrivingId = spawnPed(Config.npcDriving, "idcard:driving:clientInteract")
        if npcDrivingId then log:info("PNJ auto-école spawné") end
    end
end

local function removeAllNPCs()
    removePed(npcId)
    removePed(npcDrivingId)
    npcId        = nil
    npcDrivingId = nil
end

RegisterNetEvent("union:player:spawned", function()
    spawnAllNPCs()
end)

AddEventHandler("union:character:unloaded", function()
    removeAllNPCs()
    if nuiOpen then
        nuiOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "hideIdentity" })
    end
end)

-- Re-register si kt_interact redémarre
AddEventHandler("onResourceStart", function(r)
    if r ~= Config.resources.interact then return end
    Wait(300)
    if npcId and DoesEntityExist(npcId) then
        pcall(function()
            exports[Config.resources.interact]:AddTargetEntity(npcId, {
                options = {{ label = Config.npc.interact.label, icon = Config.npc.interact.icon,
                             distance = Config.npc.interact.distance, event = "idcard:npc:clientInteract" }}
            })
        end)
    end
    if npcDrivingId and DoesEntityExist(npcDrivingId) then
        pcall(function()
            exports[Config.resources.interact]:AddTargetEntity(npcDrivingId, {
                options = {{ label = Config.npcDriving.interact.label, icon = Config.npcDriving.interact.icon,
                             distance = Config.npcDriving.interact.distance, event = "idcard:driving:clientInteract" }}
            })
        end)
    end
    log:info("kt_interact redémarré — zones re-enregistrées")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- INTERACTIONS PNJ → SERVEUR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

AddEventHandler("idcard:npc:clientInteract", function()
    TriggerServerEvent("idcard:npc:interact")
end)

AddEventHandler("idcard:driving:clientInteract", function()
    TriggerServerEvent("idcard:driving:interact")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MENU AUTO-ÉCOLE (reçu du serveur)
-- Utilise k_menu si disponible, sinon fallback console
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNetEvent("idcard:driving:openMenu", function(licenseList)
    if not licenseList or #licenseList == 0 then return end

    local items = {}
    for _, lic in ipairs(licenseList) do
        local label = lic.label
        if lic.owned then
            label = label .. " ✓"
        end
        items[#items + 1] = {
            label       = label,
            description = lic.owned and "Déjà obtenu" or "Passer l'examen",
            icon        = lic.icon,
            disabled    = lic.owned,
            onSelect    = not lic.owned and function()
                TriggerServerEvent("idcard:driving:requestLicense", lic.type)
            end or nil,
        }
    end

    -- Utilise k_menu via Bridge si disponible
    if GetResourceState("k_menu") == "started" then
        exports["k_menu"]:Open({
            title    = "Auto-école — Choisissez votre permis",
            items    = items,
            position = "top-left",
        })
    else
        -- Fallback : affiche en console F8 + choisir via NUI simple
        print("^2[AUTO-ÉCOLE] Permis disponibles :")
        for i, lic in ipairs(licenseList) do
            if not lic.owned then
                print(("  ^3[%d]^7 %s"):format(i, lic.label))
            end
        end
        -- Envoie à la NUI pour afficher un menu basique
        SendNUIMessage({ action = "showDrivingMenu", licenses = licenseList })
        SetNuiFocus(true, true)
        nuiOpen = true
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CONTRÔLE POLICE — kt_target sur joueur
-- La police peut cibler n'importe quel joueur via kt_target
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- On enregistre les options de contrôle sur tous les joueurs (modèles freemode)
-- via kt_target AddTargetModel (plus efficace que AddTargetEntity par joueur)
CreateThread(function()
    -- Attendre que kt_target soit prêt
    while GetResourceState("kt_target") ~= "started" do Wait(1000) end

    -- Vérifie que le joueur est policier avant d'afficher les options
    local function isPolice()
        local char = LocalPlayer.state.character
        return char and char.job == "police"
    end

    exports["kt_target"]:AddTargetModel({ "mp_m_freemode_01", "mp_f_freemode_01" }, {
        options = {
            {
                label      = "Contrôler le permis",
                icon       = "fas fa-id-badge",
                distance   = 3.0,
                canInteract = isPolice,
                action     = function(entity)
                    local netId     = NetworkGetNetworkIdFromEntity(entity)
                    local targetSrc = NetworkGetEntityOwner(entity)

                    -- Récupère le server ID du joueur ciblé
                    local targetServerId = nil
                    for _, playerId in ipairs(GetActivePlayers()) do
                        if GetPlayerPed(playerId) == entity then
                            targetServerId = GetPlayerServerId(playerId)
                            break
                        end
                    end

                    if targetServerId then
                        TriggerServerEvent("idcard:police:checkLicense", targetServerId)
                    end
                end,
            },
            {
                label      = "Contrôler la carte d'identité",
                icon       = "fas fa-id-card",
                distance   = 3.0,
                canInteract = isPolice,
                action     = function(entity)
                    local targetServerId = nil
                    for _, playerId in ipairs(GetActivePlayers()) do
                        if GetPlayerPed(playerId) == entity then
                            targetServerId = GetPlayerServerId(playerId)
                            break
                        end
                    end
                    if targetServerId then
                        TriggerServerEvent("idcard:police:checkIdentity", targetServerId)
                    end
                end,
            },
        }
    })

    log:info("Options contrôle police enregistrées sur kt_target")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- VÉRIFICATION PERMIS AU VOLANT
-- Déclenché quand le joueur entre dans un véhicule
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local lastCheckedVehicle = 0  -- anti-spam : un seul check par véhicule monté

CreateThread(function()
    local inVehicle = false

    while true do
        Wait(500)

        if not LocalPlayer.state.character then goto continue end

        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if DoesEntityExist(vehicle) and vehicle ~= 0 then
            if not inVehicle then
                inVehicle = true

                -- Vérifie seulement si c'est un nouveau véhicule
                if vehicle ~= lastCheckedVehicle then
                    lastCheckedVehicle = vehicle

                    local vClass     = GetVehicleClass(vehicle)
                    local licClasses = Config.licenses.vehicleClasses
                    local licType    = licClasses[vClass]

                    if licType then
                        -- Délai pour laisser le joueur s'installer
                        Wait(1500)
                        -- Re-vérifier qu'il est toujours dans le véhicule
                        if GetVehiclePedIsIn(PlayerPedId(), false) == vehicle then
                            TriggerServerEvent("idcard:license:check", licType)
                        end
                    end
                end
            end
        else
            inVehicle          = false
            lastCheckedVehicle = 0
        end

        ::continue::
    end
end)

-- Résultat du check permis (optionnel : afficher un feedback visuel)
RegisterNetEvent("idcard:license:result", function(valid, licType)
    if Config.debug then
        local label = Config.licenses.types[licType] and Config.licenses.types[licType].label or licType
        log:debug(("Check permis '%s' → %s"):format(label, valid and "OK" or "INVALIDE"))
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NUI — AFFICHAGE (carte + permis)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNetEvent("idcard:show", function(data)
    if not data then return end
    nuiOpen = true
    SetNuiFocus(true, false)
    SendNUIMessage(data)
    log:info("NUI affichée (action=" .. tostring(data.action) .. ")")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NUI — FERMETURE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNUICallback("idcard:close", function(_, cb)
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hideIdentity" })
    TriggerServerEvent("idcard:closed")
    log:info("NUI fermée")
    cb({ ok = true })
end)

-- Choix permis depuis NUI fallback (si k_menu absent)
RegisterNUICallback("idcard:selectLicense", function(data, cb)
    if data and data.type then
        TriggerServerEvent("idcard:driving:requestLicense", data.type)
    end
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hideIdentity" })
    cb({ ok = true })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NOTIFICATIONS SERVEUR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNetEvent("idcard:notify", function(msg, nType)
    notify(msg, nType)
end)

log:info("Module kt_idcard_ui v2 client chargé")