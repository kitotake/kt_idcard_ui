-- client/main.lua
-- kt_idcard_ui v3 + kt_bankcard_ui — CLIENT FUSIONNÉ
-- Fixes : NUI focus caméra, blips map, debounce véhicule

local log     = Logger:child("UNIFIED:CLIENT")
local nuiOpen = false
local npcId        = nil
local npcDrivingId = nil
local blipMairie   = nil
local blipDriving  = nil

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function notify(msg, nType)
    lib.notify({ description = tostring(msg), type = nType or "info", duration = 4000 })
end

local function loadModel(hash)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) do
        Wait(50)
        if GetGameTimer() - t > 8000 then return false end
    end
    return true
end

local function isInteractAvailable()
    return GetResourceState(Config.resources.interact) == "started"
end

-- ─── Blips ───────────────────────────────────────────────────────────────────

local function addBlip(coords, sprite, color, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

-- ─── Spawn / remove NPC ──────────────────────────────────────────────────────

local function spawnPed(cfg, event)
    print("^3[IDCARD]^7 Modèle :", cfg.model)

    local hash = GetHashKey(cfg.model)

    if not loadModel(hash) then
        print("^1[IDCARD]^7 Impossible de charger :", cfg.model)
        return nil
    end

    local c = cfg.coords

    print("^3[IDCARD]^7 Spawn :", c.x, c.y, c.z)

    local ped = CreatePed(
        4,
        hash,
        c.x,
        c.y,
        c.z,
        cfg.heading,
        false,
        false
    )

    print("^3[IDCARD]^7 Handle :", ped)

    if not DoesEntityExist(ped) then
        print("^1[IDCARD]^7 CreatePed a échoué")
        return nil
    end

    print("^2[IDCARD]^7 Ped créé avec succès")

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)

    return ped
end
local function removePed(ped)
    if not ped or not DoesEntityExist(ped) then return end
    if isInteractAvailable() then
        pcall(function() exports[Config.resources.interact]:RemoveTargetEntity(ped) end)
    end
    SetEntityAsMissionEntity(ped, false, true)
    DeleteEntity(ped)
end

local function removeBlip(blip)
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
end

-- ─── NUI open/close helpers ──────────────────────────────────────────────────
-- FIX : SetNuiFocus(true, true) pour bloquer aussi la caméra pendant la lecture

local function openNUI(payload)
    nuiOpen = true
    SetNuiFocus(true, true)   -- FIX: 2ème arg = true bloque la caméra
    SendNUIMessage(payload)
end

local function closeNUI()
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hideCard" })
end

-- ─── Spawn au login ──────────────────────────────────────────────────────────

RegisterNetEvent("union:player:spawned", function()
    print("^2[IDCARD]^7 union:player:spawned reçu")

    Wait(500)

    if not (npcId and DoesEntityExist(npcId)) then
        print("^3[IDCARD]^7 Spawn NPC mairie")
        npcId = spawnPed(Config.npc, "idcard:npc:interact")

        if npcId then
            print("^2[IDCARD]^7 NPC mairie créé :", npcId)
            blipMairie = addBlip(Config.npc.coords, 408, 3, "Carte d'identité")
        else
            print("^1[IDCARD]^7 Échec création NPC mairie")
        end
    end

    if not (npcDrivingId and DoesEntityExist(npcDrivingId)) then
        print("^3[IDCARD]^7 Spawn NPC auto-école")
        npcDrivingId = spawnPed(Config.npcDriving, "idcard:driving:interact")

        if npcDrivingId then
            print("^2[IDCARD]^7 NPC auto-école créé :", npcDrivingId)
            blipDriving = addBlip(Config.npcDriving.coords, 225, 2, "Auto-école")
        else
            print("^1[IDCARD]^7 Échec création NPC auto-école")
        end
    end
end)

AddEventHandler("union:character:unloaded", function()
    removePed(npcId)
    removePed(npcDrivingId)
    removeBlip(blipMairie)
    removeBlip(blipDriving)
    npcId = nil ; npcDrivingId = nil
    blipMairie = nil ; blipDriving = nil
    if nuiOpen then closeNUI() end
end)

-- ─── NPC interactions ────────────────────────────────────────────────────────

AddEventHandler("idcard:npc:interact",     function() TriggerServerEvent("idcard:npc:interact") end)
AddEventHandler("idcard:driving:interact", function() TriggerServerEvent("idcard:driving:interact") end)

