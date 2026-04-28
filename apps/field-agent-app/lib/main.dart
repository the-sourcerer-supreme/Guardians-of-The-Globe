import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_core/mobile_core.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServicesBundle.bootstrap(
    AppRole.fieldAgent,
    fallbackOptions: _fallbackOptions(),
  );
  runApp(FieldAgentApp(services: services));
}

FirebaseOptions? _fallbackOptions() {
  try {
    return DefaultFirebaseOptions.currentPlatform;
  } catch (_) {
    return null;
  }
}

class FieldAgentApp extends StatelessWidget {
  const FieldAgentApp({super.key, required this.services});

  final AppServicesBundle services;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: services.settings,
      builder: (context, _) {
        final strings = AppStrings(services.settings.locale);
        return MaterialApp(
          title: 'Guardians Field Agent',
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
                  role: AppRole.fieldAgent,
                  authService: services.authService,
                  settings: services.settings,
                  title: 'Field Agent App',
                  subtitle:
                      'Secure field intake with live Firebase records, role-based access, and audit-safe updates.',
                  isLive: services.isLive,
                );
              }
              return FieldAgentHome(
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
    cardTheme: CardThemeData(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: border),
      ),
      margin: EdgeInsets.zero,
      elevation: 0,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scaffold,
      foregroundColor: text,
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

class FieldAgentHome extends StatefulWidget {
  const FieldAgentHome({
    super.key,
    required this.services,
    required this.profile,
    required this.strings,
  });

  final AppServicesBundle services;
  final UserProfile profile;
  final AppStrings strings;

