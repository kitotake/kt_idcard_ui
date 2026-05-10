// ─── Card Types ───────────────────────────────────────────────────────────────

export type CardType =
  | 'identity'
  | 'driver'
  | 'weapon'
  | 'police'
  | 'mairie'
  | 'government'
  | 'ems'
  | 'company'
  | 'passport'
  | 'bank_card' 
  | 'bank_gold_card' 
  | 'bank_diamond_card'

export interface BankCardData {
  type: CardType
  cardNumber: string      // "4532 1234 5678 9012"
  holderName: string
  expiry: string          // "12/28"
  cvv: string
  cardNetwork: 'Visa' | 'Mastercard' | 'Amex'
  bankName: string
  iban?: string
  balance?: number
}

// ─── Shared fields ────────────────────────────────────────────────────────────

export interface BaseCardData {
  photo?: string            // base64 ou URL
  firstname: string
  lastname: string
  signature?: string        // base64 svg ou nom stylisé
  issued?: string
  expiry?: string
  uniqueId?: string
}

// ─── Identity ─────────────────────────────────────────────────────────────────

export interface IdentityCardData extends BaseCardData {
  type: 'identity'
  gender: 'M' | 'F'
  dateOfBirth: string
  height: string            // ex: "178 cm"
  nationality: string
}

// ─── Driver License ──────────────────────────────────────────────────────────

export interface DriverCardData extends BaseCardData {
  type: 'driver'
  licenseNumber: string
  categories: string[]      // ['A', 'B', 'C']
  points: number
  maxPoints: number
}

// ─── Weapon Permit ───────────────────────────────────────────────────────────

export interface WeaponCardData extends BaseCardData {
  type: 'weapon'
  licenseNumber: string
  authorizationType: string // "Port et détention"
  accessLevel: number       // 1-5
  legalStatus: 'VALID' | 'SUSPENDED' | 'REVOKED'
  allowedWeapons: string[]
}

// ─── Police ──────────────────────────────────────────────────────────────────

export interface PoliceCardData extends BaseCardData {
  type: 'police'
  badgeNumber: string
  rank: string
  department: string
  service: string
  accessLevel: number
  authorizations: string[]
  status: 'ACTIVE' | 'INACTIVE' | 'SUSPENDED'
}

// ─── Mairie ──────────────────────────────────────────────────────────────────

export interface MairieCardData extends BaseCardData {
  type: 'mairie'
  employeeId: string
  function: string
  officialSignature?: string
}

// ─── Government ──────────────────────────────────────────────────────────────

export interface GovernmentCardData extends BaseCardData {
  type: 'government'
  govId: string
  function: string
  securityLevel: number     // 1-5
  nationalDepartment: string
  specialAuthorizations: string[]
}

// ─── EMS ─────────────────────────────────────────────────────────────────────

export interface EMSCardData extends BaseCardData {
  type: 'ems'
  emsNumber: string
  medicalRank: string
  department: string
  bloodGroup: string
  medicalAuthorizations: string[]
  status: 'ACTIVE' | 'INACTIVE'
}

// ─── Company ─────────────────────────────────────────────────────────────────

export interface CompanyCardData extends BaseCardData {
  type: 'company'
  employeeId: string
  company: string
  position: string
  companyDepartment: string
  accessLevel: number
  companyLogo?: string      // emoji ou URL
}

// ─── Passport ────────────────────────────────────────────────────────────────

export interface PassportCardData extends BaseCardData {
  type: 'passport'
  passportNumber: string
  nationality: string
  dateOfBirth: string
  gender: 'M' | 'F'
  issuingCountry: string
  mrz: string               // Machine Readable Zone
}

// ─── Union ───────────────────────────────────────────────────────────────────

export type CardData =
  | IdentityCardData
  | DriverCardData
  | WeaponCardData
  | PoliceCardData
  | MairieCardData
  | GovernmentCardData
  | EMSCardData
  | CompanyCardData
  | PassportCardData
  | BankCardData

// ─── NUI Messages ────────────────────────────────────────────────────────────

export interface ShowCardPayload {
  action: 'showCard'
  cardType: CardType
  data: CardData
}

export interface HideCardPayload {
  action: 'hideCard'
}

export interface PhotoResultPayload {
  action: 'photoResult'
  photo: string
}

export type NuiPayload = ShowCardPayload | HideCardPayload | PhotoResultPayload