-- ─── Police target (kt_context) ──────────────────────────────────────────────
-- Injecte les options de contrôle dans le menu joueur via kt_context:action

local function isPolice()
    local char = LocalPlayer.state.character
    if not char then return false end
    for _, j in ipairs(Config.policeJobs) do
        if char.job == j then return true end
    end
    return false
end

-- Écoute les actions du menu kt_context pour les contrôles policiers
AddEventHandler("kt_context:action", function(id, data)
    if not isPolice() then return end
    if id == "idcard_police_identity" and data and data.targetSid then
        TriggerServerEvent("idcard:police:checkIdentity", data.targetSid)
    elseif id == "idcard_police_license" and data and data.targetSid then
        TriggerServerEvent("idcard:police:checkLicense", data.targetSid)
    elseif id == "idcard_police_badge" and data and data.targetSid then
        TriggerServerEvent("idcard:police:checkBadge", data.targetSid)
    end
end)

-- Injecte les options police dans le menu joueur kt_context
AddEventHandler("kt_context:buildPlayerMenu", function(serverId, items)
    if not isPolice() then return end
    table.insert(items, { id = "_div_police", divider = true, label = "" })
    table.insert(items, {
        id          = "idcard_police_identity",
        label       = "Contrôler l'identité",
        icon        = "IdCard",
        data        = { targetSid = serverId },
    })
    table.insert(items, {
        id          = "idcard_police_license",
        label       = "Contrôler le permis",
        icon        = "Car",
        data        = { targetSid = serverId },
    })
    table.insert(items, {
        id          = "idcard_police_badge",
        label       = "Voir badge police",
        icon        = "ShieldCheck",
        data        = { targetSid = serverId },
    })
end)

log:info("Options police enregistrées (kt_context)")

-- ─── Check permis au volant ───────────────────────────────────────────────────
-- FIX : debounce 60s pour éviter le spam au moindre saut de siège

local lastVehicle       = 0
local lastLicenseCheck  = 0

CreateThread(function()
    local inVehicle = false
    while true do
        Wait(500)
        if not LocalPlayer.state.character then goto continue end
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if DoesEntityExist(veh) and veh ~= 0 then
            if not inVehicle then
                inVehicle = true
                local now = GetGameTimer()
                -- FIX: nouveau véhicule ET cooldown 60s entre deux checks
                if veh ~= lastVehicle and (now - lastLicenseCheck) > 60000 then
                    lastVehicle      = veh
                    lastLicenseCheck = now
                    local cls     = GetVehicleClass(veh)
                    local licType = Config.licenses.vehicleClasses[cls]
                    if licType then
                        Wait(1500)
                        if GetVehiclePedIsIn(PlayerPedId(), false) == veh then
                            TriggerServerEvent("idcard:license:check", licType)
                        end
                    end
                end
            end
        else
            inVehicle   = false
            lastVehicle = 0
        end
        ::continue::
    end
end)

-- ─── NUI display — cartes identité ───────────────────────────────────────────

RegisterNetEvent("idcard:show", function(payload)
    if not payload then return end
    openNUI(payload)
    log:info("Carte affichée: " .. tostring(payload.cardType))
end)

-- ─── NUI display — cartes bancaires ──────────────────────────────────────────

RegisterNetEvent("bankcard:show", function(payload)
    if not payload then return end
    openNUI(payload)
    log:info("Carte bancaire affichée: " .. tostring(payload.data and payload.data.type))
end)

-- ─── NUI close ───────────────────────────────────────────────────────────────

RegisterNUICallback("idcard:close", function(_, cb)
    closeNUI()
    TriggerServerEvent("idcard:closed")
    cb({ ok = true })
end)

RegisterNUICallback("bankcard:close", function(_, cb)
    closeNUI()
    TriggerServerEvent("bankcard:closed")
    cb({ ok = true })
end)

-- ─── Montrer sa carte aux proches (bouton NUI) ────────────────────────────────

RegisterNUICallback("idcard:showNearby", function(data, cb)
    TriggerServerEvent("idcard:showToNearby", data.cardType)
    cb({ ok = true })
end)

-- ─── Notifications ───────────────────────────────────────────────────────────

RegisterNetEvent("idcard:notify", function(msg, nType)
    notify(msg, nType)
end)

RegisterNetEvent("bankcard:notify", function(msg, nType)
    notify(msg, nType)
end)

log:info("NUI unifiée chargée — 9 cartes identité + 3 cartes bancaires")