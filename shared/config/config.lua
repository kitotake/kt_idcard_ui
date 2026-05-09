-- shared/config/config.lua

Config = {

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- ITEM
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    itemName   = "identity_card",
    showRadius = 5.0,   -- rayon (mètres) autour du joueur qui montre sa carte

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- PNJ FONCTIONNAIRE
    -- Modèle + position fixée par l'admin ici
    -- heading : orientation du PNJ (0 = nord, 90 = est, 180 = sud, 270 = ouest)
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    npc = {
        model   = "s_m_m_civmale_01",   -- modèle du fonctionnaire
        heading = 180.0,
        coords  = vector3(-268.5, -957.8, 31.2),  -- ← changer par la vraie position in-game

        -- Interaction kt_interact affichée au joueur
        interact = {
            label    = "Demander une carte d'identité",
            icon     = "fas fa-id-card",
            distance = 2.5,
        },
    },

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- RESSOURCES EXTERNES
    -- Noms des ressources Union/kt
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    resources = {
        union     = "union",
        inventory = "kt_inventory",
        character = "kt_character",
    },

    debug = true,
}

return Config

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ITEM kt_inventory à enregistrer dans ta config kt_inventory :
--
