# kt_idcard_ui v3.3.0 — Système de cartes premium

Système UI React premium pour serveur GTA RP / FiveM.  
**9 types de cartes identité** + **3 cartes bancaires** + **boutique documents**.

---

## Changements v3.3.0 (correctifs)

| # | Sévérité | Correction |
|---|---|---|
| FIX-1 | 🔴 | `IdentityView.tsx` supprimé — doublon de `IDCard.tsx` jamais importé |
| FIX-2 | 🔴 | `shop_ped.lua` — condition `not X == Y` toujours fausse → `X ~= Y` |
| FIX-3 | 🔴 | `photo_capture.lua` — Option B inaccessible quand screenshot-basic absent |
| FIX-4 | 🔴 | `showToNearby` — données correctes par cardType (police, driver, identity) |
| FIX-5 | 🔴 | `shop.lua` — catalogue vide bloquait le menu boutique |
| FIX-6 | 🔴 | `shop_ped.lua` — `shopZoneRegistered` non réinitialisé si ped inexistant |
| FIX-7 | 🟠 | `showToNearby` — vérification item/job avant diffusion |
| FIX-8 | 🟠 | `idcard:license:check` — feedback explicite si débit échoue |
| FIX-9 | 🟠 | Rate limiting sur contrôles policiers (10s par cible par officier) |
| FIX-10 | 🟠 | `photo_save.lua` — whitelist domaines photo (plus permissive → sécurisée) |
| FIX-11 | 🟠 | `NuiState` module partagé (remplace `nuiOpen` local fragile) |
| FIX-12 | 🟡 | `App.tsx` — `handleCardClose` n'appelle que l'endpoint du bon type |
| FIX-13 | 🟡 | `BankCardComponent` — animation Framer Motion (cohérent avec les autres cartes) |
| FIX-14 | 🟡 | `npc_helpers.lua` retiré du manifest (jamais utilisé) |
| FIX-15 | 🟡 | Numéros badge/permis persistants via `user_licenses_meta` |
| FIX-16 | 🟡 | `sql/migrations.sql` — `ADD INDEX IF NOT EXISTS` compatible MySQL 5.7+ |
| FIX-17 | 🟡 | `sql/migrations.sql` — purge automatique `police_checks_log` (90 jours) |
| FIX-18 | 🟡 | `types/index.ts` — `DrivingMenuPayload`, `LicensesPayload`, `ShopItem` ajoutés |
| FIX-19 | 🟡 | `shared/locales/fr.lua` — complété avec toutes les chaînes |
| FIX-20 | 🟡 | `shop.lua` — `SetTimeout` → `Citizen.SetTimeout` |

---

## Types de cartes

| Type | Clé | Couleur |
|------|-----|---------|
| Carte d'identité | `identity` | Bleu royal |
| Permis de conduire | `driver` | Vert officiel |
| Permis de port d'arme | `weapon` | Rouge crimson |
| Carte de police | `police` | Bleu nuit / Or |
| Carte de mairie | `mairie` | Violet |
| Carte gouvernementale | `government` | Or / Ambre |
| Carte EMS | `ems` | Cyan médical |
| Badge entreprise | `company` | Ardoise |
| Passeport | `passport` | Bleu marine + MRZ |
| Carte bancaire Classic | `bank_card` | Sombre / Bleu |
| Carte bancaire Gold | `bank_gold_card` | Or |
| Carte bancaire Diamond | `bank_diamond_card` | Cyan / Diamant |

---

## Installation

### 1. Build le web

```bash
cd web
npm install
npm run build
```

### 2. Structure dans FiveM

```
resources/
  kt_idcard_ui/
    client/
      logger_client.lua
      main.lua
      shop_ped.lua
      photo_capture.lua
    server/
      logger.lua
      main.lua
      shop.lua
      photo_save.lua
    shared/
      config/config.lua
      locales/fr.lua
    sql/
      migrations.sql
    web/dist/
    fxmanifest.lua
```

