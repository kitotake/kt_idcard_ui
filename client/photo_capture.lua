-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CAPTURE PHOTO PERSONNAGE (NUI callback)
-- Le NUI demande une capture → on masque la NUI,
-- on prend un screenshot encodé en base64,
-- on renvoie le résultat au NUI via SendNUIMessage.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Nécessite la native N_0x00E6A35C76DDE3B4 (exportée via GetRawBase64Image dans des builds récents)
-- Alternative : utiliser un resource comme screenshot-basic

RegisterNUICallback("idcard:capturePhoto", function(_, cb)
    cb({ ok = true })   -- répondre immédiatement pour débloquer le NUI

    -- 1. Masquer le NUI le temps de la prise de vue
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hideIdentity" })
    nuiOpen = false

    Wait(200)  -- laisse le temps au jeu de rerendre sans l'overlay

    -- 2. Prendre une capture d'écran
    --    Option A : screenshot-basic (resource externe populaire)
    if GetResourceState("screenshot-basic") == "started" then
        exports["screenshot-basic"]:requestScreenshotUpload(
            "https://api.fivemanage.com/api/image",  -- remplacer par votre endpoint
            "idcard_photo",
            function(data)
                -- data.url contient l'URL de l'image uploadée
                -- On renvoie l'URL au NUI (qui l'affichera comme src d'img)
                local url = data and data.url or nil
                if url then
                    nuiOpen = true
                    SetNuiFocus(true, false)
                    SendNUIMessage({
                        action = "showIdentity",  -- re-trigger la vue
                        -- on inclut juste la photo, le reste est déjà dans le state React
                    })
                    SendNUIMessage({ action = "photoResult", photo = url })
                end
            end
        )
    else
        -- Option B : native screenshot base64 (FiveM build >= 2699)
        -- Remplace le endpoint par votre serveur ou stockage
        local success, data = pcall(function()
            return exports["screenshot-basic"]:requestScreenshot({ encoding = "jpg", quality = 0.85 })
        end)

        Wait(500)  -- délai pour la capture

        -- Re-ouvrir la NUI dans tous les cas
        nuiOpen = true
        SetNuiFocus(true, false)
        SendNUIMessage({ action = "photoResult", photo = "" })  -- fallback vide
    end
end)

-- Sauvegarde la photo en DB côté serveur
RegisterNUICallback("idcard:savePhoto", function(data, cb)
    if data and data.photo and data.unique_id then
        TriggerServerEvent("idcard:photo:save", data.unique_id, data.photo)
    end
    cb({ ok = true })
end)
