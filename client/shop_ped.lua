-- client/shop_ped.lua
-- PNJ Boutique documents — spawn, interaction, menu NUI

local log       = Logger:child("SHOP:CLIENT")
local shopPedId = nil
local shopBlip  = nil

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

    -- Propriétés
    if cfg.frozen     then FreezeEntityPosition(ped, true)  end
    if cfg.invincible then SetEntityInvincible(ped, true)   end
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityVisible(ped, true, false)

    -- Scénario idle
    if cfg.scenario and cfg.scenario ~= "" then
        TaskStartScenarioInPlace(ped, cfg.scenario, 0, true)
    end

    -- Interaction via kt_context (zone sphérique)
    if GetResourceState(Config.resources.context) == "started" then
        exports[Config.resources.context]:RegisterMenuZone({
            id     = "idcard_shop_zone",
            coords = vector3(c.x, c.y, c.z),
            radius = cfg.distance or 2.5,
            title  = cfg.label,
            hint   = cfg.label .. " — ~INPUT_CONTEXT~",
            marker = {
                type  = 2,
                color = { r = 255, g = 193, b = 7, a = 120 },
                size  = vector3((cfg.distance or 2.5) * 2, (cfg.distance or 2.5) * 2, 0.3),
            },
            items = {{
                id    = "idcard_shop_open",
                label = cfg.label,
                icon  = "FileContract",
            }},
        })
        AddEventHandler("kt_context:action", function(id)
            if id == "idcard_shop_open" then
                TriggerServerEvent("idcard:shop:open")
            end
        end)
        log:info("Zone kt_context boutique enregistrée")
    else
        log:warn("kt_context non disponible — interaction boutique désactivée")
    end

    shopPedId = ped
    log:info("PNJ boutique spawné")

    -- Blip minimap
    if cfg.blip and cfg.blip.enabled then
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
    if shopPedId and DoesEntityExist(shopPedId) then
        if GetResourceState(Config.resources.context) == "started" then
            pcall(function()
                exports[Config.resources.context]:RemoveMenuZone("idcard_shop_zone")
            end)
        end
        SetEntityAsMissionEntity(shopPedId, false, true)
        DeleteEntity(shopPedId)
        shopPedId = nil
    end
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

-- ⭐⭐⭐⭐⭐ FIX : fallback si resource démarrée après le login
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
    -- catalogData = { items = { { id, label, desc, price, owned } ... } }
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openShop",
        items  = catalogData,
    })
end)

-- ─── Callbacks NUI ────────────────────────────────────────────────────────────

-- Joueur clique "Acheter" sur un article
RegisterNUICallback("idcard:shop:buy", function(data, cb)
    -- data.id = identifiant de l'article (ex: "license_B")
    TriggerServerEvent("idcard:shop:buy", data.id)
    cb({ ok = true })
end)

-- Joueur ferme la boutique
RegisterNUICallback("idcard:shop:close", function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeShop" })
    cb({ ok = true })
end)

-- ─── Résultat d'achat renvoyé par le serveur ─────────────────────────────────

RegisterNetEvent("idcard:shop:result", function(success, message, nType)
    notify(message, nType)
    if success then
        -- Rafraîchir le menu pour mettre à jour les "déjà acheté"
        TriggerServerEvent("idcard:shop:open")
    end
end)

log:info("PNJ boutique chargé")