  @override
  State<FieldAgentHome> createState() => _FieldAgentHomeState();
}

class _FieldAgentHomeState extends State<FieldAgentHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Guardians Field Agent',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _NeedsQueueTab(
            repository: widget.services.repository,
            profile: widget.profile,
          ),
          _CaptureTab(
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
            icon: const Icon(Icons.inbox_outlined),
            selectedIcon: const Icon(Icons.inbox),
            label: widget.strings.text('queue'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.note_add_outlined),
            selectedIcon: const Icon(Icons.note_add),
            label: widget.strings.text('capture'),
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

class _NeedsQueueTab extends StatelessWidget {
  const _NeedsQueueTab({
    required this.repository,
    required this.profile,
  });

  final AppDataRepository repository;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NeedRecord>>(
      stream: repository.watchNeeds(
        organizationId: profile.organizationIds.first,
        createdBy: profile.uid,
      ),
      builder: (context, snapshot) {
        final needs = snapshot.data ?? const <NeedRecord>[];
        final queuedCount = needs
            .where((need) => need.status == NeedStatus.open || need.status == NeedStatus.triaged)
            .length;
        final resolvedCount =
            needs.where((need) => need.status == NeedStatus.resolved).length;

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
                      'Field workload',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Every captured case stays visible here, with live status updates once the coordinator acts.',
                      style: TextStyle(color: Color(0xFF4B5563)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            label: 'Open',
                            value: '$queuedCount',
                            tone: const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(
                            label: 'Resolved',
                            value: '$resolvedCount',
                            tone: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (needs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No captured needs yet.'),
                ),
              )
            else
              ...needs.map(
                (need) => Padding(
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
                              _InfoChip(label: need.preferredLanguage.toUpperCase()),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Updated ${formatDateTime(need.updatedAt)}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CaptureTab extends StatefulWidget {
  const _CaptureTab({
    required this.repository,
    required this.profile,
  });

  final AppDataRepository repository;
  final UserProfile profile;

  @override
  State<_CaptureTab> createState() => _CaptureTabState();
}

class _CaptureTabState extends State<_CaptureTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _beneficiaryNameController = TextEditingController();
  final TextEditingController _beneficiaryPhoneController = TextEditingController();
  int _urgency = 3;
  int _peopleAffected = 1;
  String _needType = 'Water';
  String _preferredLanguage = 'en';
  bool _consentCaptured = true;
  bool _reviewRequired = false;
  final Set<String> _vulnerabilityTags = {'children'};

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _beneficiaryNameController.dispose();
    _beneficiaryPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final latitude = double.tryParse(_latitudeController.text.trim()) ?? 0;
    final longitude = double.tryParse(_longitudeController.text.trim()) ?? 0;

    final need = NeedRecord(
      id: generateNeedId(),
      organizationId: widget.profile.organizationIds.first,
      sourceChannel: 'field_app',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      needType: _needType,
      urgency: _urgency,
      peopleAffected: _peopleAffected,
      locationName: _locationController.text.trim(),
      latitude: latitude,
      longitude: longitude,
      createdBy: widget.profile.uid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: NeedStatus.open,
      priorityScore: _urgency / 5,
      beneficiaryName: _beneficiaryNameController.text.trim(),
      beneficiaryPhone: _beneficiaryPhoneController.text.trim(),
      preferredLanguage: _preferredLanguage,
      consentCaptured: _consentCaptured,
      reviewRequired: _reviewRequired,
      verificationStatus: _reviewRequired ? 'pending_review' : 'captured',
      vulnerabilityTags: _vulnerabilityTags.toList(),
    );

    await widget.repository.createNeed(need);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Need saved and ready for live coordinator review.')),
    );
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _beneficiaryNameController.clear();
    _beneficiaryPhoneController.clear();
    setState(() {
      _urgency = 3;
      _peopleAffected = 1;
      _needType = 'Water';
      _preferredLanguage = 'en';
      _consentCaptured = true;
      _reviewRequired = false;
      _vulnerabilityTags
        ..clear()
        ..add('children');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Capture need',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use this form for structured needs assessment, beneficiary consent capture, and multilingual field logging.',
                    style: TextStyle(color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Need title'),
                    validator: (value) => value == null || value.trim().length < 5
                        ? 'Enter a clear title'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _needType,
                    decoration: const InputDecoration(labelText: 'Need type'),
                    items: const [
                      'Water',
                      'Food',
                      'Shelter',
                      'Medical',
                      'Transport',
                      'Documentation',
                    ]
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _needType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => value == null || value.trim().length < 12
                        ? 'Add more detail'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location name'),
                    validator: (value) => value == null || value.trim().length < 3
                        ? 'Enter a location'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          decoration: const InputDecoration(labelText: 'Latitude'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          validator: (value) =>
                              value == null || double.tryParse(value.trim()) == null
                                  ? 'Required'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          decoration: const InputDecoration(labelText: 'Longitude'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          validator: (value) =>
                              value == null || double.tryParse(value.trim()) == null
                                  ? 'Required'
                                  : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _beneficiaryNameController,
                    decoration:
                        const InputDecoration(labelText: 'Beneficiary name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _beneficiaryPhoneController,
                    decoration:
                        const InputDecoration(labelText: 'Beneficiary phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _preferredLanguage,
                    decoration: const InputDecoration(labelText: 'Preferred language'),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                      DropdownMenuItem(value: 'mr', child: Text('Marathi')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _preferredLanguage = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Urgency: $_urgency / 5',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: _urgency.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) {
                      setState(() {
                        _urgency = value.round();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'People affected',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _peopleAffected > 1
                            ? () {
                                setState(() {
                                  _peopleAffected -= 1;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_peopleAffected',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _peopleAffected += 1;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vulnerability tags',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['children', 'senior_citizen', 'disability', 'medical_risk']
                        .map(
                          (tag) => FilterChip(
                            label: Text(tag),
                            selected: _vulnerabilityTags.contains(tag),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _vulnerabilityTags.add(tag);
                                } else {
                                  _vulnerabilityTags.remove(tag);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _consentCaptured,
                    title: const Text('Beneficiary consent captured'),
                    onChanged: (value) {
                      setState(() {
                        _consentCaptured = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _reviewRequired,
                    title: const Text('Flag for coordinator review'),
                    onChanged: (value) {
                      setState(() {
                        _reviewRequired = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save need'),
                    ),
                  ),
                ],
              ),
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
