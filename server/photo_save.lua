-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PHOTO — SAUVEGARDE EN BASE DE DONNÉES
-- Ajouter à server/main.lua
-- La colonne photo_url doit exister dans user_character
-- (ou dans une table user_photos séparée)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Migration SQL à exécuter une fois :
-- ALTER TABLE user_character ADD COLUMN photo_url TEXT DEFAULT NULL;

RegisterNetEvent("idcard:photo:save", function(uniqueId, photoUrl)
    local src = source
    if not isConnected(src) then return end

    -- Validation basique
    if not uniqueId or not photoUrl or #photoUrl < 10 then return end

    -- Vérifier que l'uid appartient bien au joueur qui envoie
    local char = getCharacter(src)
    if not char or char.unique_id ~= uniqueId then
        log:warn(("Photo save refusée — uid mismatch src=%d"):format(src))
        return
    end

    exports.oxmysql:execute(
        "UPDATE user_character SET photo_url = ? WHERE unique_id = ?",
        { photoUrl, uniqueId },
        function(result)
            if result and (result.affectedRows or 0) > 0 then
                log:info(("Photo sauvegardée uid=%s"):format(uniqueId))
            end
        end
    )
end)

-- Lors du chargement de la carte, inclure la photo dans le payload
-- Modifier la fonction showIdentity pour ajouter :
--
-- exports.oxmysql:scalar(
--     "SELECT photo_url FROM user_character WHERE unique_id = ? LIMIT 1",
--     { char.unique_id },
--     function(photoUrl)
--         payload.photo = photoUrl
--         TriggerClientEvent("idcard:show", src, payload)
--     end
-- )
