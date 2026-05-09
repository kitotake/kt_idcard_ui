-- shared/config/config.lua

Config = {

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- CARTE D'IDENTITÉ
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    itemName   = "identity_card",
    itemName   = "license_card ",  -- nom de l'item dans la DB (table `items` de union)
    showRadius = 5.0,   -- rayon (mètres) pour diffuser la carte aux proches

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- PERMIS DE CONDUIRE
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    licenses = {
        -- Types disponibles (doivent exister dans la table `licenses` de la DB union)
        types = {
            drive       = { label = "Permis B — Voiture",       item = "license_drive",       icon = "fas fa-car" },
            drive_bike  = { label = "Permis A — Moto",          item = "license_drive_bike",   icon = "fas fa-motorcycle" },
            drive_truck = { label = "Permis C — Poids lourd",   item = "license_drive_truck",  icon = "fas fa-truck" },
            drive_taxi  = { label = "Permis Taxi",              item = "license_drive_taxi",   icon = "fas fa-taxi" },
        },

        -- Amende fixe si conduite sans permis (prélevée via Bank de union)
        fine = 1500,

        -- Classes de véhicules qui nécessitent quel permis
        -- (utilisé côté client pour détecter le type de véhicule)
        vehicleClasses = {
            -- Classe GTA → type de permis requis
            -- 0=Compacts, 1=Sedans, 2=SUVs, 3=Coupes, 4=Muscle, 5=Sports Classics,
            -- 6=Sports, 7=Super, 8=Motorcycles, 9=Off-Road, 10=Industrial,
            -- 11=Utility, 12=Vans, 13=Cycles, 14=Boats, 15=Helicopters,
            -- 16=Planes, 17=Service, 18=Emergency, 19=Military, 20=Commercial, 21=Trains
            [0]  = "drive",
            [1]  = "drive",
            [2]  = "drive",
            [3]  = "drive",
            [4]  = "drive",
            [5]  = "drive",
            [6]  = "drive",
            [7]  = "drive",
            [8]  = "drive_bike",
            [9]  = "drive",
            [10] = "drive_truck",
            [11] = "drive_truck",
            [12] = "drive",
            [20] = "drive_truck",
        },
    },

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- PNJ FONCTIONNAIRE (carte d'identité)
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    npc = {
        model   = "s_m_m_civmale_01",
        heading = 180.0,
        coords  = vector3(-268.5, -957.8, 31.2),  -- ← modifier avec la vraie position

        interact = {
            label    = "Demander une carte d'identité",
            icon     = "fas fa-id-card",
            distance = 2.5,
        },
    },

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- PNJ AUTO-ÉCOLE (permis)
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    npcDriving = {
        model   = "s_m_m_dockwork_01",
        heading = 90.0,
        coords  = vector3(-800.0, -200.0, 37.0),  -- ← modifier avec la vraie position

        interact = {
            label    = "Auto-école — Passer un permis",
            icon     = "fas fa-graduation-cap",
            distance = 2.5,
        },
    },

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- RESSOURCES EXTERNES
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    resources = {
        union     = "union",
        inventory = "kt_inventory",
        interact  = "kt_interact",
    },

    debug = true,
}

return Config