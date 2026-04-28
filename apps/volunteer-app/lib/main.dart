import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_core/mobile_core.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServicesBundle.bootstrap(
    AppRole.volunteer,
    fallbackOptions: _fallbackOptions(),
  );
  runApp(VolunteerApp(services: services));
}

FirebaseOptions? _fallbackOptions() {
  try {
    return DefaultFirebaseOptions.currentPlatform;
  } catch (_) {
    return null;
  }
}

class VolunteerApp extends StatelessWidget {
  const VolunteerApp({super.key, required this.services});

  final AppServicesBundle services;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: services.settings,
      builder: (context, _) {
        final strings = AppStrings(services.settings.locale);
        return MaterialApp(
          title: 'Guardians Volunteer',
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
                  role: AppRole.volunteer,
                  authService: services.authService,
                  settings: services.settings,
                  title: 'Volunteer App',
                  subtitle:
                      'Secure volunteer dispatch with shared live tasks, protected sign-in, and editable account settings.',
                  isLive: services.isLive,
                );
              }
              return VolunteerHome(
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
  const primary = Color(0xFF0F766E);
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

class VolunteerHome extends StatefulWidget {
  const VolunteerHome({
    super.key,
    required this.services,
    required this.profile,
    required this.strings,
  });

  final AppServicesBundle services;
  final UserProfile profile;
  final AppStrings strings;

  @override
  State<VolunteerHome> createState() => _VolunteerHomeState();
}

class _VolunteerHomeState extends State<VolunteerHome> {
  final TextEditingController _completionNoteController =
      TextEditingController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _completionNoteController.dispose();
    super.dispose();
  }

  void _showBanner(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateAvailability(AvailabilityStatus status) async {
    await widget.services.repository.updateVolunteerAvailability(
      volunteerId: widget.profile.uid,
      organizationId: widget.profile.organizationIds.first,
      status: status,
    );

    if (!mounted) {
      return;
    }

    _showBanner(
      status == AvailabilityStatus.available
          ? 'You are available for dispatch.'
          : 'You are hidden from new dispatches.',
    );
  }

  Future<void> _updateTask(
    TaskRecord task,
    TaskStatus status, {
    String? notes,
  }) async {
    await widget.services.repository.updateTaskStatus(
      task: task,
      status: status,
      completionNotes: notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskRecord>>(
      stream: widget.services.repository.watchTasks(
        organizationId: widget.profile.organizationIds.first,
        volunteerId: widget.profile.uid,
      ),
      builder: (context, taskSnapshot) {
        return StreamBuilder<List<NeedRecord>>(
          stream: widget.services.repository.watchNeeds(
            organizationId: widget.profile.organizationIds.first,
          ),
          builder: (context, needSnapshot) {
            return StreamBuilder<List<VolunteerRecord>>(
              stream: widget.services.repository.watchVolunteers(
                organizationId: widget.profile.organizationIds.first,
              ),
              builder: (context, volunteerSnapshot) {
                final tasks = taskSnapshot.data ?? const <TaskRecord>[];
                final allNeeds = needSnapshot.data ?? const <NeedRecord>[];
                final volunteers =
                    volunteerSnapshot.data ?? const <VolunteerRecord>[];
                final volunteer = volunteers.cast<VolunteerRecord?>().firstWhere(
                  (item) => item?.id == widget.profile.uid,
                  orElse: () => null,
                );
                final activeTask = tasks.cast<TaskRecord?>().firstWhere(
                  (task) =>
                      task?.status == TaskStatus.accepted ||
                      task?.status == TaskStatus.inProgress,
                  orElse: () => null,
                );
                final needById = {for (final need in allNeeds) need.id: need};
                final visibleOpenNeeds = allNeeds
                    .where(
                      (need) =>
                          (need.status == NeedStatus.open ||
                              need.status == NeedStatus.triaged) &&
                          need.assignedVolunteerId == null,
                    )
                    .toList();

                return Scaffold(
                  appBar: AppBar(
                    title: const Text(
                      'Guardians Volunteer',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    actions: [
                      if (volunteer != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Center(
                            child: _StatusPill(
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
                          ),
                        ),
                    ],
                  ),
                  body: IndexedStack(
                    index: _currentIndex,
                    children: [
                      _InboxTab(
                        volunteer: volunteer,
                        tasks: tasks,
                        openNeeds: visibleOpenNeeds,
                        needById: needById,
                        onAvailabilityChanged: _updateAvailability,
                        onAccept: (task) async {
                          if (volunteer == null) {
                            _showBanner(
                              'Coordinator must provision your volunteer profile before dispatch can begin.',
                            );
                            return;
                          }
                          if (volunteer.availabilityStatus !=
                              AvailabilityStatus.available) {
                            _showBanner(
                              'Set yourself to available before accepting a task.',
                            );
                            return;
                          }
                          if (activeTask != null && activeTask.id != task.id) {
                            _showBanner(
                              'Complete the active task before taking another one.',
                            );
                            return;
                          }

                          await _updateTask(task, TaskStatus.accepted);
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _currentIndex = 1;
                          });
                          _showBanner('Task accepted and marked in progress.');
                        },
                        onDecline: (task) async {
                          await _updateTask(task, TaskStatus.declined);
                          if (!mounted) {
                            return;
                          }
                          _showBanner('Task declined and returned to dispatch.');
                        },
                      ),
                      _ActiveTaskTab(
                        task: activeTask,
                        need: activeTask == null
                            ? null
                            : needById[activeTask.needId],
                        completionNoteController: _completionNoteController,
                        onComplete: activeTask == null
                            ? null
                            : () async {
                                final note =
                                    _completionNoteController.text.trim();
                                if (note.length < 8) {
                                  _showBanner(
                                    'Add a short completion note before finishing the task.',
                                  );
                                  return;
                                }

                                await _updateTask(
                                  activeTask,
                                  TaskStatus.completed,
                                  notes: note,
                                );
                                _completionNoteController.clear();
                                if (!mounted) {
                                  return;
                                }
                                setState(() {
                                  _currentIndex = 0;
                                });
                                _showBanner(
                                  'Task marked complete and synced to the coordinator.',
                                );
                              },
                      ),
                      AccountScreen(
                        profile: widget.profile,
                        settings: widget.services.settings,
                        repository: widget.services.repository,
                        authService: widget.services.authService,
                        isLive: widget.services.isLive,
                        onSavedMessage: 'Volunteer profile updated.',
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
                        icon: const Icon(Icons.assignment_outlined),
                        selectedIcon: const Icon(Icons.assignment),
                        label: widget.strings.text('inbox'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.route_outlined),
                        selectedIcon: const Icon(Icons.route),
                        label: widget.strings.text('active'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.person_outline),
                        selectedIcon: const Icon(Icons.person),
                        label: widget.strings.text('account'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _InboxTab extends StatelessWidget {
  const _InboxTab({
    required this.volunteer,
    required this.tasks,
    required this.openNeeds,
    required this.needById,
    required this.onAvailabilityChanged,
    required this.onAccept,
    required this.onDecline,
  });

  final VolunteerRecord? volunteer;
  final List<TaskRecord> tasks;
  final List<NeedRecord> openNeeds;
  final Map<String, NeedRecord> needById;
  final ValueChanged<AvailabilityStatus> onAvailabilityChanged;
  final ValueChanged<TaskRecord> onAccept;
  final ValueChanged<TaskRecord> onDecline;

  @override
  Widget build(BuildContext context) {
    final openOffers =
        tasks.where((task) => task.status == TaskStatus.offered).length;
    final completed =
        tasks.where((task) => task.status == TaskStatus.completed).length;
    final queueVisible = openNeeds.length;
    final orderedTasks = [
      ...tasks.where((task) => task.status == TaskStatus.offered),
      ...tasks.where((task) => task.status != TaskStatus.offered),
    ];

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
                  'Volunteer dispatch',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Coordinator offers arrive here, and field-created requests are now visible before assignment.',
                  style: TextStyle(color: Color(0xFF4B5563)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Open offers',
                        value: '$openOffers',
                        tone: const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        label: 'Completed',
                        value: '$completed',
                        tone: const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        label: 'Open requests',
                        value: '$queueVisible',
                        tone: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<AvailabilityStatus>(
                  segments: const [
                    ButtonSegment(
                      value: AvailabilityStatus.available,
                      label: Text('Available'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                    ButtonSegment(
                      value: AvailabilityStatus.offline,
                      label: Text('Offline'),
                      icon: Icon(Icons.pause_circle_outline),
                    ),
                  ],
                  selected: {
                    volunteer?.availabilityStatus ?? AvailabilityStatus.offline,
                  },
                  onSelectionChanged: volunteer == null
                      ? null
                      : (selection) {
                          onAvailabilityChanged(selection.first);
                        },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (openNeeds.isNotEmpty) ...[
          const Text(
            'Field requests awaiting coordinator assignment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...openNeeds.take(6).map((need) {
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
                            label: needStatusKey(need.status).replaceAll('_', ' '),
                            color: urgencyColor(need.urgency),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        need.description,
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(label: need.needType),
                          _InfoChip(label: '${need.peopleAffected} affected'),
                          _InfoChip(label: need.locationName),
                          _InfoChip(label: 'Updated ${formatDateTime(need.updatedAt)}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Visible for awareness. A coordinator still needs to assign this request before you can accept it.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
        if (orderedTasks.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No assigned volunteer tasks yet.'),
            ),
          )
        else
          ...orderedTasks.map((task) {
            final need = needById[task.needId];
            final canRespond = task.status == TaskStatus.offered;

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
                              task.needTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _StatusPill(
                            label: taskStatusKey(task.status).replaceAll('_', ' '),
                            color: _taskStatusColor(task.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        need?.description ??
                            'Live task details remain visible from the shared dispatch stream.',
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (need != null) _InfoChip(label: need.needType),
                          if (need != null)
                            _InfoChip(label: '${need.peopleAffected} affected'),
                          if (need != null) _InfoChip(label: need.locationName),
                          _InfoChip(label: 'Assigned ${formatDateTime(task.createdAt)}'),
                        ],
                      ),
                      if (task.completionNotes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          task.completionNotes,
                          style: const TextStyle(color: Color(0xFF374151)),
                        ),
                      ],
                      if (canRespond) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => onDecline(task),
                                child: const Text('Decline'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => onAccept(task),
                                child: const Text('Accept'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ActiveTaskTab extends StatelessWidget {
  const _ActiveTaskTab({
    required this.task,
    required this.need,
    required this.completionNoteController,
    required this.onComplete,
  });

  final TaskRecord? task;
  final NeedRecord? need;
  final TextEditingController completionNoteController;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    if (task == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No active task is open right now. Accept an offer from the inbox to begin dispatch.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
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
                        task!.needTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const _StatusPill(
                      label: 'Active',
                      color: Color(0xFF0F766E),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  need?.description ??
                      'This task is active in the shared dispatch system.',
                  style: const TextStyle(color: Color(0xFF374151)),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (need != null) _InfoChip(label: need!.needType),
                    if (need != null) _InfoChip(label: need!.locationName),
                    if (need != null)
                      _InfoChip(label: '${need!.peopleAffected} affected'),
                    _InfoChip(label: 'Started ${formatDateTime(task!.createdAt)}'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Completion note',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: completionNoteController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText:
                        'Delivered supplies, confirmed handoff, and noted any follow-up constraints.',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.task_alt),
                    label: const Text('Mark task complete'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

Color _taskStatusColor(TaskStatus status) {
  switch (status) {
    case TaskStatus.offered:
      return const Color(0xFFD97706);
    case TaskStatus.accepted:
    case TaskStatus.inProgress:
      return const Color(0xFF0F766E);
    case TaskStatus.completed:
      return const Color(0xFF059669);
    case TaskStatus.declined:
    case TaskStatus.cancelled:
      return const Color(0xFF6B7280);
  }
}
