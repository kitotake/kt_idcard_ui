// ─── NUI Message Types ───────────────────────────────────────────────────────

export type NuiAction =
  | 'showIdentity'
  | 'showLicenses'
  | 'showDrivingMenu'
  | 'hideIdentity'

export interface IdentityPayload {
  action: 'showIdentity'
  firstname: string
  lastname: string
  dateofbirth: string
  unique_id: string
  ped_model: string
  job: string
  job_label: string
  shown_by?: string
  is_police_check?: boolean
}

export interface LicenseEntry {
  type: string
  label: string
  icon: string
  valid: boolean
}

export interface LicensesPayload {
  action: 'showLicenses'
  firstname: string
  lastname: string
  unique_id: string
  licenses: LicenseEntry[]
  checked_by?: string
}

export interface DrivingLicenseEntry {
  type: string
  label: string
  icon: string
  owned: boolean
}

export interface DrivingMenuPayload {
  action: 'showDrivingMenu'
  licenses: DrivingLicenseEntry[]
}

export interface HidePayload {
  action: 'hideIdentity'
}

export type NuiPayload =
  | IdentityPayload
  | LicensesPayload
  | DrivingMenuPayload
  | HidePayload

// ─── App State ───────────────────────────────────────────────────────────────

export type ViewMode = 'identity' | 'licenses' | 'driving' | null
