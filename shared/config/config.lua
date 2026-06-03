-- shared/config/config.lua

Config = {}

-- ─── Ressources externes ──────────────────────────────────────────────────────
Config.resources = {
    union     = "union",
    inventory = "kt_inventory",
    interact  = "kt_interact",
    context   = "kt_context",   -- remplace kt_target — zones et menus joueur
}

-- ─── Items inventaire ─────────────────────────────────────────────────────────
Config.items = {
    identity   = "identity_card",
    driver     = "license_card",
    weapon     = "weapon_permit",
    police     = "police_badge",
    mairie     = "mairie_card",
    government = "gov_card",
    ems        = "ems_card",
    company    = "company_badge",
    passport   = "passport",
}

-- ─── Permis de conduire ───────────────────────────────────────────────────────
Config.licenses = {
    fine = 1500,
    vehicleClasses = {
        [0]  = "B", [1]  = "B", [2]  = "B", [3]  = "B",
        [4]  = "B", [5]  = "B", [6]  = "B", [7]  = "B",
        [8]  = "A",
        [10] = "C", [11] = "C", [20] = "C",
        [12] = "B",
    },
}

-- ─── Jobs ─────────────────────────────────────────────────────────────────────
Config.policeJobs = { "police", "bcso", "sasp", "fbi" }
Config.emsJobs    = { "ems", "doctor", "ambulance" }
Config.govJobs    = { "gov", "government", "mayor" }

-- ─── Rayon affichage carte aux proches ────────────────────────────────────────
Config.showRadius = 5.0

-- ─── PNJ Mairie (donne la carte d'identité gratuite) ─────────────────────────
Config.npc = {
    model   = "s_m_m_ciasec_01",
    heading = 180.0,
    coords  = vector3(-268.5, -957.8, 31.2),
    interact = {
        label    = "Carte d'identité",
        icon     = "fas fa-id-card",
        distance = 2.5,
    },
}

-- ─── PNJ Auto-école (donne les permis gratuitement) ──────────────────────────
Config.npcDriving = {
    model   = "s_m_m_fiboffice_02",
    heading = 90.0,
    coords  = vector3(-800.0, -200.0, 37.0),
    interact = {
        label    = "Auto-école",
        icon     = "fas fa-car",
        distance = 2.5,
    },
}

-- ─── PNJ Boutique documents (vente payante) ───────────────────────────────────
--
--  Ce PNJ permet d'acheter carte d'identité et permis de conduire
--  directement contre de l'argent (déduit du compte bancaire personnel).
--
--  Scénarios GTA V utiles pour Scenario :
--    "WORLD_HUMAN_CLIPBOARD"       → tient un clipboard, regarde autour
--    "WORLD_HUMAN_AA_SMOKE"        → fume une cigarette
--    "WORLD_HUMAN_STAND_IMPATIENT" → attend en croisant les bras
--    "WORLD_HUMAN_COP_IDLES"       → pose de policier au repos
--    "WORLD_HUMAN_GUARD_STAND"     → garde debout
--
Config.PNJ = {
    model      = "s_f_y_airhostess_01",        -- modèle du ped (GTA V ped name)
    coords     = vector3(-268.0, -975.0, 31.2), -- À adapter selon votre map
    heading    = 340.0,                        -- direction (0-360)
    frozen     = true,                         -- ne se déplace pas
    invincible = true,                         -- immortel
    scenario   = "WORLD_HUMAN_CLIPBOARD",      -- animation idle

    -- Label et icône affichés sur l'interaction (kt_context)
    label    = "📋 Officier d'état civil",
    icon     = "fas fa-file-contract",
    distance = 2.5,

    -- Blip minimap
    blip = {
        enabled = true,
        sprite  = 408,          -- 408 = silhouette personne
        color   = 5,            -- 5 = jaune
        scale   = 0.8,
        label   = "État Civil",
    },

    -- ─── Catalogue ────────────────────────────────────────────────────────
    -- Chaque entrée correspond à un document achetable.
    --
    -- Champs :
    --   id      → identifiant unique (string)
    --   label   → texte affiché dans le menu
    --   desc    → description affichée sous le label
    --   price   → coût en $ (compte bancaire personnel)
    --   item    → clé dans Config.items à donner après achat (nil = aucun item)
    --   licType → type de licence à enregistrer en BDD (nil = pas de licence)
    --   unique  → true = bloqué si déjà possédé
    --
    shop = {
        {
            id      = "identity_card",
            label   = "🪪 Carte d'identité nationale",
            desc    = "Document officiel requis pour toute démarche administrative.",
            price   = 150,
            item    = "identity",  -- donne l'item identity_card
            licType = nil,
            unique  = true,        -- une seule par personnage
        },
        {
            id      = "license_A",
            label   = "🏍️ Permis — Catégorie A (Moto)",
            desc    = "Autorisation de conduire les deux-roues motorisés.",
            price   = 800,
            item    = nil,
            licType = "A",
            unique  = true,
        },
        {
            id      = "license_B",
            label   = "🚗 Permis — Catégorie B (Voiture)",
            desc    = "Autorisation de conduire les véhicules légers.",
            price   = 1200,
            item    = nil,
            licType = "B",
            unique  = true,
        },
        {
            id      = "license_C",
            label   = "🚛 Permis — Catégorie C (Poids lourd)",
            desc    = "Autorisation de conduire les véhicules lourds.",
            price   = 2500,
            item    = nil,
            licType = "C",
            unique  = true,
        },
    },
}

Config.debug = true