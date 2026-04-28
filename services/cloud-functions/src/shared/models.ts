export interface NeedDocument {
  organization_id: string;
  title: string;
  description: string;
  need_type: string;
  urgency_input: number;
  people_affected: number;
  location: {
    lat: number;
    lng: number;
    geohash?: string;
    address_text: string;
  };
  status:
    | "open"
    | "triaged"
    | "assigned"
    | "in_progress"
    | "resolved"
    | "closed"
    | "rejected";
  priority_score?: number;
  review_required?: boolean;
  parse_confidence?: number;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface VolunteerDocument {
  organization_id: string;
  name: string;
  skills: string[];
  availability_status: "available" | "busy" | "offline";
  current_task_count: number;
  home_location: {
    lat: number;
    lng: number;
    geohash?: string;
  };
  service_radius_km: number;
  acceptance_rate: number;
}

export interface MatchCandidate {
  volunteer_id: string;
  skill_fit: number;
  proximity: number;
  availability: number;
  acceptance_history: number;
  score: number;
}
