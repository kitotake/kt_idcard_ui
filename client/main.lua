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
    local hash = GetHashKey(cfg.model)
    if not loadModel(hash) then return nil end
    local c   = cfg.coords
    local ped = CreatePed(4, hash, c.x, c.y, c.z, cfg.heading, false, false)
    SetModelAsNoLongerNeeded(hash)
    if not DoesEntityExist(ped) then return nil end
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)
    -- Interaction via kt_context (zone sphérique)
    if GetResourceState(Config.resources.context) == "started" then
        pcall(function()
            exports[Config.resources.context]:RegisterMenuZone({
                id     = "idcard_zone_" .. tostring(ped),
                coords = vector3(c.x, c.y, c.z),
                radius = cfg.interact.distance or 2.5,
                title  = cfg.interact.label,
                hint   = cfg.interact.label .. " — ~INPUT_CONTEXT~",
                marker = {
                    type  = 2,
                    color = { r = 52, g = 152, b = 219, a = 120 },
                    size  = vector3((cfg.interact.distance or 2.5) * 2,
                                   (cfg.interact.distance or 2.5) * 2, 0.3),
                },
                items = {{
                    id    = event,
                    label = cfg.interact.label,
                    icon  = "IdCard",
                }},
            })
        end)
    end
    return ped
end

local function removePed(ped)
    if not ped or not DoesEntityExist(ped) then return end
    if GetResourceState(Config.resources.context) == "started" then
        pcall(function()
            exports[Config.resources.context]:RemoveMenuZone("idcard_zone_" .. tostring(ped))
        end)
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

local function spawnAllPeds()
    if not (npcId and DoesEntityExist(npcId)) then
        npcId = spawnPed(Config.npc, "idcard:npc:interact")
        if npcId then
            blipMairie = addBlip(Config.npc.coords, 408, 3, "Carte d'identité")
        end
    end
    if not (npcDrivingId and DoesEntityExist(npcDrivingId)) then
        npcDrivingId = spawnPed(Config.npcDriving, "idcard:driving:interact")
        if npcDrivingId then
            blipDriving = addBlip(Config.npcDriving.coords, 225, 2, "Auto-école")
        end
    end
end

-- ⭐⭐⭐⭐⭐ FIX : union:player:spawned peut ne pas se déclencher si la resource
-- est lancée après le login. On vérifie le statebag au démarrage et on écoute
-- l'event pour les connexions normales.
RegisterNetEvent("union:player:spawned", function()
    Wait(500)
    spawnAllPeds()
end)

-- Fallback : resource démarrée après le login (restart en jeu)
CreateThread(function()
    Wait(1000)  -- laisser le temps à la config et aux autres scripts de charger
    if LocalPlayer.state.character then
        log:info("Spawn fallback — personnage déjà actif au démarrage")
        spawnAllPeds()
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
-- Les zones kt_context déclenchent l'action avec l'id = event name

AddEventHandler("idcard:npc:interact",     function() TriggerServerEvent("idcard:npc:interact") end)
AddEventHandler("idcard:driving:interact", function() TriggerServerEvent("idcard:driving:interact") end)

-- Relais kt_context:action → events locaux NPC
AddEventHandler("kt_context:action", function(id)
    if id == "idcard:npc:interact" then
        TriggerEvent("idcard:npc:interact")
    elseif id == "idcard:driving:interact" then
        TriggerEvent("idcard:driving:interact")
    end
end)

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

-- Les actions police sont gérées dans le handler kt_context:action ci-dessus
-- (fusionné avec le relais NPC pour éviter les doubles AddEventHandler)
AddEventHandler("kt_context:action", function(id, data)
    -- ── Contrôles policiers ──
    if isPolice() then
        if id == "idcard_police_identity" and data and data.targetSid then
            TriggerServerEvent("idcard:police:checkIdentity", data.targetSid)
        elseif id == "idcard_police_license" and data and data.targetSid then
            TriggerServerEvent("idcard:police:checkLicense", data.targetSid)
        elseif id == "idcard_police_badge" and data and data.targetSid then
            TriggerServerEvent("idcard:police:checkBadge", data.targetSid)
        end
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