### 3. SQL

```bash
# Exécuter une seule fois
mysql -u root -p ma_base < sql/migrations.sql
```

Tables créées :
- `user_licenses` — permis de conduire
- `user_licenses_meta` — numéros persistants (badge, arme, EMS)
- `police_checks_log` — traçabilité contrôles (purgé auto après 90j)
- Colonne `photo_url` sur `user_character`

---

## Usage depuis Lua

### Afficher une carte (export serveur)

```lua
exports["kt_idcard_ui"]:ShowCard(src, "identity", {
    type        = "identity",
    firstname   = "Jean",
    lastname    = "DUPONT",
    gender      = "M",
    dateOfBirth = "14/07/1990",
    height      = "180 cm",
    nationality = "Française",
    uniqueId    = "NID-1234-5678-FR",
    issued      = "01/01/2023",
    expiry      = "01/01/2033",
    signature   = "J. Dupont",
})
```

### Exports disponibles

```lua
exports["kt_idcard_ui"]:ShowCard(src, cardType, data)
exports["kt_idcard_ui"]:UseIdentityCard(src)
exports["kt_idcard_ui"]:UseLicenseCard(src)
exports["kt_idcard_ui"]:UseWeaponCard(src)   -- numéro persistant
exports["kt_idcard_ui"]:UsePoliceCard(src)   -- numéro persistant
exports["kt_idcard_ui"]:UseEMSCard(src)      -- numéro persistant
exports["kt_idcard_ui"]:UsePassport(src)
exports["kt_idcard_ui"]:FetchPhotoAndSend(src, cardType, payload)
```

### NUI Messages (depuis Lua client)

```lua
-- Afficher une carte
SendNUIMessage({ action = "showCard", cardType = "police", data = { ... } })

-- Masquer
SendNUIMessage({ action = "hideCard" })

-- Ouvrir la boutique
SendNUIMessage({ action = "openShop", items = { ... } })
```

---

## Architecture React

```
web/src/
  types/index.ts          — Types TypeScript (CardType, CardData, ShopItem, etc.)
  data/
    themes.ts             — Couleurs et identité visuelle par carte
    mockData.ts           — Données de test réalistes
  hooks/
    useNui.ts             — Bridge FiveM NUI ↔ React
  components/
    IDCard.tsx            — Composant principal (9 types identité)
    BankCardComponent.tsx — 3 cartes bancaires (Classic, Gold, Diamond)
    CardParts.tsx         — Composants réutilisables (photo, QR, badge...)
    ShopMenu.tsx          — Interface boutique documents
    FrenchFlag.tsx        — Drapeau tricolore SVG
    GuillochesBg.tsx      — Fond de sécurité guilloché
  styles/
    main.scss             — Animations, overlay, tab bar dev
  App.tsx                 — Machine d'état NUI + sélecteur dev
  main.tsx               — Point d'entrée React
```

---

## Dépendances

- `react` + `react-dom` ^18
- `framer-motion` ^11 — animations (utilisé sur toutes les cartes)
- `qrcode.react` ^4 — QR codes
- `@fortawesome/react-fontawesome` + solid + regular icons
- `sass` — SCSS
- `vite` + `@vitejs/plugin-react` + `typescript`

---

## Développement

```bash
cd web
npm run dev
```

Le sélecteur de cartes (tab bar) est visible uniquement en mode `DEV`.  
Toutes les cartes sont pré-remplies avec des données fictives françaises réalistes.

---

## Sécurité

- Contrôles policiers : rate limiting 10s par (officier, cible, type)
- Photos : whitelist de domaines autorisés (configurable dans `photo_save.lua`)
- Achats boutique : debounce anti-doublon côté serveur
- `showToNearby` : vérification item/job avant diffusion
- Logs de contrôle purgés automatiquement après 90 jours

---

*kt_idcard_ui v3.3.0 — Kitotake*
