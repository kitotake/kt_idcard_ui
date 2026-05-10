# kt_idcard_ui v3 — Système de cartes premium

Système UI React premium pour serveur GTA RP / FiveM.  
**9 types de cartes** avec design AAA, animations Framer Motion, style gouvernement USA.

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

---

## Installation

### 1. Build le web

```bash
cd html
npm install
npm run build
```

### 2. Placer dans FiveM

```
resources/
  kt_idcard_ui/
    client/main.lua
    server/main.lua
    shared/config/config.lua
    html/dist/         ← build React
    fxmanifest.lua
```

### 3. Mise à jour fxmanifest.lua

```lua
ui_page 'html/dist/index.html'

files {
    'html/dist/index.html',
    'html/dist/assets/*.js',
    'html/dist/assets/*.css',
}
```

### 4. SQL (si pas déjà en place)

```sql
-- Permis
CREATE TABLE IF NOT EXISTS user_licenses (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(60) NOT NULL,
  unique_id  VARCHAR(60) NOT NULL,
  type       VARCHAR(30) NOT NULL,
  UNIQUE KEY uq_license (unique_id, type)
);

-- Photo ID (optionnel)
ALTER TABLE user_character ADD COLUMN photo_url TEXT DEFAULT NULL;
```

---

## Usage depuis Lua

### Afficher une carte

```lua
-- Côté serveur
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
exports["kt_idcard_ui"]:UseWeaponCard(src)
exports["kt_idcard_ui"]:UsePoliceCard(src)
exports["kt_idcard_ui"]:UseEMSCard(src)
exports["kt_idcard_ui"]:UsePassport(src)
```

### Items kt_inventory (config/config.lua)

```lua
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
}
```

### NUI Messages (depuis Lua client)

```lua
SendNUIMessage({
    action   = "showCard",
    cardType = "police",
    data     = { ... }
})

SendNUIMessage({ action = "hideCard" })
```

---

## Architecture React

```
src/
  types/index.ts        — Types TypeScript pour les 9 cartes
  data/
    themes.ts           — Couleurs et identité visuelle par carte
    mockData.ts         — Données de test réalistes
  hooks/
    useNui.ts           — Bridge FiveM NUI
  components/
    IDCard.tsx          — Composant principal (9 sous-composants)
    CardParts.tsx       — Composants réutilisables (photo, QR, badge...)
  styles/
    main.scss           — Animations, overlay, tab bar dev
  App.tsx               — Machine d'état NUI + sélecteur dev
```

### Utilisation React

```tsx
import { IDCard } from './components/IDCard'

<IDCard type="identity" data={identityData} />
<IDCard type="police"   data={policeData} />
<IDCard type="passport" data={passportData} />
```

---

## Dépendances

- `react` + `react-dom` ^18
- `framer-motion` ^11 — animations
- `qrcode.react` ^4 — QR codes
- `@fortawesome/react-fontawesome` + solid + regular icons
- `sass` — SCSS
- `vite` + `@vitejs/plugin-react` + `typescript`

---

## Développement

```bash
cd html
npm run dev
```

Le sélecteur de cartes (tab bar) est visible uniquement en mode `DEV`.  
Toutes les cartes sont pré-remplies avec des données fictives françaises réalistes.

---

*kt_idcard_ui v3 — Kitotake*
