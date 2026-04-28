import {
  createUserWithEmailAndPassword,
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut,
  updateProfile,
  type User
} from "firebase/auth";
import {
  collection,
  doc,
  getDoc,
  onSnapshot,
  query,
  setDoc,
  where,
  writeBatch,
  type Firestore
} from "firebase/firestore";
import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type PropsWithChildren
} from "react";
import { getFirebaseAuth, getFirebaseFirestore, firebaseConfigured } from "../lib/firebase";
import type {
  AuditEventRecord,
  AppSession,
  DraftNeedInput,
  FieldAgentRecord,
  NeedRecord,
  NeedSourceChannel,
  ProfileFormInput,
  Role,
  SupportedLanguage,
  TaskRecord,
  ThemePreference,
  VolunteerRecord
} from "../types";

interface AppStateContextValue {
  authConfigured: boolean;
  authError: string | null;
  clearAuthError(): void;
  loading: boolean;
  session: AppSession | null;
  needs: NeedRecord[];
  volunteers: VolunteerRecord[];
  fieldAgents: FieldAgentRecord[];
  tasks: TaskRecord[];
  events: AuditEventRecord[];
  selectedNeedId: string | null;
  selectedNeed: NeedRecord | null;
  theme: ThemePreference;
  signInWithEmail(email: string, password: string): Promise<void>;
  signUpWithEmail(email: string, password: string, displayName: string): Promise<void>;
  signInWithGoogle(): Promise<void>;
  logout(): Promise<void>;
  toggleTheme(): void;
  selectNeed(needId: string | null): void;
  createNeed(input: DraftNeedInput): Promise<void>;
  assignNeed(needId: string, volunteerId: string): Promise<void>;
  completeTask(taskId: string): Promise<void>;
  saveProfile(input: ProfileFormInput): Promise<void>;
}

const AppStateContext = createContext<AppStateContextValue | null>(null);
const themeStorageKey = "guardians-theme";

function normalizeSourceChannel(raw: unknown): NeedSourceChannel {
  switch (String(raw ?? "")) {
    case "field_app":
    case "field_web":
    case "dashboard":
    case "telegram":
    case "sms":
      return String(raw) as NeedSourceChannel;
    default:
      return "other";
  }
}

function parseNeed(rawId: string, raw: Record<string, unknown>): NeedRecord {
  const location = (raw.location as Record<string, unknown> | undefined) ?? {};

  return {
    id: rawId,
    organizationId: String(raw.organization_id ?? ""),
    title: String(raw.title ?? ""),
    description: String(raw.description ?? ""),
    needType: String(raw.need_type ?? ""),
    urgency: Number(raw.urgency_input ?? 1),
    peopleAffected: Number(raw.people_affected ?? 1),
    locationName: String(location.address_text ?? ""),
    lat: Number(location.lat ?? 0),
    lng: Number(location.lng ?? 0),
    status: String(raw.status ?? "open") as NeedRecord["status"],
    priorityScore: Number(raw.priority_score ?? 0),
    createdAt: String(raw.created_at ?? new Date().toISOString()),
    updatedAt: String(raw.updated_at ?? new Date().toISOString()),
    createdBy: String(raw.created_by ?? ""),
    assignedVolunteerId:
      raw.assigned_volunteer_id == null ? undefined : String(raw.assigned_volunteer_id),
    assignedTaskId: raw.assigned_task_id == null ? undefined : String(raw.assigned_task_id),
    beneficiaryName: String(raw.beneficiary_name ?? ""),
    beneficiaryPhone: String(raw.beneficiary_phone ?? ""),
    preferredLanguage: String(raw.preferred_language ?? "en") as SupportedLanguage,
    verificationStatus: String(raw.verification_status ?? "pending"),
    reviewRequired: Boolean(raw.review_required ?? false),
    escalationFlag: Boolean(raw.escalation_flag ?? false),
    vulnerabilityTags: Array.isArray(raw.vulnerability_tags)
      ? raw.vulnerability_tags.map(String)
      : [],
    sourceChannel: normalizeSourceChannel(raw.source_channel)
  };
}

