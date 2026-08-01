-- server/shop.lua
-- Logique serveur de la boutique documents
-- Corrections :
--   [FIX-1] getCharacter local normalisé identiquement à server/main.lua
--   [FIX-2] checkDone() : catalogue vide → menu envoyé immédiatement (plus de deadlock)
--   [FIX-3] Protection anti-doublon achats (debounce par src)
--   [FIX-4] SetTimeout → Citizen.SetTimeout (plus robuste cross-versions)

local log = Logger:child("SHOP:SERVER")

-- ─── Helpers locaux ───────────────────────────────────────────────────────────

local function isConnected(src)
    return GetPlayerEndpoint(src) ~= nil
end

local function getCharacter(src)
    if not src then return nil end
    local ok, raw = pcall(function()
        return exports[Config.resources.union]:GetCharacterState(src)
    end)
    if not ok or not raw or type(raw) ~= "table" then return nil end
    if raw.data             and type(raw.data)             == "table" then return raw.data             end
    if raw.character        and type(raw.character)        == "table" then return raw.character        end
    if raw.currentCharacter and type(raw.currentCharacter) == "table" then return raw.currentCharacter end
    if raw.firstname or raw.unique_id then return raw end
    return nil
end

local function notify(src, msg, nType)
    TriggerClientEvent("idcard:notify", src, msg, nType or "info")
end

local function hasItem(src, item)
    local ok, n = pcall(function()
        return exports[Config.resources.inventory]:GetItemCount(src, item)
    end)
    return ok and n and n > 0
end

local function addItem(src, item)
    local ok, r = pcall(function()
        return exports[Config.resources.inventory]:AddItem(src, item, 1)
    end)
    return ok and r
end

-- ─── Vérifie si une licence est déjà possédée en BDD ─────────────────────────

local function hasLicense(uniqueId, licType, cb)
    exports.oxmysql:scalar(
        "SELECT COUNT(*) FROM user_licenses WHERE unique_id = ? AND type = ?",
        { uniqueId, licType },
        function(count)
            cb(count and count > 0)
        end
    )
end

-- ─── Ajoute une licence en BDD ────────────────────────────────────────────────

local function grantLicense(uniqueId, ident, licType, cb)
    exports.oxmysql:execute(
        "INSERT IGNORE INTO user_licenses (identifier, unique_id, type) VALUES (?, ?, ?)",
        { ident, uniqueId, licType },
        function(result)
            cb(result ~= nil)
        end
    )
end

-- ─── Débite le compte bancaire personnel ─────────────────────────────────────

local function debitAccount(uniqueId, amount, cb)
    exports.oxmysql:scalar(
        "SELECT balance FROM bank_accounts WHERE unique_id = ? AND type = 'personal' LIMIT 1",
        { uniqueId },
        function(balance)
            if not balance or balance < amount then
                cb(false, "solde insuffisant")
                return
            end
            exports.oxmysql:execute(
                "UPDATE bank_accounts SET balance = balance - ? WHERE unique_id = ? AND type = 'personal'",
                { amount, uniqueId },
                function(result)
                    local ok = result and (result.affectedRows or 0) > 0
                    cb(ok, ok and nil or "erreur bancaire")
                end
            )
        end
    )
end

-- ─── Récupère l'identifiant BDD du personnage ─────────────────────────────────

local function getIdent(uniqueId, cb)
    exports.oxmysql:scalar(
        "SELECT identifier FROM user_character WHERE unique_id = ? LIMIT 1",
        { uniqueId }, cb
    )
end

-- ─── EVENT : ouvrir la boutique ───────────────────────────────────────────────

