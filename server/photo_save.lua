-- server/photo_save.lua
-- PHOTO — SAUVEGARDE EN BASE DE DONNÉES
-- Corrections :
--   [FIX-1] Helpers locaux (pas de dépendance au scope de server/main.lua)
--   [FIX-2] Validation URL renforcée avec whitelist de domaines
--   [FIX-3] Log structuré

-- SQL requis (dans sql/migrations.sql) :
-- ALTER TABLE user_character ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL;

local log = Logger:child("PHOTO:SERVER")

-- ─── Helpers locaux [FIX-1] ──────────────────────────────────────────────────

local function isConnected(src)
    return GetPlayerEndpoint(src) ~= nil
end

local function getCharacterLocal(src)
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

-- ─── Validation URL [FIX-2] ──────────────────────────────────────────────────
-- Whitelist de domaines autorisés pour les photos de profil.
-- Ajoutez vos domaines si vous utilisez un CDN différent.

local ALLOWED_PHOTO_DOMAINS = {
    "api.fivemanage.com",
    "i.imgur.com",
    "cdn.discordapp.com",
    "media.discordapp.net",
}

local ALLOWED_EXTENSIONS = {
    jpg = true, jpeg = true, png = true, webp = true, gif = true,
}

local function isValidPhotoUrl(url)
    if not url or type(url) ~= "string" then return false end
    local len = #url
    if len < 10 or len > 2048 then return false end
    if not url:match("^https://") then return false end  -- HTTPS uniquement

    -- Extraire le domaine
    local domain = url:match("^https://([^/]+)")
    if not domain then return false end

    -- Vérifier la whitelist
    local domainAllowed = false
    for _, allowed in ipairs(ALLOWED_PHOTO_DOMAINS) do
        if domain == allowed or domain:sub(-#allowed - 1) == ("." .. allowed) then
            domainAllowed = true
            break
        end
    end
    if not domainAllowed then return false end

    -- Vérifier l'extension
    local ext = url:match("%.(%a+)%??") -- tolère les query strings ?v=...
    if not ext or not ALLOWED_EXTENSIONS[ext:lower()] then return false end

    return true
end

-- ─────────────────────────────────────────────
-- SAUVEGARDE PHOTO
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:photo:save", function(uniqueId, photoUrl)
    local src = source

    if not isConnected(src) then return end

    if not uniqueId or type(uniqueId) ~= "string" or uniqueId == "" then
        log:warn(("Photo save refusée — uniqueId invalide src=%d"):format(src))
        return
    end

    if not isValidPhotoUrl(photoUrl) then
        log:warn(("Photo save refusée — URL invalide src=%d url=%s"):format(src, tostring(photoUrl):sub(1, 80)))
        return
    end

    local char = getCharacterLocal(src)
    if not char then
        log:warn(("Photo save refusée — pas de personnage src=%d"):format(src))
        return
    end

    if char.unique_id ~= uniqueId then
        log:warn(("Photo save refusée — uid mismatch src=%d got=%s expected=%s"):format(
            src, tostring(uniqueId), tostring(char.unique_id)))
        return
    end

    exports.oxmysql:execute(
        "UPDATE user_character SET photo_url = ? WHERE unique_id = ?",
        { photoUrl, uniqueId },
        function(result)
            if result and (result.affectedRows or 0) > 0 then
                log:info(("Photo sauvegardée uid=%s"):format(uniqueId))
            else
                log:warn(("Photo non sauvegardée — aucune ligne affectée uid=%s"):format(uniqueId))
            end
        end
    )
end)

-- ─────────────────────────────────────────────
-- CHARGEMENT PHOTO
-- ─────────────────────────────────────────────

exports("FetchPhotoAndSend", function(src, cardType, payload)
    if not payload or not payload.data or not payload.data.uniqueId then
        TriggerClientEvent("idcard:show", src, payload)
        return
    end

    exports.oxmysql:scalar(
        "SELECT photo_url FROM user_character WHERE unique_id = ? LIMIT 1",
        { payload.data.uniqueId },
        function(photoUrl)
            if photoUrl and isValidPhotoUrl(photoUrl) then
                payload.data.photo = photoUrl
            end
            TriggerClientEvent("idcard:show", src, payload)
        end
    )
end)

log:info("Photo save chargé")
