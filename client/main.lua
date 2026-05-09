-- client/main.lua
-- Gestion côté client de la carte d'identité.
-- Reçoit identity:show depuis le serveur → envoie à la NUI.
-- Gère la fermeture via NUI callback (touche E dans la NUI).

Identity        = Identity or {}
Identity.open   = false
Identity.logger = Logger:child("IDENTITY")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- AFFICHAGE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("identity:show", function(data)
    if not data then return end

    Identity.open = true
    SetNuiFocus(true, false)   -- focus NUI pour capter la touche E, mais pas la souris

    SendNUIMessage(data)       -- data.action = "showIdentity" déjà défini côté serveur

    Identity.logger:info("Carte affichée")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FERMETURE DEPUIS LA NUI (touche E dans le HTML)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNUICallback("identity:close", function(_, cb)
    Identity.close()
    cb({ ok = true })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HELPER CLOSE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Identity.close()
    if not Identity.open then return end
    Identity.open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hideIdentity" })
    TriggerServerEvent("identity:closed")
    Identity.logger:info("Carte fermée")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FERMETURE AUTOMATIQUE SI PERSONNAGE DÉCHARGÉ
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AddEventHandler("union:character:unloaded", function()
    Identity.close()
end)
