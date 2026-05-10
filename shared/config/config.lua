-- shared/config/config.lua

Config = {

    -- ─── Ressources externes ─────────────────────────────────────────────────
    resources = {
        union     = "union",
        inventory = "kt_inventory",
        interact  = "kt_interact",
        target    = "kt_target",
    },

    -- ─── Items inventaire ─────────────────────────────────────────────────────
    items = {
        identity   = "identity_card",
        driver     = "license_card",
        weapon     = "weapon_permit",
        police     = "police_badge",
        mairie     = "mairie_card",
        government = "gov_card",
        ems        = "ems_card",
        company    = "company_badge",
        passport   = "passport",
    },

    -- ─── Permis de conduire ───────────────────────────────────────────────────
    licenses = {
        fine = 1500,
        vehicleClasses = {
            [0]  = "B", [1]  = "B", [2]  = "B", [3]  = "B",
            [4]  = "B", [5]  = "B", [6]  = "B", [7]  = "B",
            [8]  = "A",
            [10] = "C", [11] = "C", [20] = "C",
            [12] = "B",
        },
    },

    -- ─── Police ───────────────────────────────────────────────────────────────
    policeJobs = { "police", "bcso", "sasp", "fbi" },
    emsJobs    = { "ems", "doctor", "ambulance" },
    govJobs    = { "gov", "government", "mayor" },

    -- ─── Rayon affichage carte aux proches ────────────────────────────────────
    showRadius = 5.0,

    -- ─── PNJ Mairie ───────────────────────────────────────────────────────────
    npc = {
        model   = "s_m_m_civmale_01",
        heading = 180.0,
        coords  = vector3(-268.5, -957.8, 31.2),
        interact = {
            label    = "Carte d'identité",
            icon     = "fas fa-id-card",
            distance = 2.5,
        },
    },

    -- ─── PNJ Auto-école ───────────────────────────────────────────────────────
    npcDriving = {
        model   = "s_m_m_dockwork_01",
        heading = 90.0,
        coords  = vector3(-800.0, -200.0, 37.0),
        interact = {
            label    = "Auto-école",
            icon     = "fas fa-car",
            distance = 2.5,
        },
    },

    debug = true,
}

return Config
