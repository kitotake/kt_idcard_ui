// web/src/data/mockData.ts
import type {
  IdentityCardData, DriverCardData, WeaponCardData, PoliceCardData,
  MairieCardData, GovernmentCardData, EMSCardData, CompanyCardData,
  PassportCardData, BankCardData,
} from '../types'

const fmt      = (d: Date) => d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' })
const addYears = (n: number) => { const d = new Date(); d.setFullYear(d.getFullYear() + n); return fmt(d) }
const subYears = (n: number) => { const d = new Date(); d.setFullYear(d.getFullYear() - n); return fmt(d) }

export const MOCK_IDENTITY: IdentityCardData = {
  type: 'identity', firstname: 'Alexandre', lastname: 'MOREAU',
  gender: 'M', dateOfBirth: '14/07/1994', height: '182 cm', nationality: 'Française',
  uniqueId: 'NID-2847-3910-FR', issued: subYears(2), expiry: addYears(8), signature: 'A. Moreau',
}

export const MOCK_DRIVER: DriverCardData = {
  type: 'driver', firstname: 'Alexandre', lastname: 'MOREAU',
  licenseNumber: 'FR-084-2019-00847', categories: ['A', 'B', 'C'],
  points: 9, maxPoints: 12, issued: subYears(5), expiry: addYears(10), signature: 'A. Moreau',
}

export const MOCK_WEAPON: WeaponCardData = {
  type: 'weapon', firstname: 'Alexandre', lastname: 'MOREAU',
  licenseNumber: 'WPN-0047-2021-FR', authorizationType: 'Port & Détention',
  accessLevel: 3, legalStatus: 'VALID', allowedWeapons: ['Pistolet semi-auto', 'Fusil à pompe'],
  issued: subYears(3), expiry: addYears(2), signature: 'A. Moreau',
}

export const MOCK_POLICE: PoliceCardData = {
  type: 'police', firstname: 'Alexandre', lastname: 'MOREAU',
  badgeNumber: 'LSPD-4721', rank: 'Lieutenant', department: 'Los Santos Police Dept.',
  service: 'Brigade Criminelle', accessLevel: 4,
  authorizations: ['Arrestation', 'Perquisition', 'Usage de force', 'Accès aux fichiers'],
  status: 'ACTIVE', issued: subYears(1), expiry: addYears(4), signature: 'A. Moreau',
}

export const MOCK_MAIRIE: MairieCardData = {
  type: 'mairie', firstname: 'Isabelle', lastname: 'FONTAINE',
  function: 'Responsable Urbanisme', employeeId: 'MRE-2024-0391',
  issued: subYears(2), expiry: addYears(3), signature: 'I. Fontaine',
  officialSignature: 'Mairie de Los Santos',
}

export const MOCK_GOVERNMENT: GovernmentCardData = {
  type: 'government', firstname: 'Julien', lastname: 'BERTRAND',
  function: "Secrétaire d'État", govId: 'GOV-FR-0047-ALPHA', securityLevel: 5,
  nationalDepartment: 'Ministère de la Justice',
  specialAuthorizations: ['Accès classifié Δ', 'Commande sécurisée', 'Zone restreinte'],
  issued: subYears(1), expiry: addYears(5), signature: 'J. Bertrand',
}

export const MOCK_EMS: EMSCardData = {
  type: 'ems', firstname: 'Camille', lastname: 'DURAND',
  emsNumber: 'EMS-LS-0847', medicalRank: 'Médecin Urgentiste',
  department: 'SAMU Los Santos', bloodGroup: 'A+',
  medicalAuthorizations: ['Chirurgie', 'Triage', 'Défibrillation', 'Prescriptions'],
  status: 'ACTIVE', issued: subYears(3), expiry: addYears(2), signature: 'C. Durand',
}

export const MOCK_COMPANY: CompanyCardData = {
  type: 'company', firstname: 'Thomas', lastname: 'LEMAIRE',
  company: 'Weazel News Corp.', position: 'Directeur Technique',
  companyDepartment: 'IT & Infrastructure', employeeId: 'WNZ-EMP-2847',
  accessLevel: 3, companyLogo: '📡', issued: subYears(1), expiry: addYears(2),
  signature: 'T. Lemaire',
}

export const MOCK_PASSPORT: PassportCardData = {
  type: 'passport', firstname: 'Marie', lastname: 'LECLERC',
  nationality: 'Française', dateOfBirth: '22/03/1991', gender: 'F',
  passportNumber: 'FRP47291038', issuingCountry: 'FRANCE',
  mrz: 'P<FRALECLERC<<MARIE<<<<<<<<<<<<<<<<<<<<<\nFRP472910382FRA9103228F3005316<<<<<<<<<4',
  issued: subYears(1), expiry: addYears(9), signature: 'M. Leclerc',
}

export const MOCK_BANK_CARD: BankCardData = {
  type: 'bank_card', cardNumber: '4532 1847 6392 0174', holderName: 'ALEXANDRE MOREAU',
  expiry: '09/28', cvv: '847', cardNetwork: 'Visa', bankName: 'Maze Bank',
  iban: 'FR76 3000 6000 0112 3456 7890 189', balance: 24580,
}

export const MOCK_GOLD_CARD: BankCardData = {
  type: 'bank_gold_card', cardNumber: '5412 7539 2648 1037', holderName: 'THOMAS LEMAIRE',
  expiry: '03/30', cvv: '392', cardNetwork: 'Mastercard', bankName: 'Maze Bank',
  iban: 'FR76 3000 6000 0198 7654 3210 456', balance: 284700,
}

export const MOCK_DIAMOND_CARD: BankCardData = {
  type: 'bank_diamond_card', cardNumber: '3782 822463 10005', holderName: 'JULIEN BERTRAND',
  expiry: '11/31', cvv: '7294', cardNetwork: 'Amex', bankName: 'Maze Bank',
  iban: 'FR76 3000 6000 0100 0000 0001 337', balance: 4750000,
}

export const ALL_MOCKS: Record<string, unknown> = {
  identity:          MOCK_IDENTITY,
  driver:            MOCK_DRIVER,
  weapon:            MOCK_WEAPON,
  police:            MOCK_POLICE,
  mairie:            MOCK_MAIRIE,
  government:        MOCK_GOVERNMENT,
  ems:               MOCK_EMS,
  company:           MOCK_COMPANY,
  passport:          MOCK_PASSPORT,
  bank_card:         MOCK_BANK_CARD,
  bank_gold_card:    MOCK_GOLD_CARD,
  bank_diamond_card: MOCK_DIAMOND_CARD,
}
