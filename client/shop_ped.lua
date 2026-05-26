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
    local hash = GetHashKey(cfg.Model)

    if not loadModel(hash) then
        log:warn("Impossible de charger le modèle : " .. cfg.Model)
        return
    end

    local c   = cfg.Coords
    local ped = CreatePed(4, hash, c.x, c.y, c.z - 1.0, cfg.Heading, false, false)
    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(ped) then
        log:warn("Impossible de créer le PNJ boutique")
        return
    end

    -- Propriétés
    if cfg.Frozen     then FreezeEntityPosition(ped, true)  end
    if cfg.Invincible then SetEntityInvincible(ped, true)   end
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityVisible(ped, true, false)

    -- Scénario idle
    if cfg.Scenario and cfg.Scenario ~= "" then
        TaskStartScenarioInPlace(ped, cfg.Scenario, 0, true)
    end

    -- Interaction via kt_target
    if GetResourceState(Config.resources.target) == "started" then
        exports[Config.resources.target]:AddTargetEntity(ped, {
            options = {{
                label    = cfg.label,
                icon     = cfg.icon,
                distance = cfg.distance,
                action   = function()
                    TriggerServerEvent("idcard:shop:open")
                end,
            }}
        })
    else
        -- Fallback : zone d'interaction si kt_target absent
        log:warn("kt_target non disponible, fallback zone")
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
        if GetResourceState(Config.resources.target) == "started" then
            pcall(function()
                exports[Config.resources.target]:RemoveTargetEntity(shopPedId)
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
