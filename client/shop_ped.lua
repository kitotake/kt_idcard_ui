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
    local cfg = Config.PNJ

    print("^3[SHOP]^7 Début spawn")

    local hash = GetHashKey(cfg.model)

    print("^3[SHOP]^7 Modèle :", cfg.model)

    if not loadModel(hash) then
        print("^1[SHOP]^7 Impossible de charger :", cfg.model)
        return
    end

    local c = cfg.coords

    print("^3[SHOP]^7 Position :", c.x, c.y, c.z)

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

    print("^3[SHOP]^7 Handle :", ped)

    if not DoesEntityExist(ped) then
        print("^1[SHOP]^7 CreatePed a échoué")
        return
    end

    print("^2[SHOP]^7 PNJ boutique créé")

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    shopPedId = ped
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
    print("^2[SHOP]^7 union:player:spawned reçu")

    Wait(600)

    if not (shopPedId and DoesEntityExist(shopPedId)) then
        spawnShopPed()
    end
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