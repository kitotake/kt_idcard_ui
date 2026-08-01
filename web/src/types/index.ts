// web/src/types/index.ts

export type CardType =
  | 'identity' | 'driver' | 'weapon' | 'police'
  | 'mairie' | 'government' | 'ems' | 'company' | 'passport'
  | 'bank_card' | 'bank_gold_card' | 'bank_diamond_card'

export interface CardTheme {
  name: string; accent: string; accentAlt: string
  gradFrom: string; gradVia: string; gradTo: string
  headerBg: string; chip: string
  textPrimary: string; textSecondary: string
  borderColor: string; holoBg: string; stripeColor: string
  icon: string; agency: string
}

export interface BankCardData {
  type: 'bank_card' | 'bank_gold_card' | 'bank_diamond_card'
  cardNumber: string; holderName: string
  expiry: string; cvv: string
  cardNetwork: 'Visa' | 'Mastercard' | 'Amex'
  bankName: string; iban?: string; balance?: number
}

export interface BaseCardData {
  photo?: string; firstname: string; lastname: string
  signature?: string; issued?: string; expiry?: string; uniqueId?: string
}

export interface IdentityCardData extends BaseCardData {
  type: 'identity'; gender: 'M' | 'F'; dateOfBirth: string; height: string; nationality: string
}
export interface DriverCardData extends BaseCardData {
  type: 'driver'; licenseNumber: string; categories: string[]; points: number; maxPoints: number
}
export interface WeaponCardData extends BaseCardData {
  type: 'weapon'; licenseNumber: string; authorizationType: string
  accessLevel: number; legalStatus: 'VALID' | 'SUSPENDED' | 'REVOKED'; allowedWeapons: string[]
}
export interface PoliceCardData extends BaseCardData {
  type: 'police'; badgeNumber: string; rank: string; department: string
  service: string; accessLevel: number; authorizations: string[]
  status: 'ACTIVE' | 'INACTIVE' | 'SUSPENDED'
}
export interface MairieCardData extends BaseCardData {
  type: 'mairie'; employeeId: string; function: string; officialSignature?: string
}
export interface GovernmentCardData extends BaseCardData {
  type: 'government'; govId: string; function: string
  securityLevel: number; nationalDepartment: string; specialAuthorizations: string[]
}
export interface EMSCardData extends BaseCardData {
  type: 'ems'; emsNumber: string; medicalRank: string; department: string
  bloodGroup: string; medicalAuthorizations: string[]; status: 'ACTIVE' | 'INACTIVE'
}
export interface CompanyCardData extends BaseCardData {
  type: 'company'; employeeId: string; company: string; position: string
  companyDepartment: string; accessLevel: number; companyLogo?: string
}
export interface PassportCardData extends BaseCardData {
  type: 'passport'; passportNumber: string; nationality: string
  dateOfBirth: string; gender: 'M' | 'F'; issuingCountry: string; mrz: string
}

export type CardData =
  | IdentityCardData | DriverCardData | WeaponCardData | PoliceCardData
  | MairieCardData | GovernmentCardData | EMSCardData | CompanyCardData
  | PassportCardData | BankCardData

// ─── NUI Payloads ─────────────────────────────────────────────────────────────

export interface ShowCardPayload   { action: 'showCard';    cardType: CardType; data: CardData }
export interface HideCardPayload   { action: 'hideCard' }
export interface PhotoResultPayload { action: 'photoResult'; photo: string }
export interface HideIdentityPayload { action: 'hideIdentity' }
export type NuiPayload =
  | ShowCardPayload
  | HideCardPayload
  | PhotoResultPayload
  | HideIdentityPayload

// ─── Types anciennement manquants (DrivingMenuView, LicensesView) ─────────────

export interface LicenseEntry {
  type: string
  label: string
  icon: string
  valid: boolean
  owned?: boolean
}

export interface LicensesPayload {
  action: 'showLicenses'
  firstname?: string
  lastname?: string
  unique_id?: string
  photo?: string
  licenses: LicenseEntry[]
  checked_by?: string
}

export interface DrivingMenuLicense {
  type: string
  label: string
  icon: string
  owned: boolean
}

export interface DrivingMenuPayload {
  action: 'showDrivingMenu'
  licenses: DrivingMenuLicense[]
}

// ─── Shop ─────────────────────────────────────────────────────────────────────

export interface ShopItem {
  id: string
  label: string
  desc: string
  price: number
  owned: boolean
}
