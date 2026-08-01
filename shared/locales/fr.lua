-- shared/locales/fr.lua
-- Chaînes de localisation françaises pour kt_idcard_ui v3
-- Usage (côté serveur) :
--   local msg = Locale.get("identity_created")
--   notify(src, msg, "success")

Locale = Locale or {}

local strings = {
    -- Identité
    identity_created        = "Votre carte d'identité a été créée.",
    identity_no_char        = "Aucun personnage actif.",
    identity_not_found      = "Carte d'identité introuvable.",

    -- Permis
    license_required        = "Permis de catégorie %s requis. Tentative d'amende : $%d",
    license_fine_deducted   = "Amende de $%d prélevée pour conduite sans permis %s.",
    license_fine_no_balance = "Solde insuffisant pour l'amende. Convocation au tribunal.",
    license_check_failed    = "Impossible de vérifier le permis.",

    -- Police
    police_not_officer      = "Vous n'êtes pas policier.",
    police_not_found        = "Joueur introuvable.",
    police_target_not_cop   = "Cette personne n'est pas agent de police.",
    police_cooldown         = "Veuillez patienter avant un nouveau contrôle.",

    -- Boutique
    shop_no_char            = "Aucun personnage actif.",
    shop_buy_pending        = "Un achat est déjà en cours.",
    shop_item_not_found     = "Article introuvable.",
    shop_already_owned_lic  = "Vous possédez déjà ce permis.",
    shop_already_owned_item = "Vous possédez déjà ce document.",
    shop_balance_low        = "Solde insuffisant. Prix : $%d",
    shop_bank_error         = "Erreur bancaire, réessayez.",
    shop_success            = "✅ %s acheté pour $%d",

    -- Cartes proches
    nearby_no_identity      = "Vous n'avez pas de carte d'identité.",
    nearby_no_license       = "Vous n'avez pas de permis de conduire.",
    nearby_no_badge         = "Vous n'avez pas de badge de police.",
}

-- Récupère une chaîne localisée avec support des arguments de format
function Locale.get(key, ...)
    local s = strings[key]
    if not s then
        print(("^3[LOCALE]^7 Clé manquante : %s"):format(tostring(key)))
        return key
    end
    if select('#', ...) > 0 then
        return s:format(...)
    end
    return s
end
