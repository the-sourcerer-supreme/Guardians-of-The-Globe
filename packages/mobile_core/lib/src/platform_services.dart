import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_env.dart';
import 'models.dart';
import 'settings_controller.dart';

class AppServicesBundle {
  AppServicesBundle({
    required this.role,
    required this.settings,
    required this.authService,
    required this.repository,
    required this.isLive,
  });

  final AppRole role;
  final SettingsController settings;
  final AppAuthService authService;
  final AppDataRepository repository;
  final bool isLive;

  static Future<AppServicesBundle> bootstrap(
    AppRole role, {
    FirebaseOptions? fallbackOptions,
  }) async {
    final settings = await SettingsController.load();
    final options = FirebaseEnvConfig.isConfigured
        ? FirebaseEnvConfig.currentOptions
        : fallbackOptions;

    if (options == null) {
      return AppServicesBundle(
        role: role,
        settings: settings,
        authService: LockedAppAuthService(),
        repository: LockedAppDataRepository(),
        isLive: false,
      );
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }

    final firestore = FirebaseFirestore.instance;
    final authInstance = auth.FirebaseAuth.instance;
    final repository = FirestoreAppDataRepository(firestore);
    final authService = FirebaseAppAuthService(authInstance, firestore, role);

    return AppServicesBundle(
      role: role,
      settings: settings,
      authService: authService,
      repository: repository,
      isLive: true,
    );
  }
}

abstract class AppAuthService {
  Stream<UserProfile?> get authState;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signInWithGoogle();

  Future<void> signOut();
}

abstract class AppDataRepository {
  Stream<List<NeedRecord>> watchNeeds({
    required String organizationId,
    String? createdBy,
    String? assignedVolunteerId,
  });

  Stream<List<TaskRecord>> watchTasks({
    required String organizationId,
    String? volunteerId,
  });

  Stream<List<VolunteerRecord>> watchVolunteers({
    required String organizationId,
  });

  Stream<List<AuditEvent>> watchEvents({required String organizationId});

  Future<void> saveUserProfile(UserProfile profile);

  Future<void> createNeed(NeedRecord need);

  Future<void> assignNeed({
    required NeedRecord need,
    required VolunteerRecord volunteer,
    required UserProfile coordinator,
  });

  Future<void> updateTaskStatus({
    required TaskRecord task,
    required TaskStatus status,
    String? completionNotes,
  });

  Future<void> updateVolunteerAvailability({
    required String volunteerId,
    required String organizationId,
    required AvailabilityStatus status,
  });
}

class FirebaseAppAuthService implements AppAuthService {
  FirebaseAppAuthService(this._auth, this._firestore, this._role);

  final auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AppRole _role;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Stream<UserProfile?> get authState {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(null);
      }