function parseVolunteer(rawId: string, raw: Record<string, unknown>): VolunteerRecord {
  const homeLocation = (raw.home_location as Record<string, unknown> | undefined) ?? {};

  return {
    id: rawId,
    organizationId: String(raw.organization_id ?? ""),
    name: String(raw.name ?? ""),
    email: String(raw.email ?? ""),
    phone: String(raw.phone ?? ""),
    skills: Array.isArray(raw.skills) ? raw.skills.map(String) : [],
    languages: Array.isArray(raw.languages)
      ? (raw.languages.map(String) as SupportedLanguage[])
      : ["en"],
    status: String(raw.availability_status ?? "offline") as VolunteerRecord["status"],
    currentTaskCount: Number(raw.current_task_count ?? 0),
    lat: Number(homeLocation.lat ?? 0),
    lng: Number(homeLocation.lng ?? 0),
    serviceRadiusKm: Number(raw.service_radius_km ?? 0),
    lastActiveAt: String(raw.last_active_at ?? new Date().toISOString())
  };
}

function parseFieldAgent(rawId: string, raw: Record<string, unknown>): FieldAgentRecord {
  return {
    id: rawId,
    organizationId: String(raw.organization_id ?? ""),
    displayName: String(raw.display_name ?? raw.name ?? "Field agent"),
    phone: String(raw.phone ?? ""),
    assignedRegions: Array.isArray(raw.assigned_regions) ? raw.assigned_regions.map(String) : [],
    deviceLastSeenAt: String(raw.device_last_seen_at ?? new Date().toISOString()),
    appVersion: String(raw.app_version ?? ""),
    syncHealth: String(raw.sync_health ?? "unknown")
  };
}

function parseTask(rawId: string, raw: Record<string, unknown>): TaskRecord {
  return {
    id: rawId,
    organizationId: String(raw.organization_id ?? ""),
    needId: String(raw.need_id ?? ""),
    volunteerId: String(raw.volunteer_id ?? ""),
    needTitle: String(raw.need_title ?? ""),
    volunteerName: String(raw.volunteer_name ?? ""),
    assignedBy: String(raw.assigned_by ?? ""),
    status: String(raw.status ?? "offered") as TaskRecord["status"],
    createdAt: String(raw.created_at ?? new Date().toISOString()),
    completionNotes: String(raw.completion_notes ?? ""),
    acceptedAt: raw.accepted_at == null ? undefined : String(raw.accepted_at),
    completedAt: raw.completed_at == null ? undefined : String(raw.completed_at)
  };
}

function parseEvent(rawId: string, raw: Record<string, unknown>): AuditEventRecord {
  return {
    id: rawId,
    organizationId: String(raw.organization_id ?? ""),
    entityType: String(raw.entity_type ?? ""),
    entityId: String(raw.entity_id ?? ""),
    eventType: String(raw.event_type ?? ""),
    actorRole: String(raw.actor_role ?? ""),
    summary: String(raw.summary ?? ""),
    createdAt: String(raw.created_at ?? new Date().toISOString())
  };
}

function parseSession(user: User, raw: Record<string, unknown>): AppSession {
  const roles = (
    Array.isArray(raw.roles) ? raw.roles.map(String) : ["coordinator"]
  ) as Role[];
  const activeRole = String(raw.active_role ?? roles[0] ?? "coordinator") as Role;

  return {
    uid: user.uid,
    email: String(raw.email ?? user.email ?? ""),
    displayName: String(raw.display_name ?? user.displayName ?? "Guardians User"),
    phone: String(raw.phone ?? ""),
    role: activeRole,
    roles,
    organizationIds: Array.isArray(raw.organization_ids)
      ? raw.organization_ids.map(String)
      : [],
    preferredLanguage: String(raw.preferred_language ?? "en") as SupportedLanguage,
    notificationsEnabled: Boolean(raw.notifications_enabled ?? true),
    emergencyAlertsEnabled: Boolean(raw.emergency_alerts_enabled ?? true)
  };
}

function loadStoredTheme(): ThemePreference {
  const stored = window.localStorage.getItem(themeStorageKey);
  return stored === "dark" ? "dark" : "light";
}

