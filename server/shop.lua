-- server/shop.lua
-- Logique serveur de la boutique documents

local log = Logger:child("SHOP:SERVER")

-- ─── Helpers locaux ───────────────────────────────────────────────────────────

local function isConnected(src)
    return GetPlayerEndpoint(src) ~= nil
end

local function getCharacter(src)
    local ok, char = pcall(function()
        return exports[Config.resources.union]:GetCharacterState(src)
    end)
    if ok and char then return char end
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
    -- Vérifie que le solde est suffisant avant de débiter
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

-- ─── Construction du catalogue avec état "owned" pour ce joueur ──────────────

local function buildCatalog(char, cb)
    local shop    = Config.PNJ.shop
    local total   = #shop
    local catalog = {}
    local done    = 0

    for i, entry in ipairs(shop) do
        local function markDone(owned)
            catalog[i] = {
                id    = entry.id,
                label = entry.label,
                desc  = entry.desc,
                price = entry.price,
                owned = owned,
            }
            done = done + 1
            if done == total then cb(catalog) end
        end

        if not entry.unique then
            -- Article non-unique → jamais "owned"
            markDone(false)
        elseif entry.licType then
            -- Vérifier la licence en BDD
            hasLicense(char.unique_id, entry.licType, markDone)
        elseif entry.item then
            -- Vérifier l'item dans l'inventaire
            local owned = hasItem(-1, Config.items[entry.item] or entry.item)
            -- hasItem avec src réel
            markDone(owned)
        else
            markDone(false)
        end
    end
end

-- ─── EVENT : ouvrir la boutique ───────────────────────────────────────────────

RegisterNetEvent("idcard:shop:open", function()
    local src  = source
    local char = getCharacter(src)
    if not char then
        notify(src, "Aucun personnage actif.", "error")
        return
    end

    -- On reconstruit le catalogue en vérifiant ce que le joueur possède déjà
    local shop   = Config.PNJ.shop
    local total  = #shop
    local catalog = {}
    local pending = 0

    -- Pour les licences on fait des requêtes async, on collecte tout puis on envoie
    local results = {}
    for i = 1, total do results[i] = false end

    local function checkDone()
        pending = pending - 1
        if pending == 0 then
            -- Tout résolu : envoyer au client
            TriggerClientEvent("idcard:shop:openMenu", src, catalog)
        end
    end

    for i, entry in ipairs(shop) do
        pending = pending + 1
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
        elseif entry.item then
            local itemName = Config.items[entry.item] or entry.item
            local owned    = hasItem(src, itemName)
            catalog[idx] = {
                id    = entry.id,
                label = entry.label,
                desc  = entry.desc,
                price = entry.price,
                owned = owned,
            }
            pending = pending - 1 + 0  -- synchrone, on décrémente manuellement
            pending = pending + 1
            checkDone()
        else
            catalog[idx] = {
                id    = entry.id,
                label = entry.label,
                desc  = entry.desc,
                price = entry.price,
                owned = false,
            }
            checkDone()
        end
    end
end)

-- ─── EVENT : acheter un article ───────────────────────────────────────────────

RegisterNetEvent("idcard:shop:buy", function(itemId)
    local src  = source
    local char = getCharacter(src)
    if not char then return end
    if not isConnected(src) then return end

    -- Trouver l'article dans le catalogue
    local entry = nil
    for _, e in ipairs(Config.PNJ.shop) do
        if e.id == itemId then entry = e ; break end
    end

    if not entry then
        notify(src, "Article introuvable.", "error")
        return
    end

    -- ── Vérification "unique" ──────────────────────────────────────────────
    local function proceedWithPurchase()
        -- Débiter le compte
        debitAccount(char.unique_id, entry.price, function(success, errMsg)
            if not success then
                TriggerClientEvent("idcard:shop:result", src, false,
                    errMsg == "solde insuffisant"
                        and ("Solde insuffisant. Prix : $%d"):format(entry.price)
                        or  "Erreur bancaire, réessayez.",
                    "error")
                return
            end

            -- ── Donner l'item si défini ────────────────────────────────────
            if entry.item then
                local itemName = Config.items[entry.item] or entry.item
                addItem(src, itemName)
            end

            -- ── Enregistrer la licence si définie ─────────────────────────
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

            log:info(("Achat : src=%d uid=%s article=%s prix=%d"):format(src, char.unique_id, itemId, entry.price))

            TriggerClientEvent("idcard:shop:result", src, true,
                ("✅ %s acheté pour $%d"):format(entry.label:gsub("[^\32-\126\192-\255]", ""), entry.price),
                "success")
        end)
    end

    -- Vérification "unique" selon le type
    if entry.unique then
        if entry.licType then
            hasLicense(char.unique_id, entry.licType, function(owned)
                if owned then
                    TriggerClientEvent("idcard:shop:result", src, false,
                        "Vous possédez déjà ce permis.", "warning")
                    return
                end
                proceedWithPurchase()
            end)
        elseif entry.item then
            local itemName = Config.items[entry.item] or entry.item
            if hasItem(src, itemName) then
                TriggerClientEvent("idcard:shop:result", src, false,
                    "Vous possédez déjà ce document.", "warning")
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

log:info("Boutique documents chargée")
