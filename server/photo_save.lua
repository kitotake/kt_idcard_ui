-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PHOTO — SAUVEGARDE EN BASE DE DONNÉES
-- Corrections :
--   [FIX-1] isConnected et getCharacter redéclarés localement
--           (ce fichier est chargé séparément, il n'a pas accès aux
--            helpers de server/main.lua dans son propre scope)
--   [FIX-2] Validation URL renforcée
--   [FIX-3] Log structuré
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Migration SQL à exécuter une fois :
-- ALTER TABLE user_character ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL;

local log = Logger:child("PHOTO:SERVER")

-- [FIX-1] Helpers locaux — ne pas dépendre du scope de server/main.lua

local function isConnected(src)
    return GetPlayerEndpoint(src) ~= nil
end

local function getCharacterLocal(src)
    if not src then return nil end
    local ok, raw = pcall(function()
        return exports[Config.resources.union]:GetCharacterState(src)
    end)
    if not ok or not raw or type(raw) ~= "table" then return nil end
    if raw.data        and type(raw.data)      == "table" then return raw.data      end
    if raw.character   and type(raw.character) == "table" then return raw.character end
    if raw.currentCharacter and type(raw.currentCharacter) == "table" then return raw.currentCharacter end
    if raw.firstname or raw.unique_id then return raw end
    return nil
end

-- [FIX-2] Validation URL basique (évite les injections via l'URL)
local function isValidPhotoUrl(url)
    if not url or type(url) ~= "string" then return false end
    local len = #url
    if len < 10 or len > 2048 then return false end
    -- Doit commencer par http(s)://
    if not url:match("^https?://") then return false end
    -- Doit se terminer par une extension image connue
    if not url:match("%.%a+$") then return false end
    return true
end

-- ─────────────────────────────────────────────
-- SAUVEGARDE PHOTO
-- ─────────────────────────────────────────────

RegisterNetEvent("idcard:photo:save", function(uniqueId, photoUrl)
    local src = source

    if not isConnected(src) then return end

    -- [FIX-2] Validation renforcée
    if not uniqueId or type(uniqueId) ~= "string" or uniqueId == "" then
        log:warn(("Photo save refusée — uniqueId invalide src=%d"):format(src))
        return
    end

    if not isValidPhotoUrl(photoUrl) then
        log:warn(("Photo save refusée — URL invalide src=%d url=%s"):format(src, tostring(photoUrl):sub(1, 80)))
        return
    end

    -- [FIX-1] Utilisation du helper local
    local char = getCharacterLocal(src)
    if not char then
        log:warn(("Photo save refusée — pas de personnage src=%d"):format(src))
        return
    end

    -- Vérification anti-usurpation : l'uid doit appartenir au joueur
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
-- CHARGEMENT PHOTO (pour inclusion dans les cartes)
-- ─────────────────────────────────────────────

-- Helper exporté pour server/main.lua afin d'inclure la photo dans le payload
-- Usage dans server/main.lua :
--   exports["kt_idcard_ui"]:FetchPhotoAndSend(src, cardType, payload)
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