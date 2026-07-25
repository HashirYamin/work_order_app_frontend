import 'package:flutter/material.dart';

import '../../../core/services/tag_preferences_service.dart';
import '../../../core/services/user_session_service.dart';
class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TagPreferencesService tagPreferencesService = TagPreferencesService();
  final UserSessionService userSessionService = UserSessionService();

  bool biometricEnabled = false;
  String tagPosition = TagPreferencesService.defaultPosition;
  String tagSize = TagPreferencesService.defaultSize;

  String userName = 'Technician User';
  String userPhone = '+0000000000';

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
    final Map<String, dynamic>? user = await userSessionService.getUser();

    if (!mounted) return;

    if (user == null) return;

    setState(() {
      userName = user['name']?.toString() ?? 'Technician User';
      userPhone = user['phone']?.toString() ?? '+0000000000';
    });
  }

  Future<void> loadPreferences() async {
    final savedPosition = await tagPreferencesService.getTagPosition();
    final savedSize = await tagPreferencesService.getTagSize();

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
  }

  Future<void> updateTagSize(String value) async {
    setState(() {
      tagSize = value;
    });

    await tagPreferencesService.saveTagSize(value);
  }

  void showSavedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo tag preferences saved'),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    child: Icon(Icons.person, size: 35),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Phone: $userPhone'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Account',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ListTile(
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),

            ListTile(
              title: const Text('Change Phone Number'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),

            const SizedBox(height: 12),

            const Text(
              'Photo Tag Preferences',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: tagPosition,
              decoration: const InputDecoration(
                labelText: 'Tag Position',
                border: OutlineInputBorder(),
              ),
              items: positions.map((position) {
                return DropdownMenuItem(
                  value: position,
                  child: Text(position),
                );
              }).toList(),
              onChanged: (value) async {
                if (value == null) return;
                await updateTagPosition(value);
                showSavedMessage();
              },
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: tagSize,
              decoration: const InputDecoration(
                labelText: 'Tag Size',
                border: OutlineInputBorder(),
              ),
              items: sizes.map((size) {
                return DropdownMenuItem(
                  value: size,
                  child: Text(size),
                );
              }).toList(),
              onChanged: (value) async {
                if (value == null) return;
                await updateTagSize(value);
                showSavedMessage();
              },
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'These settings control where the metadata tag appears on captured photos and how large the tag text will be.',
                style: TextStyle(fontSize: 13),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Preferences',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            SwitchListTile(
              title: const Text('Biometric / Face'),
              value: biometricEnabled,
              onChanged: (value) {
                setState(() {
                  biometricEnabled = value;
                });
              },
            ),

            const SizedBox(height: 12),

            const Text(
              'About',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const ListTile(
              title: Text('App Version'),
              trailing: Text('v1.0.0'),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}