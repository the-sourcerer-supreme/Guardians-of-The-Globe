import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_core/mobile_core.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServicesBundle.bootstrap(
    AppRole.coordinator,
    fallbackOptions: _fallbackOptions(),
  );
  runApp(CoordinatorApp(services: services));
}

FirebaseOptions? _fallbackOptions() {
  try {
    return DefaultFirebaseOptions.currentPlatform;
  } catch (_) {
    return null;
  }
}

class CoordinatorApp extends StatelessWidget {
  const CoordinatorApp({super.key, required this.services});

  final AppServicesBundle services;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: services.settings,
      builder: (context, _) {
        final strings = AppStrings(services.settings.locale);
        return MaterialApp(
          title: 'Guardians Coordinator',
          debugShowCheckedModeBanner: false,
          themeMode: services.settings.themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          locale: services.settings.locale,
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: StreamBuilder<UserProfile?>(
            stream: services.authService.authState,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              if (profile == null) {
                return SignInScreen(
                  role: AppRole.coordinator,
                  authService: services.authService,
                  settings: services.settings,
                  title: 'Coordinator App',
                  subtitle:
                      'Strict coordinator login with live triage, dispatch, and audit visibility.',
                  isLive: services.isLive,
                );
              }
              return CoordinatorHome(
                services: services,
                profile: profile,
                strings: strings,
              );
            },
          ),
        );
      },
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  const primary = Color(0xFF1D4ED8);
  final scaffold = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  final surface = isDark ? const Color(0xFF050505) : const Color(0xFFFFFFFF);
  final text = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
  final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

  return ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      surface: surface,
    ),
    scaffoldBackgroundColor: scaffold,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffold,
      foregroundColor: text,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: border),
      ),
      margin: EdgeInsets.zero,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
  );
}

class CoordinatorHome extends StatefulWidget {
  const CoordinatorHome({
    super.key,
    required this.services,
    required this.profile,
    required this.strings,
  });

  final AppServicesBundle services;
  final UserProfile profile;
  final AppStrings strings;

  @override
  State<CoordinatorHome> createState() => _CoordinatorHomeState();
}

