-- client/photo_capture.lua
-- CAPTURE PHOTO PERSONNAGE (NUI callback)
-- Corrections :
--   [FIX-1] Utilise NuiState (exposé par main.lua) au lieu de la variable
--           locale nuiOpen, qui n'était pas accessible depuis ce fichier
--           de façon garantie.
--   [FIX-2] Option B corrigée : ne tente plus d'appeler screenshot-basic
--           si la resource n'est pas démarrée. Fallback propre avec message
--           d'erreur explicite renvoyé au NUI.

-- ─────────────────────────────────────────────────────────────────────────────
-- CAPTURE PHOTO
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback("idcard:capturePhoto", function(_, cb)
    cb({ ok = true })

    -- 1. Masquer le NUI pour la prise de vue
    NuiState.open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hideIdentity" })

    Wait(200)

    -- 2. Option A : screenshot-basic disponible
    if GetResourceState("screenshot-basic") == "started" then
        exports["screenshot-basic"]:requestScreenshotUpload(
            "https://api.fivemanage.com/api/image",
            "idcard_photo",
            function(data)
                local url = data and data.url or nil
                if url then
                    NuiState.open = true
                    SetNuiFocus(true, true)
                    SendNUIMessage({ action = "photoResult", photo = url })
                else
                    -- Upload échoué : on réouvre le NUI sans photo
                    NuiState.open = true
                    SetNuiFocus(true, true)
                    SendNUIMessage({ action = "photoResult", photo = "" })
                end
            end
        )
        return
    end

    -- [FIX-2] Option B : screenshot-basic non disponible
    -- On renvoie immédiatement un résultat vide plutôt que de tenter
    -- d'appeler une resource qui n'est pas démarrée (ce qui causerait
    -- une erreur Lua non catchée malgré le pcall).
    print("^3[PHOTO]^7 screenshot-basic non disponible — capture impossible")
    Wait(300)
    NuiState.open = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "photoResult", photo = "" })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- SAUVEGARDE PHOTO
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback("idcard:savePhoto", function(data, cb)
    if data and data.photo and data.photo ~= "" and data.unique_id then
        TriggerServerEvent("idcard:photo:save", data.unique_id, data.photo)
    end
    cb({ ok = true })
end)
