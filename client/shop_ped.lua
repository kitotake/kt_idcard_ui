-- client/shop_ped.lua
-- PNJ Boutique documents — spawn, interaction, menu NUI

local log       = Logger:child("SHOP:CLIENT")
local shopPedId = nil
local shopBlip  = nil

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function notify(msg, nType)
    lib.notify({ description = tostring(msg), type = nType or "info", duration = 4000 })
end

-- ─── Spawn du PNJ boutique ────────────────────────────────────────────────────

local function addShopBlip()
    local cfg = Config.PNJ
    if not cfg.blip or not cfg.blip.enabled then return end
    if shopBlip and DoesBlipExist(shopBlip) then return end

    shopBlip = AddBlipForCoord(cfg.coords.x, cfg.coords.y, cfg.coords.z)
    SetBlipSprite(shopBlip, cfg.blip.sprite or 408)
    SetBlipColour(shopBlip, cfg.blip.color or 5)
    SetBlipScale(shopBlip, cfg.blip.scale or 0.8)
    SetBlipAsShortRange(shopBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(cfg.blip.label or cfg.label or "État Civil")
    EndTextCommandSetBlipName(shopBlip)
end

local function spawnShopPed()
    local cfg = Config.PNJ

    print("^3[SHOP]^7 Début spawn")

    shopPedId = NPC.SpawnPed(cfg, "SHOP")

    if not shopPedId then
        print("^1[SHOP]^7 Échec création PNJ boutique")
        return
    end

    addShopBlip()

    local targetReady = NPC.TryAddTargetEntity(shopPedId, cfg, "idcard:shop:interact")
    if not targetReady then
        print("^3[SHOP]^7 kt_interact indisponible ou incompatible, fallback touche E actif")
    end
end

local function removeShopPed()
    NPC.RemoveTargetEntity(shopPedId)
    NPC.DeletePed(shopPedId)
    shopPedId = nil

    if shopBlip and DoesBlipExist(shopBlip) then
        RemoveBlip(shopBlip)
        shopBlip = nil
    end
end

local function waitForCharacterReady(timeout)
    local startedAt = GetGameTimer()

    while GetGameTimer() - startedAt < (timeout or 15000) do
        if LocalPlayer and LocalPlayer.state and LocalPlayer.state.character then
            return true
        end
        Wait(250)
    end

    return false
end

-- ─── Spawn / despawn sur login/logout et restart ressource ───────────────────
local function ensureShopPedSpawned(reason)
    print(("^2[SHOP]^7 Vérification spawn PNJ boutique (%s)"):format(reason or "manuel"))

    if not (shopPedId and DoesEntityExist(shopPedId)) then
        spawnShopPed()
    elseif not (shopBlip and DoesBlipExist(shopBlip)) then
        addShopBlip()
    end
end

RegisterNetEvent("union:player:spawned", function()
    Wait(600)
    ensureShopPedSpawned("union:player:spawned")
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    CreateThread(function()
        Wait(1700)
        if waitForCharacterReady(15000) then
            ensureShopPedSpawned("resource start")
        else
            print("^3[SHOP]^7 Aucun personnage chargé, spawn PNJ boutique reporté à union:player:spawned")
        end
    end)
end)

AddEventHandler("union:character:unloaded", removeShopPed)

AddEventHandler("idcard:shop:interact", function()
    TriggerServerEvent("idcard:shop:open")
end)

NPC.StartFallbackInteraction("idcard_shop", function() return shopPedId end, Config.PNJ, "idcard:shop:interact")

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