class _CoordinatorHomeState extends State<CoordinatorHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Guardians Coordinator',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(
            repository: widget.services.repository,
            profile: widget.profile,
          ),
          _NeedsTab(
            repository: widget.services.repository,
            profile: widget.profile,
          ),
          _VolunteersTab(
            repository: widget.services.repository,
            profile: widget.profile,
          ),
          AccountScreen(
            profile: widget.profile,
            settings: widget.services.settings,
            repository: widget.services.repository,
            authService: widget.services.authService,
            isLive: widget.services.isLive,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: widget.strings.text('dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: widget.strings.text('fieldNeeds'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: widget.strings.text('volunteers'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: widget.strings.text('account'),
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.repository,
    required this.profile,
  });

  final AppDataRepository repository;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NeedRecord>>(
      stream: repository.watchNeeds(organizationId: profile.organizationIds.first),
      builder: (context, needSnapshot) {
        return StreamBuilder<List<TaskRecord>>(
          stream: repository.watchTasks(organizationId: profile.organizationIds.first),
          builder: (context, taskSnapshot) {
            return StreamBuilder<List<VolunteerRecord>>(
              stream: repository.watchVolunteers(
                organizationId: profile.organizationIds.first,
              ),
              builder: (context, volunteerSnapshot) {
                final needs = needSnapshot.data ?? const <NeedRecord>[];
                final tasks = taskSnapshot.data ?? const <TaskRecord>[];
                final volunteers = volunteerSnapshot.data ?? const <VolunteerRecord>[];
                final openNeeds = needs
                    .where((need) => need.status != NeedStatus.resolved)
                    .length;
                final criticalNeeds = needs.where((need) => need.urgency >= 4).length;
                final activeTasks = tasks
                    .where((task) => task.status == TaskStatus.accepted)
                    .length;
                final availableVolunteers = volunteers
                    .where((volunteer) =>
                        volunteer.availabilityStatus == AvailabilityStatus.available)
                    .length;

                return StreamBuilder<List<AuditEvent>>(
                  stream: repository.watchEvents(
                    organizationId: profile.organizationIds.first,
                  ),
                  builder: (context, eventSnapshot) {
                    final events = eventSnapshot.data ?? const <AuditEvent>[];
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Operations overview',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'This mobile coordinator view focuses on triage speed, dispatch clarity, and audit visibility.',
                                  style: TextStyle(color: Color(0xFF4B5563)),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MetricTile(
                                        label: 'Open needs',
                                        value: '$openNeeds',
                                        tone: const Color(0xFF1D4ED8),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _MetricTile(
                                        label: 'Critical',
                                        value: '$criticalNeeds',
                                        tone: const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MetricTile(
                                        label: 'Available',
                                        value: '$availableVolunteers',
                                        tone: const Color(0xFF059669),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _MetricTile(
                                        label: 'Active tasks',
                                        value: '$activeTasks',
                                        tone: const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Audit timeline',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (events.isEmpty)
                                  const Text('No audit events yet.')
                                else
                                  ...events.take(8).map(
                                        (event) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 10,
                                                height: 10,
                                                margin: const EdgeInsets.only(top: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1D4ED8),
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      event.summary,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${event.actorRole} • ${formatDateTime(event.createdAt)}',
                                                      style: const TextStyle(
                                                        color: Color(0xFF6B7280),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _NeedsTab extends StatelessWidget {
  const _NeedsTab({
    required this.repository,
    required this.profile,
  });

  final AppDataRepository repository;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NeedRecord>>(
      stream: repository.watchNeeds(organizationId: profile.organizationIds.first),
      builder: (context, needSnapshot) {
        return StreamBuilder<List<VolunteerRecord>>(
          stream: repository.watchVolunteers(
            organizationId: profile.organizationIds.first,
          ),
          builder: (context, volunteerSnapshot) {
            final needs = needSnapshot.data ?? const <NeedRecord>[];
            final volunteers = volunteerSnapshot.data ?? const <VolunteerRecord>[];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (needs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No needs available yet.'),
                    ),
                  )
                else
                  ...needs.map(
                    (need) {
                      final candidates = volunteers.where((volunteer) {
                        final statusOk = volunteer.availabilityStatus ==
                            AvailabilityStatus.available;
                        final skillOk = volunteer.skills.any(
                          (skill) =>
                              skill.toLowerCase() == need.needType.toLowerCase(),
                        );
                        return statusOk && skillOk;
                      }).toList();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        need.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    _StatusPill(
                                      label: needStatusKey(need.status)
                                          .replaceAll('_', ' '),
                                      color: urgencyColor(need.urgency),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  need.description,
                                  style: const TextStyle(
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _InfoChip(label: need.needType),
                                    _InfoChip(label: need.locationName),
                                    _InfoChip(label: '${need.peopleAffected} affected'),
                                    _InfoChip(
                                      label: need.reviewRequired
                                          ? 'Review required'
                                          : 'Ready',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Suggested volunteers',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                if (candidates.isEmpty)
                                  const Text(
                                    'No exact live match is available right now.',
                                    style: TextStyle(color: Color(0xFF6B7280)),
                                  )
                                else
                                  ...candidates.take(3).map(
                                        (volunteer) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      volunteer.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      volunteer.skills.join(', '),
                                                      style: const TextStyle(
                                                        color: Color(0xFF6B7280),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              FilledButton(
                                                onPressed: need.status ==
                                                            NeedStatus.open ||
                                                        need.status ==
                                                            NeedStatus.triaged
                                                    ? () {
                                                        repository.assignNeed(
                                                          need: need,
                                                          volunteer: volunteer,
                                                          coordinator: profile,
                                                        );
                                                      }
                                                    : null,
                                                child: const Text('Assign'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _VolunteersTab extends StatelessWidget {
  const _VolunteersTab({
    required this.repository,
    required this.profile,
  });

  final AppDataRepository repository;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VolunteerRecord>>(
      stream: repository.watchVolunteers(
        organizationId: profile.organizationIds.first,
      ),
      builder: (context, snapshot) {
        final volunteers = snapshot.data ?? const <VolunteerRecord>[];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: volunteers
              .map(
                (volunteer) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  volunteer.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _StatusPill(
                                label: availabilityStatusKey(
                                  volunteer.availabilityStatus,
                                ),
                                color: volunteer.availabilityStatus ==
                                        AvailabilityStatus.available
                                    ? const Color(0xFF059669)
                                    : volunteer.availabilityStatus ==
                                            AvailabilityStatus.busy
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFF6B7280),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(volunteer.email),
                          const SizedBox(height: 4),
                          Text(
                            volunteer.phone,
                            style: const TextStyle(color: Color(0xFF4B5563)),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoChip(label: volunteer.skills.join(', ')),
                              _InfoChip(
                                label:
                                    '${volunteer.serviceRadiusKm.toStringAsFixed(0)} km radius',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF4B5563))),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
