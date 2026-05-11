-- client/main.lua
-- kt_idcard_ui v3 + kt_bankcard_ui — CLIENT FUSIONNÉ
-- NUI unique gérant 9 cartes identité + 3 cartes bancaires

local log     = Logger:child("UNIFIED:CLIENT")
local nuiOpen = false
local npcId        = nil
local npcDrivingId = nil

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

-- ─── Spawn / remove NPC ──────────────────────────────────────────────────────

local function spawnPed(cfg, event)
    local hash = GetHashKey(cfg.model)
    if not loadModel(hash) then return nil end
    local c   = cfg.coords
    local ped = CreatePed(4, hash, c.x, c.y, c.z - 1.0, cfg.heading, false, false)
    SetModelAsNoLongerNeeded(hash)
    if not DoesEntityExist(ped) then return nil end
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)
    if isInteractAvailable() then
        pcall(function()
            exports[Config.resources.interact]:AddTargetEntity(ped, {
                options = {{
                    label    = cfg.interact.label,
                    icon     = cfg.interact.icon,
                    distance = cfg.interact.distance,
                    event    = event,
                }}
            })
        end)
    end
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

-- ─── NUI open/close helpers ──────────────────────────────────────────────────

local function openNUI(payload)
    nuiOpen = true
    SetNuiFocus(true, false)
    SendNUIMessage(payload)
end

local function closeNUI()
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hideCard" })
end

-- ─── Spawn au login ──────────────────────────────────────────────────────────

RegisterNetEvent("union:player:spawned", function()
    Wait(500)
    if not (npcId and DoesEntityExist(npcId)) then
        npcId = spawnPed(Config.npc, "idcard:npc:interact")
    end
    if not (npcDrivingId and DoesEntityExist(npcDrivingId)) then
        npcDrivingId = spawnPed(Config.npcDriving, "idcard:driving:interact")
    end
end)

AddEventHandler("union:character:unloaded", function()
    removePed(npcId)
    removePed(npcDrivingId)
    npcId = nil ; npcDrivingId = nil
    if nuiOpen then closeNUI() end
end)

-- ─── NPC interactions ────────────────────────────────────────────────────────

AddEventHandler("idcard:npc:interact",     function() TriggerServerEvent("idcard:npc:interact") end)
AddEventHandler("idcard:driving:interact", function() TriggerServerEvent("idcard:driving:interact") end)

-- ─── Police target (kt_target) ───────────────────────────────────────────────

CreateThread(function()
    while GetResourceState("kt_target") ~= "started" do Wait(1000) end

    local function isPolice()
        local char = LocalPlayer.state.character
        if not char then return false end
        for _, j in ipairs(Config.policeJobs) do
            if char.job == j then return true end
        end
        return false
    end

    local function getTargetServerId(entity)
        for _, pid in ipairs(GetActivePlayers()) do
            if GetPlayerPed(pid) == entity then
                return GetPlayerServerId(pid)
            end
        end
        return nil
    end

    exports["kt_target"]:AddTargetModel({ "mp_m_freemode_01", "mp_f_freemode_01" }, {
        options = {
            {
                label       = "Contrôler l'identité",
                icon        = "fas fa-id-card",
                distance    = 3.0,
                canInteract = isPolice,
                action      = function(entity)
                    local sid = getTargetServerId(entity)
                    if sid then TriggerServerEvent("idcard:police:checkIdentity", sid) end
                end,
            },
            {
                label       = "Contrôler le permis",
                icon        = "fas fa-car",
                distance    = 3.0,
                canInteract = isPolice,
                action      = function(entity)
                    local sid = getTargetServerId(entity)
                    if sid then TriggerServerEvent("idcard:police:checkLicense", sid) end
                end,
            },
            {
                label       = "Voir badge police",
                icon        = "fas fa-shield-halved",
                distance    = 3.0,
                canInteract = isPolice,
                action      = function(entity)
                    local sid = getTargetServerId(entity)
                    if sid then TriggerServerEvent("idcard:police:checkBadge", sid) end
                end,
            },
        }
    })
    log:info("Options police enregistrées")
end)

-- ─── Check permis au volant ───────────────────────────────────────────────────

local lastVehicle = 0

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
                if veh ~= lastVehicle then
                    lastVehicle = veh
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

-- ─── NUI display — cartes identité (depuis serveur idcard) ───────────────────

RegisterNetEvent("idcard:show", function(payload)
    if not payload then return end
    openNUI(payload)
    log:info("Carte affichée: " .. tostring(payload.cardType))
end)

-- ─── NUI display — cartes bancaires (depuis serveur bankcard) ────────────────
-- Payload format: { action = "showCard", data = { type = "bank_card", ... } }

RegisterNetEvent("bankcard:show", function(payload)
    if not payload then return end
    openNUI(payload)
    log:info("Carte bancaire affichée: " .. tostring(payload.data and payload.data.type))
end)

-- ─── NUI close — commun aux deux systèmes ────────────────────────────────────

-- Callback idcard (compatibilité ascendante)
RegisterNUICallback("idcard:close", function(_, cb)
    closeNUI()
    TriggerServerEvent("idcard:closed")
    cb({ ok = true })
end)

-- Callback bankcard (compatibilité ascendante)
RegisterNUICallback("bankcard:close", function(_, cb)
    closeNUI()
    TriggerServerEvent("bankcard:closed")
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