import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/auth_api_service.dart';
import '../../../core/services/tag_preferences_service.dart';
import '../../../core/services/user_session_service.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TagPreferencesService tagPreferencesService =
      TagPreferencesService();

  final UserSessionService userSessionService =
      UserSessionService();

  final AuthApiService authApiService = AuthApiService();

  bool deletingAccount = false;

  String tagPosition = TagPreferencesService.defaultPosition;
  String tagSize = TagPreferencesService.defaultSize;

  String userName = 'Technician User';
  String userPhone = '';

  final List<String> positions = [
    'Top Left',
    'Top Right',
    'Bottom Left',
    'Bottom Right',
  ];

  final List<String> sizes = [
    'Small',
    'Medium',
    'Large',
  ];

  @override
  void initState() {
    super.initState();
    loadPreferences();
    loadUser();
  }

  Future<void> loadUser() async {
    final Map<String, dynamic>? user =
        await userSessionService.getUser();

    if (!mounted || user == null) return;

    setState(() {
      userName =
          user['full_name']?.toString() ??
          user['name']?.toString() ??
          'Technician User';

      userPhone = user['phone']?.toString() ?? '';
    });
  }

  Future<void> loadPreferences() async {
    final String savedPosition =
        await tagPreferencesService.getTagPosition();

    final String savedSize =
        await tagPreferencesService.getTagSize();

    if (!mounted) return;

    setState(() {
      tagPosition = savedPosition;
      tagSize = savedSize;
    });
  }

  Future<void> updateTagPosition(String value) async {
    setState(() {
      tagPosition = value;
    });

    await tagPreferencesService.saveTagPosition(value);

    showSavedMessage();
  }

  Future<void> updateTagSize(String value) async {
    setState(() {
      tagSize = value;
    });

    await tagPreferencesService.saveTagSize(value);

    showSavedMessage();
  }

  void showSavedMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo tag preferences saved'),
      ),
    );
  }

  String get formattedPhone {
    final String phone = userPhone.trim();

    if (phone.isEmpty) {
      return 'Not available';
    }

    if (phone.startsWith('+')) {
      return phone;
    }

    if (RegExp(r'^\d{8}$').hasMatch(phone)) {
      return '+974 $phone';
    }

    return phone;
  }

  Future<void> openPrivacyPolicy() async {
    final Uri privacyPolicyUrl = Uri.parse(
      'https://work-order-backend-b931.onrender.com/privacy-policy',
    );

    final bool opened = await launchUrl(
      privacyPolicyUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open the Privacy Policy.',
          ),
        ),
      );
    }
  }

  Future<void> showDeleteAccountDialog() async {
    final TextEditingController passwordController =
        TextEditingController();

    bool obscurePassword = true;
    bool dialogLoading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setDialogState,
          ) {
            Future<void> submitDeletion() async {
              final String password =
                  passwordController.text.trim();

              if (password.isEmpty) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter your current password.',
                    ),
                  ),
                );

                return;
              }

              setDialogState(() {
                dialogLoading = true;
              });

              setState(() {
                deletingAccount = true;
              });

              try {
                final String? token =
                    await userSessionService.getToken();

                if (token == null || token.isEmpty) {
                  throw Exception(
                    'Your login session has expired. Please log in again.',
                  );
                }

                final Map<String, dynamic> response =
                    await authApiService.deleteAccount(
                  token: token,
                  password: password,
                );

                final bool success =
                    response['success'] == true;

                final String message =
                    response['message']?.toString() ??
                    'Unable to delete account';

                if (!success) {
                  throw Exception(message);
                }

                await userSessionService.clearSession();

                if (!mounted) return;

                Navigator.of(dialogContext).pop();

                Navigator.pushNamedAndRemoveUntil(
                  this.context,
                  '/',
                  (route) => false,
                );

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                  ),
                );
              } catch (error) {
                if (!mounted) return;

                setDialogState(() {
                  dialogLoading = false;
                });

                setState(() {
                  deletingAccount = false;
                });

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error
                          .toString()
                          .replaceFirst(
                            'Exception: ',
                            '',
                          ),
                    ),
                  ),
                );
              }
            }

            return AlertDialog(
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 42,
              ),
              title: const Text(
                'Delete Account?',
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This action is permanent and cannot be undone.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Deleting your account will permanently remove your profile, associated work orders, photos, photo location data, reports, and authentication identity.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      enabled: !dialogLoading,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        hintText:
                            'Enter your password to confirm',
                        prefixIcon:
                            const Icon(Icons.lock_outline),
                        border:
                            const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: dialogLoading
                              ? null
                              : () {
                                  setDialogState(() {
                                    obscurePassword =
                                        !obscurePassword;
                                  });
                                },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      onSubmitted: (_) {
                        if (!dialogLoading) {
                          submitDeletion();
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: dialogLoading
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed:
                      dialogLoading ? null : submitDeletion,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  icon: dialogLoading
                      ? const SizedBox.shrink()
                      : const Icon(
                          Icons.delete_forever,
                        ),
                  label: dialogLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Delete Permanently',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();

    if (mounted) {
      setState(() {
        deletingAccount = false;
      });
    }
  }

  Future<void> logout() async {
    await userSessionService.clearSession();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget settingsCard({
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget divider() {
    return Divider(
      height: 1,
      indent: 56,
      color: Colors.grey.shade200,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            32,
          ),
          children: [
            // ---------------------------------------------
            // USER PROFILE
            // ---------------------------------------------

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor:
                        Colors.white.withValues(
                      alpha: 0.18,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 15,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                formattedPhone,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------------------------------------------
            // PHOTO TAG PREFERENCES
            // ---------------------------------------------

            sectionTitle('PHOTO TAG PREFERENCES'),

            settingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<
                      String>(
                    value: tagPosition,
                    decoration:
                        const InputDecoration(
                      labelText: 'Tag Position',
                      prefixIcon: Icon(
                        Icons.open_with,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                    items:
                        positions.map((position) {
                      return DropdownMenuItem(
                        value: position,
                        child: Text(position),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      updateTagPosition(value);
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    16,
                  ),
                  child:
                      DropdownButtonFormField<
                          String>(
                    value: tagSize,
                    decoration:
                        const InputDecoration(
                      labelText: 'Tag Size',
                      prefixIcon:
                          Icon(Icons.text_fields),
                      border:
                          OutlineInputBorder(),
                    ),
                    items: sizes.map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text(size),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      updateTagSize(value);
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    16,
                  ),
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer
                        .withValues(alpha: 0.35),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 19,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'These settings control the position and size of the metadata tag added to captured work-order photos.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ---------------------------------------------
            // PRIVACY & INFORMATION
            // ---------------------------------------------

            sectionTitle('PRIVACY & INFORMATION'),

            settingsCard(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.privacy_tip_outlined,
                    color: colors.primary,
                  ),
                  title:
                      const Text('Privacy Policy'),
                  subtitle: const Text(
                    'Learn how your personal information is handled',
                  ),
                  trailing:
                      const Icon(Icons.open_in_new),
                  onTap: openPrivacyPolicy,
                ),
                divider(),
                const ListTile(
                  leading: Icon(
                    Icons.info_outline,
                  ),
                  title: Text('App Version'),
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ---------------------------------------------
            // ACCOUNT
            // ---------------------------------------------

            sectionTitle('ACCOUNT'),

            settingsCard(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                  ),
                  title: const Text('Log Out'),
                  subtitle: const Text(
                    'Sign out from this device',
                  ),
                  trailing:
                      const Icon(Icons.chevron_right),
                  onTap: logout,
                ),
                divider(),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Permanently delete your account and associated data',
                  ),
                  trailing: deletingAccount
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.chevron_right,
                          color: Colors.red,
                        ),
                  onTap: deletingAccount
                      ? null
                      : showDeleteAccountDialog,
                ),
              ],
            ),

            const SizedBox(height: 28),

            Center(
              child: Text(
                'Work Order • Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}