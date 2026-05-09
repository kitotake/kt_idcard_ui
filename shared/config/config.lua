-- À AJOUTER dans shared/config/config.lua, 
Config = { 
   identity = {
       showRadius  = 5.0,    -- mètres autour du joueur qui montre sa carte
       itemName    = "identity_card",
   },

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ITEM kt_inventory à enregistrer dans ta config kt_inventory :
--
-- ["identity_card"] = {
--     label       = "Carte d'identité",
--     weight      = 10,
--     stack       = false,
--     close       = true,
--     description = "Carte nationale d'identité officielle.",
--     server      = {
--         export = "union.UseIdentityCard"   -- voir ci-dessous
--     }
-- }
--
-- OU via l'event kt_inventory (selon ta version) :
-- L'item doit déclencher TriggerServerEvent("identity:use") à l'usage.
-- La façon la plus simple : dans ta config kt_inventory, pointe l'item
-- vers l'event "identity:use" de la ressource "union".
--
-- Si kt_inventory utilise des exports pour les callbacks d'item :
-- exports("UseIdentityCard", function(source)
--     TriggerServerEvent("identity:use")   -- le source est déjà capturé par FiveM
-- end)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