export function AppStateProvider({ children }: PropsWithChildren) {
  const auth = getFirebaseAuth();
  const db = getFirebaseFirestore();

  const [loading, setLoading] = useState(true);
  const [authError, setAuthError] = useState<string | null>(null);
  const [session, setSession] = useState<AppSession | null>(null);
  const [needs, setNeeds] = useState<NeedRecord[]>([]);
  const [volunteers, setVolunteers] = useState<VolunteerRecord[]>([]);
  const [fieldAgents, setFieldAgents] = useState<FieldAgentRecord[]>([]);
  const [tasks, setTasks] = useState<TaskRecord[]>([]);
  const [events, setEvents] = useState<AuditEventRecord[]>([]);
  const [selectedNeedId, setSelectedNeedId] = useState<string | null>(null);
  const [theme, setTheme] = useState<ThemePreference>(loadStoredTheme);

  useEffect(() => {
    document.body.classList.toggle("theme-dark", theme === "dark");
    document.body.classList.toggle("theme-light", theme === "light");
    window.localStorage.setItem(themeStorageKey, theme);
  }, [theme]);

  useEffect(() => {
    if (!auth || !db) {
      setLoading(false);
      setNeeds([]);
      setVolunteers([]);
      setFieldAgents([]);
      setTasks([]);
      setEvents([]);
      setSession(null);
      return;
    }

    const unsubscribe = onAuthStateChanged(auth, async (user: User | null) => {
      if (!user) {
        setSession(null);
        setNeeds([]);
        setVolunteers([]);
        setFieldAgents([]);
        setTasks([]);
        setEvents([]);
        setLoading(false);
        return;
      }

      try {
        const nextSession = await ensureCoordinatorProfile(user, db);
        setSession(nextSession);
        setAuthError(null);
      } catch (error) {
        await signOut(auth);
        setSession(null);
        setAuthError(
          error instanceof Error
            ? error.message
            : "This account is not authorized for the coordinator dashboard."
        );
      } finally {
        setLoading(false);
      }
    });

    return unsubscribe;
  }, [auth, db]);

  useEffect(() => {
    if (!db || !session) {
      return;
    }

    const organizationId = session.organizationIds[0];
    const needsQuery = query(
      collection(db, "needs"),
      where("organization_id", "==", organizationId)
    );
    const volunteersQuery = query(
      collection(db, "volunteers"),
      where("organization_id", "==", organizationId)
    );
    const fieldAgentsQuery = query(
      collection(db, "field_agents"),
      where("organization_id", "==", organizationId)
    );
    const tasksQuery = query(
      collection(db, "tasks"),
      where("organization_id", "==", organizationId)
    );
    const eventsQuery = query(
      collection(db, "events"),
      where("organization_id", "==", organizationId)
    );

    const unsubscribeNeeds = onSnapshot(needsQuery, (snapshot) => {
      const nextNeeds = snapshot.docs
        .map((item) => parseNeed(item.id, item.data() as Record<string, unknown>))
        .sort(
          (left, right) =>
            right.priorityScore - left.priorityScore ||
            right.updatedAt.localeCompare(left.updatedAt)
        );
      setNeeds(nextNeeds);
    });

    const unsubscribeVolunteers = onSnapshot(volunteersQuery, (snapshot) => {
      const nextVolunteers = snapshot.docs
        .map((item) => parseVolunteer(item.id, item.data() as Record<string, unknown>))
        .sort((left, right) => left.name.localeCompare(right.name));
      setVolunteers(nextVolunteers);
    });

    const unsubscribeFieldAgents = onSnapshot(fieldAgentsQuery, (snapshot) => {
      const nextFieldAgents = snapshot.docs
        .map((item) => parseFieldAgent(item.id, item.data() as Record<string, unknown>))
        .sort((left, right) => right.deviceLastSeenAt.localeCompare(left.deviceLastSeenAt));
      setFieldAgents(nextFieldAgents);
    });

    const unsubscribeTasks = onSnapshot(tasksQuery, (snapshot) => {
      const nextTasks = snapshot.docs
        .map((item) => parseTask(item.id, item.data() as Record<string, unknown>))
        .sort((left, right) => right.createdAt.localeCompare(left.createdAt));
      setTasks(nextTasks);
    });

    const unsubscribeEvents = onSnapshot(eventsQuery, (snapshot) => {
      const nextEvents = snapshot.docs
        .map((item) => parseEvent(item.id, item.data() as Record<string, unknown>))
        .sort((left, right) => right.createdAt.localeCompare(left.createdAt));
      setEvents(nextEvents);
    });

    return () => {
      unsubscribeNeeds();
      unsubscribeVolunteers();
      unsubscribeFieldAgents();
      unsubscribeTasks();
      unsubscribeEvents();
    };
  }, [db, session]);

  useEffect(() => {
    if (needs.length === 0) {
      setSelectedNeedId(null);
      return;
    }

    if (!selectedNeedId || !needs.some((need) => need.id === selectedNeedId)) {
      setSelectedNeedId(needs[0]?.id ?? null);
    }
  }, [needs, selectedNeedId]);

  const value = useMemo<AppStateContextValue>(
    () => ({
      authConfigured: firebaseConfigured,
      authError,
      clearAuthError() {
        setAuthError(null);
      },
      loading,
      session,
      needs,
      volunteers,
      fieldAgents,
      tasks,
      events,
      selectedNeedId,
      selectedNeed: needs.find((need) => need.id === selectedNeedId) ?? null,
      theme,
      async signInWithEmail(email, password) {
        if (!auth || !db) {
          throw new Error("Firebase is not configured for this dashboard.");
        }

        const credential = await signInWithEmailAndPassword(auth, email, password);
        await ensureCoordinatorProfile(credential.user, db);
        setAuthError(null);
      },
      async signUpWithEmail(email, password, displayName) {
        if (!auth || !db) {
          throw new Error("Firebase is not configured for this dashboard.");
        }

        const credential = await createUserWithEmailAndPassword(auth, email, password);
        await updateProfile(credential.user, { displayName: displayName.trim() });
        await ensureCoordinatorProfile(credential.user, db, displayName.trim());
        setAuthError(null);
      },
      async signInWithGoogle() {
        if (!auth || !db) {
          throw new Error("Firebase is not configured for this dashboard.");
        }

        const provider = new GoogleAuthProvider();
        const result = await signInWithPopup(auth, provider);
        await ensureCoordinatorProfile(result.user, db);
        setAuthError(null);
      },
      async logout() {
        if (!auth) {
          return;
        }
        await signOut(auth);
      },
      toggleTheme() {
        setTheme((current) => (current === "dark" ? "light" : "dark"));
      },
      selectNeed(needId) {
        setSelectedNeedId(needId);
      },
      async createNeed(input) {
        if (!db || !session) {
          throw new Error("You must be signed in before creating a need.");
        }

        const organizationId = session.organizationIds[0];
        if (!organizationId) {
          throw new Error("This account is missing organization membership.");
        }

        const latitude = Number(input.lat);
        const longitude = Number(input.lng);
        if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90) {
          throw new Error("Enter a valid latitude between -90 and 90.");
        }
        if (!Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
          throw new Error("Enter a valid longitude between -180 and 180.");
        }

        const needId = `need-${crypto.randomUUID()}`;
        const timestamp = new Date().toISOString();
        await setDoc(doc(db, "needs", needId), {
          organization_id: organizationId,
          source_channel: "dashboard",
          title: input.title.trim(),
          description: input.description.trim(),
          need_type: input.needType,
          urgency_input: Number(input.urgency),
          people_affected: Number(input.peopleAffected),
          beneficiary_name: "",
          beneficiary_phone: "",
          preferred_language: session.preferredLanguage,
          consent_captured: true,
          verification_status: "verified",
          review_required: false,
          escalation_flag: false,
          priority_score: Number(input.urgency) / 5,
          location: {
            lat: latitude,
            lng: longitude,
            address_text: input.locationName.trim()
          },
          created_by: session.uid,
          created_at: timestamp,
          updated_at: timestamp,
          status: "open",
          vulnerability_tags: []
        });

        await setDoc(doc(collection(db, "events")), {
          organization_id: organizationId,
          entity_type: "need",
          entity_id: needId,
          event_type: "need.created",
          actor_uid: session.uid,
          actor_role: session.role,
          summary: "Need created from coordinator dashboard",
          created_at: timestamp
        });
      },
      async assignNeed(needId, volunteerId) {
        if (!db || !session) {
          throw new Error("You must be signed in before assigning a need.");
        }

        const need = needs.find((item) => item.id === needId);
        const volunteer = volunteers.find((item) => item.id === volunteerId);
        if (!need || !volunteer) {
          throw new Error("Need or volunteer could not be found.");
        }

        const batch = writeBatch(db);
        const taskId = `task-${crypto.randomUUID()}`;
        const timestamp = new Date().toISOString();

        batch.set(doc(db, "tasks", taskId), {
          organization_id: need.organizationId,
          need_id: need.id,
          volunteer_id: volunteer.id,
          need_title: need.title,
          volunteer_name: volunteer.name,
          assigned_by: session.uid,
          created_at: timestamp,
          status: "offered",
          completion_notes: ""
        });

        batch.update(doc(db, "needs", need.id), {
          status: "assigned",
          assigned_task_id: taskId,
          assigned_volunteer_id: volunteer.id,
          updated_at: timestamp
        });

        batch.set(
          doc(db, "volunteers", volunteer.id),
          {
            availability_status: "busy",
            current_task_count: Math.max(volunteer.currentTaskCount + 1, 1),
            last_active_at: timestamp
          },
          { merge: true }
        );

        batch.set(doc(collection(db, "events")), {
          organization_id: need.organizationId,
          entity_type: "task",
          entity_id: taskId,
          event_type: "task.assigned",
          actor_uid: session.uid,
          actor_role: session.role,
          summary: "Volunteer assigned from coordinator dashboard",
          created_at: timestamp
        });

        await batch.commit();
      },
      async completeTask(taskId) {
        if (!db || !session) {
          throw new Error("You must be signed in before completing a task.");
        }

        const task = tasks.find((item) => item.id === taskId);
        if (!task) {
          throw new Error("Task could not be found.");
        }

        const batch = writeBatch(db);
        const timestamp = new Date().toISOString();
        const volunteer = volunteers.find((item) => item.id === task.volunteerId);

        batch.update(doc(db, "tasks", task.id), {
          status: "completed",
          completed_at: timestamp
        });

        batch.update(doc(db, "needs", task.needId), {
          status: "resolved",
          updated_at: timestamp
        });

        batch.set(
          doc(db, "volunteers", task.volunteerId),
          {
            availability_status: "available",
            current_task_count: Math.max((volunteer?.currentTaskCount ?? 1) - 1, 0),
            last_active_at: timestamp
          },
          { merge: true }
        );

        batch.set(doc(collection(db, "events")), {
          organization_id: task.organizationId,
          entity_type: "task",
          entity_id: task.id,
          event_type: "task.completed",
          actor_uid: session.uid,
          actor_role: session.role,
          summary: "Task marked complete from coordinator dashboard",
          created_at: timestamp
        });

        await batch.commit();
      },
      async saveProfile(input) {
        if (!db || !session) {
          throw new Error("You must be signed in before updating your profile.");
        }

        await setDoc(
          doc(db, "users", session.uid),
          {
            display_name: input.displayName.trim(),
            phone: input.phone.trim(),
            preferred_language: input.preferredLanguage,
            notifications_enabled: input.notificationsEnabled,
            emergency_alerts_enabled: input.emergencyAlertsEnabled,
            updated_at: new Date().toISOString()
          },
          { merge: true }
        );

        setSession((current) =>
          current
            ? {
                ...current,
                displayName: input.displayName.trim(),
                phone: input.phone.trim(),
                preferredLanguage: input.preferredLanguage,
                notificationsEnabled: input.notificationsEnabled,
                emergencyAlertsEnabled: input.emergencyAlertsEnabled
              }
            : current
        );
      }
    }),
    [
      auth,
      authError,
      db,
      events,
      fieldAgents,
      loading,
      needs,
      selectedNeedId,
      session,
      tasks,
      theme,
      volunteers
    ]
  );

  return <AppStateContext.Provider value={value}>{children}</AppStateContext.Provider>;
}

