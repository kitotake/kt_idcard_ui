-- shared/config/config.lua

Config = {}

-- ─── Ressources externes ──────────────────────────────────────────────────────
Config.resources = {
    union     = "union",
    inventory = "kt_inventory",
    interact  = "kt_interact",
    context   = "kt_context",
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

-- ─── PNJ Mairie ───────────────────────────────────────────────────────────────
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

-- ─── PNJ Auto-école ───────────────────────────────────────────────────────────
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

-- ─── PNJ Boutique documents ───────────────────────────────────────────────────
Config.PNJ = {
    model      = "s_f_y_airhostess_01",
    coords     = vector3(-268.0, -975.0, 31.2),
    heading    = 340.0,
    frozen     = true,
    invincible = true,
    scenario   = "WORLD_HUMAN_CLIPBOARD",

    label    = "📋 Officier d'état civil",
    icon     = "fas fa-file-contract",
    distance = 2.5,

    blip = {
        enabled = true,
        sprite  = 408,
        color   = 5,
        scale   = 0.8,
        label   = "État Civil",
    },

    shop = {
        {
            id      = "identity_card",
            label   = "🪪 Carte d'identité nationale",
            desc    = "Document officiel requis pour toute démarche administrative.",
            price   = 150,
            item    = "identity",
            licType = nil,
            unique  = true,
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

Config.debug = false
