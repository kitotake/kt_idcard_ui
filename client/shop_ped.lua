-- client/shop_ped.lua
-- PNJ Boutique documents — spawn, interaction, menu NUI
-- Corrections :
--   [FIX-1] Handler kt_context:action retiré — géré dans client/main.lua
--   [FIX-2] Zone kt_context enregistrée une seule fois (guard shopZoneRegistered)
--   [FIX-3] shopZoneRegistered réinitialisé inconditionnellement dans removeShopPed
--           (bug : si le ped n'existait plus, la zone n'était jamais ré-enregistrable)
--   [FIX-4] Condition elseif corrigée : "not X == Y" → "X ~= Y"

local log       = Logger:child("SHOP:CLIENT")
local shopPedId = nil
local shopBlip  = nil

local shopZoneRegistered = false

-- ─── Helpers ─────────────────────────────────────────────────────────────────

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

local function notify(msg, nType)
    lib.notify({ description = tostring(msg), type = nType or "info", duration = 4000 })
end

-- ─── Spawn du PNJ boutique ────────────────────────────────────────────────────

local function spawnShopPed()
    local cfg  = Config.PNJ
    local hash = GetHashKey(cfg.model)

    if not loadModel(hash) then
        log:warn("Impossible de charger le modèle : " .. cfg.model)
        return
    end

    local c   = cfg.coords
    local ped = CreatePed(4, hash, c.x, c.y, c.z, cfg.heading, false, false)
    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(ped) then
        log:warn("Impossible de créer le PNJ boutique")
        return
    end

    if cfg.frozen     then FreezeEntityPosition(ped, true)  end
    if cfg.invincible then SetEntityInvincible(ped, true)   end
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityVisible(ped, true, false)

    if cfg.scenario and cfg.scenario ~= "" then
        TaskStartScenarioInPlace(ped, cfg.scenario, 0, true)
    end

    local contextStarted = GetResourceState(Config.resources.context) == "started"

    if contextStarted and not shopZoneRegistered then
        pcall(function()
            exports[Config.resources.context]:RegisterMenuZone({
                id     = "idcard_shop_zone",
                coords = vector3(c.x, c.y, c.z),
                radius = cfg.distance or 2.5,
                title  = cfg.label,
                hint   = cfg.label .. " — ~INPUT_CONTEXT~",
                marker = {
                    type  = 2,
                    color = { r = 255, g = 193, b = 7, a = 120 },
                    size  = vector3(
                        (cfg.distance or 2.5) * 2,
                        (cfg.distance or 2.5) * 2,
                        0.3
                    ),
                },
                items = {{
                    id    = "idcard_shop_open",
                    label = cfg.label,
                    icon  = "FileContract",
                }},
            })
        end)
        shopZoneRegistered = true
        log:info("Zone kt_context boutique enregistrée")
    elseif not contextStarted then
        -- [FIX-4] Correction : "not X == Y" était toujours false en Lua
        log:warn("kt_context non disponible — interaction boutique désactivée")
    end

    shopPedId = ped
    log:info("PNJ boutique spawné")

    if cfg.blip and cfg.blip.enabled and not shopBlip then
        shopBlip = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(shopBlip, cfg.blip.sprite)
        SetBlipColour(shopBlip, cfg.blip.color)
        SetBlipScale(shopBlip, cfg.blip.scale)
        SetBlipAsShortRange(shopBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(cfg.blip.label)
        EndTextCommandSetBlipName(shopBlip)
    end
end

local function removeShopPed()
    -- [FIX-3] On retire la zone et on réinitialise le guard AVANT la vérification
    -- d'existence du ped. Sinon, si le ped a disparu (crash, reconnexion),
    -- shopZoneRegistered restait true et la zone ne pouvait plus être ré-enregistrée.
    if shopZoneRegistered then
        if GetResourceState(Config.resources.context) == "started" then
            pcall(function()
                exports[Config.resources.context]:RemoveMenuZone("idcard_shop_zone")
            end)
        end
        shopZoneRegistered = false
    end

    if shopPedId and DoesEntityExist(shopPedId) then
        SetEntityAsMissionEntity(shopPedId, false, true)
        DeleteEntity(shopPedId)
    end
    shopPedId = nil

    if shopBlip and DoesBlipExist(shopBlip) then
        RemoveBlip(shopBlip)
        shopBlip = nil
    end
end

-- ─── Spawn / despawn sur login/logout ────────────────────────────────────────

RegisterNetEvent("union:player:spawned", function()
    Wait(600)
    if not (shopPedId and DoesEntityExist(shopPedId)) then
        spawnShopPed()
    end
end)

CreateThread(function()
    Wait(1200)
    if LocalPlayer.state.character and not (shopPedId and DoesEntityExist(shopPedId)) then
        log:info("Spawn fallback boutique — personnage déjà actif")
        spawnShopPed()
    end
end)

AddEventHandler("union:character:unloaded", function()
    removeShopPed()
end)

-- ─── Réception du catalogue depuis le serveur → ouvre la NUI boutique ────────

RegisterNetEvent("idcard:shop:openMenu", function(catalogData)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openShop",
        items  = catalogData,
    })
end)

-- ─── Callbacks NUI ────────────────────────────────────────────────────────────

RegisterNUICallback("idcard:shop:buy", function(data, cb)
    TriggerServerEvent("idcard:shop:buy", data.id)
    cb({ ok = true })
end)

RegisterNUICallback("idcard:shop:close", function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeShop" })
    cb({ ok = true })
end)

-- ─── Résultat d'achat renvoyé par le serveur ─────────────────────────────────

RegisterNetEvent("idcard:shop:result", function(success, message, nType)
    notify(message, nType)
    if success then
        TriggerServerEvent("idcard:shop:open")
    end
end)

log:info("PNJ boutique chargé")