async function ensureCoordinatorProfile(
  user: User,
  db: Firestore,
  displayNameOverride?: string
) {
  const ref = doc(db, "users", user.uid);
  const snapshot = await getDoc(ref);
  const existing = snapshot.exists() ? (snapshot.data() as Record<string, unknown>) : null;
  const existingRoles = Array.isArray(existing?.roles) ? existing!.roles.map(String) : [];
  const roles = Array.from(new Set([...existingRoles, "coordinator"]));
  const sessionName =
    displayNameOverride?.trim() ||
    String(existing?.display_name ?? user.displayName ?? "Guardians User");
  const preferredLanguage = String(existing?.preferred_language ?? "en") as SupportedLanguage;

  await setDoc(
    ref,
    {
      organization_ids:
        Array.isArray(existing?.organization_ids) && existing!.organization_ids.length > 0
          ? existing!.organization_ids
          : ["guardians"],
      roles,
      active_role: "coordinator",
      display_name: sessionName,
      email: user.email ?? String(existing?.email ?? ""),
      phone: String(existing?.phone ?? ""),
      preferred_language: preferredLanguage,
      notifications_enabled: Boolean(existing?.notifications_enabled ?? true),
      emergency_alerts_enabled: Boolean(existing?.emergency_alerts_enabled ?? true),
      status: "active",
      updated_at: new Date().toISOString()
    },
    { merge: true }
  );

  const refreshed = await getDoc(ref);
  const data = (refreshed.data() ?? {}) as Record<string, unknown>;
  const session = parseSession(user, data);
  if (session.organizationIds.length === 0) {
    throw new Error("This account is missing organization membership.");
  }

  return session;
}

export function useAppState() {
  const context = useContext(AppStateContext);
  if (!context) {
    throw new Error("useAppState must be used within AppStateProvider");
  }
  return context;
}
