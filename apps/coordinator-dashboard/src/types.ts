export type SupportedLanguage = "en" | "hi" | "mr";
export type ThemePreference = "light" | "dark";
export type NeedSourceChannel = "field_app" | "field_web" | "dashboard" | "telegram" | "sms" | "other";

export type Role = "admin" | "coordinator" | "field_agent" | "volunteer";

export type NeedStatus =
  | "open"
  | "triaged"
  | "assigned"
  | "in_progress"
  | "resolved"
  | "closed"
  | "rejected";

export type VolunteerStatus = "available" | "busy" | "offline";

export type TaskStatus =
  | "offered"
  | "accepted"
  | "in_progress"
  | "completed"
  | "declined"
  | "cancelled";

export interface AppSession {
  uid: string;
  email: string;
  displayName: string;
  phone: string;
  role: Role;
  roles: Role[];
  organizationIds: string[];
  preferredLanguage: SupportedLanguage;
  notificationsEnabled: boolean;
  emergencyAlertsEnabled: boolean;
}

export interface NeedRecord {
  id: string;
  organizationId: string;
  title: string;
  description: string;
  needType: string;
  urgency: number;
  peopleAffected: number;
  locationName: string;
  lat: number;
  lng: number;
  status: NeedStatus;
  priorityScore: number;
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  createdByName?: string;
  assignedVolunteerId?: string;
  assignedTaskId?: string;
  beneficiaryName: string;
  beneficiaryPhone: string;
  preferredLanguage: SupportedLanguage;
  verificationStatus: string;
  reviewRequired: boolean;
  escalationFlag: boolean;
  vulnerabilityTags: string[];
  sourceChannel: NeedSourceChannel;
}

export interface VolunteerRecord {
  id: string;
  organizationId: string;
  name: string;
  email: string;
  phone: string;
  skills: string[];
  languages: SupportedLanguage[];
  status: VolunteerStatus;
  currentTaskCount: number;
  lat: number;
  lng: number;
  serviceRadiusKm: number;
  lastActiveAt: string;
}

export interface FieldAgentRecord {
  id: string;
  organizationId: string;
  displayName: string;
  phone: string;
  assignedRegions: string[];
  deviceLastSeenAt: string;
  appVersion: string;
  syncHealth: string;
}

export interface TaskRecord {
  id: string;
  organizationId: string;
  needId: string;
  volunteerId: string;
  needTitle: string;
  volunteerName: string;
  assignedBy: string;
  status: TaskStatus;
  createdAt: string;
  completionNotes: string;
  acceptedAt?: string;
  completedAt?: string;
}

export interface AuditEventRecord {
  id: string;
  organizationId: string;
  entityType: string;
  entityId: string;
  eventType: string;
  actorRole: string;
  summary: string;
  createdAt: string;
}

export interface DraftNeedInput {
  title: string;
  description: string;
  needType: string;
  urgency: number;
  peopleAffected: number;
  locationName: string;
  lat: string;
  lng: string;
}

export interface ProfileFormInput {
  displayName: string;
  phone: string;
  preferredLanguage: SupportedLanguage;
  notificationsEnabled: boolean;
  emergencyAlertsEnabled: boolean;
}