      return _firestore.collection('users').doc(user.uid).snapshots().asyncMap((
        snapshot,
      ) async {
        try {
          return _loadAuthorizedProfileFromSnapshot(user, snapshot);
        } catch (_) {
          await signOut();
          return null;
        }
      });
    });
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _ensureProfileForRole(credential.user!);
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
    await _ensureProfileForRole(
      credential.user!,
      displayNameOverride: displayName.trim(),
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = auth.GoogleAuthProvider();
      final result = await _auth.signInWithPopup(provider);
      await _ensureProfileForRole(result.user!);
      return;
    }

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    await _ensureProfileForRole(result.user!);
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google cleanup errors and still sign out Firebase.
    }
    await _auth.signOut();
  }

  Future<UserProfile> _loadAuthorizedProfile(auth.User user) async {
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    return _loadAuthorizedProfileFromSnapshot(user, snapshot);
  }

  Future<void> _ensureProfileForRole(
    auth.User user, {
    String? displayNameOverride,
  }) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final existing = await ref.get();
    final baseProfile = existing.exists && existing.data() != null
        ? UserProfile.fromJson(existing.id, existing.data()!)
        : UserProfile(
            uid: user.uid,
            organizationIds: const ['guardians'],
            roles: const [],
            activeRole: _role,
            displayName:
                displayNameOverride?.isNotEmpty == true
                    ? displayNameOverride!
                    : (user.displayName?.trim().isNotEmpty == true
                          ? user.displayName!.trim()
                          : 'Guardians User'),
            email: user.email ?? '',
            phone: user.phoneNumber ?? '',
            preferredLanguage: 'en',
          );

    final nextRoles = <AppRole>{...baseProfile.roles, _role}.toList();
    final profile = baseProfile.copyWith(
      organizationIds: baseProfile.organizationIds.isEmpty
          ? const ['guardians']
          : baseProfile.organizationIds,
      roles: nextRoles,
      activeRole: _role,
      displayName:
          displayNameOverride?.isNotEmpty == true
              ? displayNameOverride
              : (baseProfile.displayName.trim().isNotEmpty
                    ? baseProfile.displayName
                    : 'Guardians User'),
      email: user.email ?? baseProfile.email,
      phone: user.phoneNumber ?? baseProfile.phone,
    );

    await _upsertProvisionedProfile(profile);
  }

  Future<void> _upsertProvisionedProfile(UserProfile profile) async {
    final batch = _firestore.batch();
    final organizationId = profile.organizationIds.first;

    batch.set(
      _firestore.collection('users').doc(profile.uid),
      {
        ...profile.toJson(),
        'status': 'active',
      },
      SetOptions(merge: true),
    );

    if (profile.roles.contains(AppRole.volunteer)) {
      batch.set(
        _firestore.collection('volunteers').doc(profile.uid),
        {
          'organization_id': organizationId,
          'name': profile.displayName,
          'email': profile.email,
          'phone': profile.phone,
          'skills': const <String>[],
          'languages': [profile.preferredLanguage],
          'availability_status': 'available',
          'current_task_count': 0,
          'home_location': {'lat': 0, 'lng': 0},
          'service_radius_km': 10,
          'last_active_at': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    }

    if (profile.roles.contains(AppRole.fieldAgent)) {
      batch.set(
        _firestore.collection('field_agents').doc(profile.uid),
        {
          'organization_id': organizationId,
          'display_name': profile.displayName,
          'phone': profile.phone,
          'assigned_regions': const <String>[],
          'device_last_seen_at': DateTime.now().toIso8601String(),
          'app_version': '0.1.0',
          'sync_health': 'healthy',
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  UserProfile _loadAuthorizedProfileFromSnapshot(
    auth.User user,
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists || snapshot.data() == null) {
      throw StateError('This account profile has not finished syncing yet.');
    }

    final data = snapshot.data()!;
    final status = data['status'] as String? ?? 'active';
    if (status != 'active') {
      throw StateError('This account has been disabled.');
    }

    final profile = UserProfile.fromJson(snapshot.id, data);
    final allowedRoles = <AppRole>{...profile.roles};
    final hasAccess =
        allowedRoles.contains(AppRole.admin) || allowedRoles.contains(_role);

    if (!hasAccess) {
      throw StateError('This account is missing the current app role.');
    }

    if (profile.organizationIds.isEmpty) {
      throw StateError('This account is missing organization membership.');
    }

    return profile;
  }
}

class FirestoreAppDataRepository implements AppDataRepository {
  FirestoreAppDataRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<NeedRecord>> watchNeeds({
    required String organizationId,
    String? createdBy,
    String? assignedVolunteerId,
  }) {
    return _firestore
        .collection('needs')
        .where('organization_id', isEqualTo: organizationId)
        .snapshots()
        .map((snapshot) {
          final all =
              snapshot.docs
                  .map((doc) => NeedRecord.fromJson(doc.id, doc.data()))
                  .toList()
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return all.where((need) {
            final createdMatches =
                createdBy == null || need.createdBy == createdBy;
            final volunteerMatches =
                assignedVolunteerId == null ||
                need.assignedVolunteerId == assignedVolunteerId;
            return createdMatches && volunteerMatches;
          }).toList();
        });
  }

  @override
  Stream<List<TaskRecord>> watchTasks({
    required String organizationId,
    String? volunteerId,
  }) {
    return _firestore
        .collection('tasks')
        .where('organization_id', isEqualTo: organizationId)
        .snapshots()
        .map((snapshot) {
          final all =
              snapshot.docs
                  .map((doc) => TaskRecord.fromJson(doc.id, doc.data()))
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return volunteerId == null
              ? all
              : all.where((task) => task.volunteerId == volunteerId).toList();
        });
  }

  @override
  Stream<List<VolunteerRecord>> watchVolunteers({
    required String organizationId,
  }) {
    return _firestore
        .collection('volunteers')
        .where('organization_id', isEqualTo: organizationId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => VolunteerRecord.fromJson(doc.id, doc.data()))
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  @override
  Stream<List<AuditEvent>> watchEvents({required String organizationId}) {
    return _firestore
        .collection('events')
        .where('organization_id', isEqualTo: organizationId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => AuditEvent.fromJson(doc.id, doc.data()))
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    final volunteerRef = _firestore.collection('volunteers').doc(profile.uid);
    final fieldAgentRef = _firestore.collection('field_agents').doc(profile.uid);
    final volunteerSnapshot = profile.roles.contains(AppRole.volunteer)
        ? await volunteerRef.get()
        : null;
    final fieldAgentSnapshot = profile.roles.contains(AppRole.fieldAgent)
        ? await fieldAgentRef.get()
        : null;
    final batch = _firestore.batch();
    final organizationId = profile.organizationIds.first;

    batch.set(
      _firestore.collection('users').doc(profile.uid),
      profile.toJson(),
      SetOptions(merge: true),
    );

    if (volunteerSnapshot?.exists ?? false) {
      batch.set(
        volunteerRef,
        {
          'organization_id': organizationId,
          'name': profile.displayName,
          'email': profile.email,
          'phone': profile.phone,
          'languages': [profile.preferredLanguage],
          'last_active_at': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    }

    if (fieldAgentSnapshot?.exists ?? false) {
      batch.set(
        fieldAgentRef,
        {
          'organization_id': organizationId,
          'display_name': profile.displayName,
          'phone': profile.phone,
          'device_last_seen_at': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  @override
  Future<void> createNeed(NeedRecord need) async {
    await _firestore.collection('needs').doc(need.id).set(need.toJson());
    await _firestore.collection('events').add({
      'organization_id': need.organizationId,
      'entity_type': 'need',
      'entity_id': need.id,
      'event_type': 'need.created',
      'actor_role': 'field_agent',
      'summary': 'Need captured from field app',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> assignNeed({
    required NeedRecord need,
    required VolunteerRecord volunteer,
    required UserProfile coordinator,
  }) async {
    final taskId = 'task-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final task = TaskRecord(
      id: taskId,
      organizationId: need.organizationId,
      needId: need.id,
      volunteerId: volunteer.id,
      needTitle: need.title,
      volunteerName: volunteer.name,
      assignedBy: coordinator.uid,
      createdAt: now,
      status: TaskStatus.offered,
    );

    final batch = _firestore.batch();
    batch.set(_firestore.collection('tasks').doc(taskId), task.toJson());
    batch.update(_firestore.collection('needs').doc(need.id), {
      'status': 'assigned',
      'assigned_task_id': taskId,
      'assigned_volunteer_id': volunteer.id,
      'updated_at': now.toIso8601String(),
    });
    batch.set(
      _firestore.collection('volunteers').doc(volunteer.id),
      {
        'availability_status': 'busy',
        'current_task_count': 1,
        'last_active_at': now.toIso8601String(),
      },
      SetOptions(merge: true),
    );
    batch.set(_firestore.collection('events').doc(), {
      'organization_id': need.organizationId,
      'entity_type': 'task',
      'entity_id': taskId,
      'event_type': 'task.assigned',
      'actor_role': roleKey(coordinator.activeRole),
      'summary': 'Volunteer assigned to need',
      'created_at': now.toIso8601String(),
    });
    await batch.commit();
  }

  @override
  Future<void> updateTaskStatus({
    required TaskRecord task,
    required TaskStatus status,
    String? completionNotes,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    batch.update(_firestore.collection('tasks').doc(task.id), {
      'status': taskStatusKey(status),
      'completion_notes': completionNotes ?? '',
      if (status == TaskStatus.accepted) 'accepted_at': now.toIso8601String(),
      if (status == TaskStatus.completed)
        'completed_at': now.toIso8601String(),
    });

    batch.set(_firestore.collection('events').doc(), {
      'organization_id': task.organizationId,
      'entity_type': 'task',
      'entity_id': task.id,
      'event_type': 'task.${taskStatusKey(status)}',
      'actor_role': 'volunteer',
      'summary': 'Task status updated',
      'created_at': now.toIso8601String(),
    });

    if (status == TaskStatus.accepted || status == TaskStatus.inProgress) {
      batch.update(_firestore.collection('needs').doc(task.needId), {
        'status': 'in_progress',
        'updated_at': now.toIso8601String(),
      });
      batch.set(
        _firestore.collection('volunteers').doc(task.volunteerId),
        {
          'availability_status': 'busy',
          'current_task_count': 1,
          'last_active_at': now.toIso8601String(),
        },
        SetOptions(merge: true),
      );
    }

    if (status == TaskStatus.completed) {
      batch.update(_firestore.collection('needs').doc(task.needId), {
        'status': 'resolved',
        'updated_at': now.toIso8601String(),
      });
      batch.set(
        _firestore.collection('volunteers').doc(task.volunteerId),
        {
          'availability_status': 'available',
          'current_task_count': 0,
          'last_active_at': now.toIso8601String(),
        },
        SetOptions(merge: true),
      );
    }

    if (status == TaskStatus.declined || status == TaskStatus.cancelled) {
      batch.update(_firestore.collection('needs').doc(task.needId), {
        'status': 'open',
        'assigned_task_id': FieldValue.delete(),
        'assigned_volunteer_id': FieldValue.delete(),
        'updated_at': now.toIso8601String(),
      });
      batch.set(
        _firestore.collection('volunteers').doc(task.volunteerId),
        {
          'availability_status': 'available',
          'current_task_count': 0,
          'last_active_at': now.toIso8601String(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  @override
  Future<void> updateVolunteerAvailability({
    required String volunteerId,
    required String organizationId,
    required AvailabilityStatus status,
  }) async {
    await _firestore.collection('volunteers').doc(volunteerId).set({
      'organization_id': organizationId,
      'availability_status': availabilityStatusKey(status),
      'last_active_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}

class LockedAppAuthService implements AppAuthService {
  @override
  Stream<UserProfile?> get authState => Stream.value(null);

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw StateError(
      'Firebase configuration is missing. Secure sign-in is locked until the app is configured.',
    );
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) {
    throw StateError(
      'Firebase configuration is missing. Secure sign-in is locked until the app is configured.',
    );
  }

  @override
  Future<void> signInWithGoogle() {
    throw StateError(
      'Firebase configuration is missing. Secure sign-in is locked until the app is configured.',
    );
  }

  @override
  Future<void> signOut() async {}
}

class LockedAppDataRepository implements AppDataRepository {
  const LockedAppDataRepository();

  @override
  Stream<List<NeedRecord>> watchNeeds({
    required String organizationId,
    String? createdBy,
    String? assignedVolunteerId,
  }) => Stream.value(const <NeedRecord>[]);

  @override
  Stream<List<TaskRecord>> watchTasks({
    required String organizationId,
    String? volunteerId,
  }) => Stream.value(const <TaskRecord>[]);

  @override
  Stream<List<VolunteerRecord>> watchVolunteers({
    required String organizationId,
  }) => Stream.value(const <VolunteerRecord>[]);

  @override
  Stream<List<AuditEvent>> watchEvents({required String organizationId}) =>
      Stream.value(const <AuditEvent>[]);

  @override
  Future<void> saveUserProfile(UserProfile profile) {
    throw StateError('Firebase configuration is missing.');
  }

  @override
  Future<void> createNeed(NeedRecord need) {
    throw StateError('Firebase configuration is missing.');
  }

  @override
  Future<void> assignNeed({
    required NeedRecord need,
    required VolunteerRecord volunteer,
    required UserProfile coordinator,
  }) {
    throw StateError('Firebase configuration is missing.');
  }

  @override
  Future<void> updateTaskStatus({
    required TaskRecord task,
    required TaskStatus status,
    String? completionNotes,
  }) {
    throw StateError('Firebase configuration is missing.');
  }

  @override
  Future<void> updateVolunteerAvailability({
    required String volunteerId,
    required String organizationId,
    required AvailabilityStatus status,
  }) {
    throw StateError('Firebase configuration is missing.');
  }
}

String generateNeedId() =>
    'need-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
