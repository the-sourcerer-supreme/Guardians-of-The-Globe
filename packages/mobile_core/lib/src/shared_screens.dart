import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'models.dart';
import 'platform_services.dart';
import 'settings_controller.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.role,
    required this.authService,
    required this.settings,
    required this.title,
    required this.subtitle,
    required this.isLive,
  });

  final AppRole role;
  final AppAuthService authService;
  final SettingsController settings;
  final String title;
  final String subtitle;
  final bool isLive;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  bool _busy = false;
  bool _createMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  String? _validateCredentials(AppStrings strings) {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      return '${strings.text('email')} is required.';
    }
    if (_createMode && _displayNameController.text.trim().length < 2) {
      return '${strings.text('displayName')} is required.';
    }
    if (password.length < 8) {
      return '${strings.text('password')} must be at least 8 characters.';
    }
    return null;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(widget.settings.locale);
    final roleLabel = roleKey(widget.role).replaceAll('_', ' ');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(color: Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 8),
                      _ModeBadge(
                        label: widget.isLive
                            ? strings.text('firebaseLive')
                            : 'Locked until Firebase is configured',
                        color: widget.isLive
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        roleLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_createMode) ...[
                        TextField(
                          controller: _displayNameController,
                          decoration: InputDecoration(
                            labelText: strings.text('displayName'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: strings.text('email'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: strings.text('password'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy || !widget.isLive
                              ? null
                              : () => _run(() {
                                  final error = _validateCredentials(strings);
                                  if (error != null) {
                                    throw StateError(error);
                                  }
                                  if (_createMode) {
                                    return widget.authService.signUpWithEmail(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                      displayName: _displayNameController.text.trim(),
                                    );
                                  }
                                  return widget.authService.signInWithEmail(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                  );
                                }),
                          child: Text(
                            _createMode
                                ? strings.text('signUp')
                                : strings.text('signIn'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _busy || !widget.isLive
                              ? null
                              : () => _run(widget.authService.signInWithGoogle),
                          icon: const Icon(Icons.account_circle_outlined),
                          label: Text(strings.text('googleSignIn')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _busy || !widget.isLive
                            ? null
                            : () {
                                setState(() {
                                  _createMode = !_createMode;
                                });
                              },
                        child: Text(
                          _createMode
                              ? strings.text('signIn')
                              : strings.text('signUp'),
                        ),
                      ),
                      Text(
                        widget.isLive
                            ? 'Users can create their own account in this app. The app will create the matching Firebase profile automatically.'
                            : 'Firebase configuration is still required before this app can sign in.',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.profile,
    required this.settings,
    required this.repository,
    required this.authService,
    required this.isLive,
    this.onSavedMessage,
  });

  final UserProfile profile;
  final SettingsController settings;
  final AppDataRepository repository;
  final AppAuthService authService;
  final bool isLive;
  final String? onSavedMessage;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _phoneController;
  bool _notificationsEnabled = true;
  bool _emergencyAlertsEnabled = true;
  String _languageCode = 'en';

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profile.displayName,
    );
    _phoneController = TextEditingController(text: widget.profile.phone);
    _notificationsEnabled = widget.profile.notificationsEnabled;
    _emergencyAlertsEnabled = widget.profile.emergencyAlertsEnabled;
    _languageCode = widget.profile.preferredLanguage;
  }

  @override
  void didUpdateWidget(covariant AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.uid != widget.profile.uid ||
        oldWidget.profile.displayName != widget.profile.displayName ||
        oldWidget.profile.phone != widget.profile.phone ||
        oldWidget.profile.preferredLanguage != widget.profile.preferredLanguage ||
        oldWidget.profile.notificationsEnabled !=
            widget.profile.notificationsEnabled ||
        oldWidget.profile.emergencyAlertsEnabled !=
            widget.profile.emergencyAlertsEnabled) {
      _displayNameController.text = widget.profile.displayName;
      _phoneController.text = widget.profile.phone;
      _notificationsEnabled = widget.profile.notificationsEnabled;
      _emergencyAlertsEnabled = widget.profile.emergencyAlertsEnabled;
      _languageCode = widget.profile.preferredLanguage;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final updated = widget.profile.copyWith(
      displayName: _displayNameController.text.trim(),
      phone: _phoneController.text.trim(),
      preferredLanguage: _languageCode,
      notificationsEnabled: _notificationsEnabled,
      emergencyAlertsEnabled: _emergencyAlertsEnabled,
    );

    await widget.repository.saveUserProfile(updated);
    await widget.settings.setLocale(Locale(_languageCode));

    if (!mounted) {
      return;
    }
    final strings = AppStrings(widget.settings.locale);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.onSavedMessage ?? strings.text('profileSaved')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(widget.settings.locale);
    final isDark = widget.settings.themePreference == ThemePreference.dark;

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
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFE5E7EB),
                            child: Text(
                              widget.profile.displayName.isEmpty
                                  ? 'GU'
                                  : widget.profile.displayName
                                        .trim()
                                        .split(' ')
                                        .take(2)
                                        .map((part) => part[0].toUpperCase())
                                        .join(),
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.profile.email,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _ModeBadge(
                                  label: widget.isLive
                                      ? strings.text('firebaseLive')
                                      : 'Locked',
                                  color: widget.isLive
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String>(
                        initialValue: _languageCode,
                        decoration: InputDecoration(
                          labelText: strings.text('language'),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                          DropdownMenuItem(value: 'mr', child: Text('Marathi')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _languageCode = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: widget.settings.toggleThemePreference,
                    icon: Icon(
                      isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    ),
                    label: Text(
                      '${strings.text('appearance')}: '
                      '${isDark ? strings.text('dark') : strings.text('light')}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: strings.text('displayName'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: strings.text('phone')),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _notificationsEnabled,
                  title: Text(strings.text('notifications')),
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _emergencyAlertsEnabled,
                  title: Text(strings.text('emergencyAlerts')),
                  onChanged: (value) {
                    setState(() {
                      _emergencyAlertsEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saveProfile,
                    child: Text(strings.text('save')),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: widget.authService.signOut,
                    child: Text(strings.text('signOut')),
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

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.label, required this.color});

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
