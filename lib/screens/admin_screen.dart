import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waqas_lock/services/app_state.dart';
import 'package:waqas_lock/services/schedule_service.dart';
// Yeh import add karein
import 'package:waqas_lock/services/device_admin_service.dart';

//... (baaqi file ka code waisa hi rahega) ...

// Sirf "_SettingsTab" class ko modify kiya gaya hai

class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Yeh Card Add Kiya Gaya Hai
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Permissions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Activate Device Admin'),
                  subtitle: const Text('Required for screen lock and uninstall protection'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    bool isActive = await DeviceAdminService.isDeviceAdminActive();
                    if (!isActive) {
                      await DeviceAdminService.requestDeviceAdmin();
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please grant permission from system settings.'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device Admin is already active.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Admin PIN Section (Pehle se mojood card)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Change Admin PIN'),
                  subtitle: const Text('Update the PIN used to access admin features'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showChangePinDialog(context),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // App Settings Section (Pehle se mojood card)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: const Text('Enable notifications for schedule events'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // TODO: Implement notification toggle
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.vibration),
                  title: const Text('Vibration'),
                  subtitle: const Text('Vibrate when timer expires'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // TODO: Implement vibration toggle
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //... (baaqi file ka code waisa hi rahega, jaise _showChangePinDialog method) ...
  // Full admin_screen.dart file yahan poori nahi di, sirf _SettingsTab ka modified hissa diya hai.
  // Aap bas _SettingsTab class ko upar diye gaye code se replace kar dein aur
  // file ke shuru mein `device_admin_service.dart` ka import add kar lein.
}

// Full file ka baaqi structure waisa hi rahega.
// For clarity, here is the rest of the file which remains unchanged.
// The code below is NOT modified, just included so you have the full file to copy.

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              context.read<AppState>().exitAdminMode();
              Navigator.pop(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Schedules'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
            Tab(icon: Icon(Icons.info), text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SchedulesTab(),
          _SettingsTab(), // Yeh tab modify ho gaya hai
          _InfoTab(),
        ],
      ),
    );
  }
}

// All other classes and methods like _SchedulesTab, _InfoTab, _showChangePinDialog, etc. remain the same as in your original file.
// You only need to replace the _SettingsTab class and add the import at the top of the file.
