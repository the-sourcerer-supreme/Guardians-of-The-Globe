import 'package:flutter/material.dart';

enum AppRole { admin, coordinator, fieldAgent, volunteer }

enum ThemePreference { system, light, dark }

enum NeedStatus {
  open,
  triaged,
  assigned,
  inProgress,
  resolved,
  closed,
  rejected,
}

enum TaskStatus {
  offered,
  accepted,
  inProgress,
  completed,
  declined,
  cancelled,
}

enum AvailabilityStatus { available, busy, offline }

class UserProfile {
  UserProfile({
    required this.uid,
    required this.organizationIds,
    required this.roles,
    required this.activeRole,
    required this.displayName,
    required this.email,
    this.phone = '',
    this.photoUrl,
    this.preferredLanguage = 'en',
    this.notificationsEnabled = true,
    this.emergencyAlertsEnabled = true,
  });

  final String uid;
  final List<String> organizationIds;
  final List<AppRole> roles;
  final AppRole activeRole;
  final String displayName;
  final String email;
  final String phone;
  final String? photoUrl;
  final String preferredLanguage;
  final bool notificationsEnabled;
  final bool emergencyAlertsEnabled;

  UserProfile copyWith({
    List<String>? organizationIds,
    List<AppRole>? roles,
    AppRole? activeRole,
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
    String? preferredLanguage,
    bool? notificationsEnabled,
    bool? emergencyAlertsEnabled,
  }) {
    return UserProfile(
      uid: uid,
      organizationIds: organizationIds ?? this.organizationIds,
      roles: roles ?? this.roles,
      activeRole: activeRole ?? this.activeRole,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emergencyAlertsEnabled:
          emergencyAlertsEnabled ?? this.emergencyAlertsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_ids': organizationIds,
      'roles': roles.map(roleKey).toList(),
      'active_role': roleKey(activeRole),
      'display_name': displayName,
      'email': email,
      'phone': phone,
      'photo_url': photoUrl,
      'preferred_language': preferredLanguage,
      'notifications_enabled': notificationsEnabled,
      'emergency_alerts_enabled': emergencyAlertsEnabled,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory UserProfile.fromJson(String uid, Map<String, dynamic> json) {
    final roleValues = (json['roles'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => appRoleFromKey(item as String? ?? ''))
        .toList();
    final roles = roleValues.isEmpty ? [AppRole.fieldAgent] : roleValues;

    return UserProfile(
      uid: uid,
      organizationIds:
          (json['organization_ids'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
      roles: roles,
      activeRole: appRoleFromKey(
        json['active_role'] as String? ?? roleKey(roles.first),
      ),
      displayName: json['display_name'] as String? ?? 'Guardians User',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      emergencyAlertsEnabled: json['emergency_alerts_enabled'] as bool? ?? true,
    );
  }
}

class NeedRecord {
  NeedRecord({
    required this.id,
    required this.organizationId,
    required this.sourceChannel,
    required this.title,
    required this.description,
    required this.needType,
    required this.urgency,
    required this.peopleAffected,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.priorityScore = 0,
    this.beneficiaryName = '',
    this.beneficiaryPhone = '',
    this.preferredLanguage = 'en',
    this.consentCaptured = false,
    this.verificationStatus = 'pending',
    this.reviewRequired = true,
    this.escalationFlag = false,
    this.assignedTaskId,
    this.assignedVolunteerId,
    this.vulnerabilityTags = const [],
  });

  final String id;
  final String organizationId;
  final String sourceChannel;
  final String title;
  final String description;
  final String needType;
  final int urgency;
  final int peopleAffected;
  final String locationName;
  final double latitude;
  final double longitude;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final NeedStatus status;
  final double priorityScore;
  final String beneficiaryName;
  final String beneficiaryPhone;
  final String preferredLanguage;
  final bool consentCaptured;
  final String verificationStatus;
  final bool reviewRequired;
  final bool escalationFlag;
  final String? assignedTaskId;
  final String? assignedVolunteerId;
  final List<String> vulnerabilityTags;

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'source_channel': sourceChannel,
      'title': title,
      'description': description,
      'need_type': needType,
      'urgency_input': urgency,
      'people_affected': peopleAffected,
      'beneficiary_name': beneficiaryName,
      'beneficiary_phone': beneficiaryPhone,
      'preferred_language': preferredLanguage,
      'consent_captured': consentCaptured,
      'verification_status': verificationStatus,
      'review_required': reviewRequired,
      'escalation_flag': escalationFlag,
      'priority_score': priorityScore,
      'location': {
        'lat': latitude,
        'lng': longitude,
        'address_text': locationName,
      },
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': needStatusKey(status),
      'assigned_task_id': assignedTaskId,
      'assigned_volunteer_id': assignedVolunteerId,
      'vulnerability_tags': vulnerabilityTags,
    };
  }

  factory NeedRecord.fromJson(String id, Map<String, dynamic> json) {
    final location =
        (json['location'] as Map<String, dynamic>? ??
        const <String, dynamic>{});
    return NeedRecord(
      id: id,
      organizationId: json['organization_id'] as String? ?? '',
      sourceChannel: json['source_channel'] as String? ?? 'field_app',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      needType: json['need_type'] as String? ?? '',
      urgency: (json['urgency_input'] as num? ?? 1).toInt(),
      peopleAffected: (json['people_affected'] as num? ?? 1).toInt(),
      locationName: location['address_text'] as String? ?? '',
      latitude: (location['lat'] as num? ?? 0).toDouble(),
      longitude: (location['lng'] as num? ?? 0).toDouble(),
      createdBy: json['created_by'] as String? ?? '',
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      status: needStatusFromKey(json['status'] as String? ?? 'open'),
      priorityScore: (json['priority_score'] as num? ?? 0).toDouble(),
      beneficiaryName: json['beneficiary_name'] as String? ?? '',
      beneficiaryPhone: json['beneficiary_phone'] as String? ?? '',
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      consentCaptured: json['consent_captured'] as bool? ?? false,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      reviewRequired: json['review_required'] as bool? ?? true,
      escalationFlag: json['escalation_flag'] as bool? ?? false,
      assignedTaskId: json['assigned_task_id'] as String?,
      assignedVolunteerId: json['assigned_volunteer_id'] as String?,
      vulnerabilityTags:
          (json['vulnerability_tags'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
    );
  }
}

class VolunteerRecord {
  VolunteerRecord({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.email,
    required this.phone,
    required this.skills,
    required this.languages,
    required this.availabilityStatus,
    required this.currentTaskCount,
    required this.latitude,
    required this.longitude,
    required this.serviceRadiusKm,
    required this.lastActiveAt,
  });

  final String id;
  final String organizationId;
  final String name;
  final String email;
  final String phone;
  final List<String> skills;
  final List<String> languages;
  final AvailabilityStatus availabilityStatus;
  final int currentTaskCount;
  final double latitude;
  final double longitude;
  final double serviceRadiusKm;
  final DateTime lastActiveAt;

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'name': name,
      'email': email,
      'phone': phone,
      'skills': skills,
      'languages': languages,
      'availability_status': availabilityStatusKey(availabilityStatus),
      'current_task_count': currentTaskCount,
      'home_location': {'lat': latitude, 'lng': longitude},
      'service_radius_km': serviceRadiusKm,
      'last_active_at': lastActiveAt.toIso8601String(),
    };
  }

  factory VolunteerRecord.fromJson(String id, Map<String, dynamic> json) {
    final home =
        (json['home_location'] as Map<String, dynamic>? ??
        const <String, dynamic>{});
    return VolunteerRecord(
      id: id,
      organizationId: json['organization_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      languages: (json['languages'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      availabilityStatus: availabilityStatusFromKey(
        json['availability_status'] as String? ?? 'offline',
      ),
      currentTaskCount: (json['current_task_count'] as num? ?? 0).toInt(),
      latitude: (home['lat'] as num? ?? 0).toDouble(),
      longitude: (home['lng'] as num? ?? 0).toDouble(),
      serviceRadiusKm: (json['service_radius_km'] as num? ?? 0).toDouble(),
      lastActiveAt: parseDate(json['last_active_at']),
    );
  }
}

class TaskRecord {
  TaskRecord({
    required this.id,
    required this.organizationId,
    required this.needId,
    required this.volunteerId,
    required this.needTitle,
    required this.volunteerName,
    required this.assignedBy,
    required this.createdAt,
    required this.status,
    this.completionNotes = '',
    this.scheduledFor,
  });

  final String id;
  final String organizationId;
  final String needId;
  final String volunteerId;
  final String needTitle;
  final String volunteerName;
  final String assignedBy;
  final DateTime createdAt;
  final TaskStatus status;
  final String completionNotes;
  final DateTime? scheduledFor;

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'need_id': needId,
      'volunteer_id': volunteerId,
      'need_title': needTitle,
      'volunteer_name': volunteerName,
      'assigned_by': assignedBy,
      'created_at': createdAt.toIso8601String(),
      'status': taskStatusKey(status),
      'completion_notes': completionNotes,
      'scheduled_for': scheduledFor?.toIso8601String(),
    };
  }

  factory TaskRecord.fromJson(String id, Map<String, dynamic> json) {
    return TaskRecord(
      id: id,
      organizationId: json['organization_id'] as String? ?? '',
      needId: json['need_id'] as String? ?? '',
      volunteerId: json['volunteer_id'] as String? ?? '',
      needTitle: json['need_title'] as String? ?? '',
      volunteerName: json['volunteer_name'] as String? ?? '',
      assignedBy: json['assigned_by'] as String? ?? '',
      createdAt: parseDate(json['created_at']),
      status: taskStatusFromKey(json['status'] as String? ?? 'offered'),
      completionNotes: json['completion_notes'] as String? ?? '',
      scheduledFor: json['scheduled_for'] == null
          ? null
          : parseDate(json['scheduled_for']),
    );
  }
}

class AuditEvent {
  AuditEvent({
    required this.id,
    required this.summary,
    required this.eventType,
    required this.actorRole,
    required this.createdAt,
  });