RegisterNetEvent("idcard:shop:open", function()
    local src  = source
    local char = getCharacter(src)
    if not char then
        notify(src, "Aucun personnage actif.", "error")
        return
    end

    local shop = Config.PNJ.shop

    -- [FIX-2] Catalogue vide : on envoie immédiatement sans attendre checkDone
    if not shop or #shop == 0 then
        TriggerClientEvent("idcard:shop:openMenu", src, {})
        return
    end

    local total   = #shop
    local catalog = {}
    local pending = total

    local function checkDone()
        pending = pending - 1
        if pending == 0 then
            TriggerClientEvent("idcard:shop:openMenu", src, catalog)
        end
    end

    for i, entry in ipairs(shop) do
        local idx = i

        if entry.licType then
            hasLicense(char.unique_id, entry.licType, function(owned)
                catalog[idx] = {
                    id    = entry.id,
                    label = entry.label,
                    desc  = entry.desc,
                    price = entry.price,
                    owned = owned,
                }
                checkDone()
            end)
        else
            local owned = false
            if entry.item then
                local itemName = Config.items[entry.item] or entry.item
                owned = hasItem(src, itemName)
            end
            catalog[idx] = {
                id    = entry.id,
                label = entry.label,
                desc  = entry.desc,
                price = entry.price,
                owned = owned,
            }
            checkDone()
        end
    end
end)

-- ─── Protection anti-doublon achats ──────────────────────────────────────────

local buyingPlayers = {}

-- ─── EVENT : acheter un article ───────────────────────────────────────────────

RegisterNetEvent("idcard:shop:buy", function(itemId)
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    if not isConnected(src) then return end

    if buyingPlayers[src] then
        notify(src, "Un achat est déjà en cours.", "warning")
        return
    end
    buyingPlayers[src] = true

    -- [FIX-4] Citizen.SetTimeout au lieu de SetTimeout
    Citizen.SetTimeout(5000, function()
        buyingPlayers[src] = nil
    end)

    local entry = nil
    for _, e in ipairs(Config.PNJ.shop) do
        if e.id == itemId then entry = e ; break end
    end

    if not entry then
        notify(src, "Article introuvable.", "error")
        buyingPlayers[src] = nil
        return
    end

    local function finishPurchase(success, msg, msgType)
        buyingPlayers[src] = nil
        TriggerClientEvent("idcard:shop:result", src, success, msg, msgType)
    end

    local function proceedWithPurchase()
        debitAccount(char.unique_id, entry.price, function(success, errMsg)
            if not success then
                finishPurchase(false,
                    errMsg == "solde insuffisant"
                        and ("Solde insuffisant. Prix : $%d"):format(entry.price)
                        or  "Erreur bancaire, réessayez.",
                    "error")
                return
            end

            if entry.item then
                local itemName = Config.items[entry.item] or entry.item
                addItem(src, itemName)
            end

            if entry.licType then
                getIdent(char.unique_id, function(ident)
                    if not ident then return end
                    grantLicense(char.unique_id, ident, entry.licType, function(ok)
                        if not ok then
                            log:warn(("Échec grant licence %s pour %s"):format(entry.licType, char.unique_id))
                        end
                    end)
                end)
            end

            log:info(("Achat : src=%d uid=%s article=%s prix=%d"):format(
                src, char.unique_id, itemId, entry.price))

            local label = entry.label:gsub("[^\32-\126\192-\255]", "")
            finishPurchase(true, ("✅ %s acheté pour $%d"):format(label, entry.price), "success")
        end)
    end

    if entry.unique then
        if entry.licType then
            hasLicense(char.unique_id, entry.licType, function(owned)
                if owned then
                    finishPurchase(false, "Vous possédez déjà ce permis.", "warning")
                    return
                end
                proceedWithPurchase()
            end)
        elseif entry.item then
            local itemName = Config.items[entry.item] or entry.item
            if hasItem(src, itemName) then
                finishPurchase(false, "Vous possédez déjà ce document.", "warning")
                return
            end
            proceedWithPurchase()
        else
            proceedWithPurchase()
        end
    else
        proceedWithPurchase()
    end
end)

AddEventHandler("playerDropped", function()
    buyingPlayers[source] = nil
end)

log:info("Boutique documents chargée")