  final String id;
  final String summary;
  final String eventType;
  final String actorRole;
  final DateTime createdAt;

  factory AuditEvent.fromJson(String id, Map<String, dynamic> json) {
    return AuditEvent(
      id: id,
      summary: json['summary'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      actorRole: json['actor_role'] as String? ?? '',
      createdAt: parseDate(json['created_at']),
    );
  }
}

DateTime parseDate(Object? raw) {
  if (raw is DateTime) {
    return raw;
  }
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
  }
  return DateTime.now();
}

String roleKey(AppRole role) {
  switch (role) {
    case AppRole.admin:
      return 'admin';
    case AppRole.coordinator:
      return 'coordinator';
    case AppRole.fieldAgent:
      return 'field_agent';
    case AppRole.volunteer:
      return 'volunteer';
  }
}

AppRole appRoleFromKey(String value) {
  switch (value) {
    case 'admin':
      return AppRole.admin;
    case 'coordinator':
      return AppRole.coordinator;
    case 'volunteer':
      return AppRole.volunteer;
    default:
      return AppRole.fieldAgent;
  }
}

String needStatusKey(NeedStatus status) {
  switch (status) {
    case NeedStatus.open:
      return 'open';
    case NeedStatus.triaged:
      return 'triaged';
    case NeedStatus.assigned:
      return 'assigned';
    case NeedStatus.inProgress:
      return 'in_progress';
    case NeedStatus.resolved:
      return 'resolved';
    case NeedStatus.closed:
      return 'closed';
    case NeedStatus.rejected:
      return 'rejected';
  }
}

NeedStatus needStatusFromKey(String value) {
  switch (value) {
    case 'triaged':
      return NeedStatus.triaged;
    case 'assigned':
      return NeedStatus.assigned;
    case 'in_progress':
      return NeedStatus.inProgress;
    case 'resolved':
      return NeedStatus.resolved;
    case 'closed':
      return NeedStatus.closed;
    case 'rejected':
      return NeedStatus.rejected;
    default:
      return NeedStatus.open;
  }
}

String taskStatusKey(TaskStatus status) {
  switch (status) {
    case TaskStatus.offered:
      return 'offered';
    case TaskStatus.accepted:
      return 'accepted';
    case TaskStatus.inProgress:
      return 'in_progress';
    case TaskStatus.completed:
      return 'completed';
    case TaskStatus.declined:
      return 'declined';
    case TaskStatus.cancelled:
      return 'cancelled';
  }
}

TaskStatus taskStatusFromKey(String value) {
  switch (value) {
    case 'accepted':
      return TaskStatus.accepted;
    case 'in_progress':
      return TaskStatus.inProgress;
    case 'completed':
      return TaskStatus.completed;
    case 'declined':
      return TaskStatus.declined;
    case 'cancelled':
      return TaskStatus.cancelled;
    default:
      return TaskStatus.offered;
  }
}

String availabilityStatusKey(AvailabilityStatus status) {
  switch (status) {
    case AvailabilityStatus.available:
      return 'available';
    case AvailabilityStatus.busy:
      return 'busy';
    case AvailabilityStatus.offline:
      return 'offline';
  }
}

AvailabilityStatus availabilityStatusFromKey(String value) {
  switch (value) {
    case 'available':
      return AvailabilityStatus.available;
    case 'busy':
      return AvailabilityStatus.busy;
    default:
      return AvailabilityStatus.offline;
  }
}

String formatDateTime(DateTime value) {
  String two(int input) => input.toString().padLeft(2, '0');

  return '${value.day}/${value.month}/${value.year} '
      '${two(value.hour)}:${two(value.minute)}';
}

Color urgencyColor(int urgency) {
  if (urgency >= 5) {
    return const Color(0xFFDC2626);
  }
  if (urgency >= 4) {
    return const Color(0xFFD97706);
  }
  if (urgency >= 3) {
    return const Color(0xFF1D4ED8);
  }
  return const Color(0xFF059669);
}
