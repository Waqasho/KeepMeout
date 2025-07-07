import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waqas_lock/services/app_state.dart';
import 'package:waqas_lock/services/schedule_service.dart';
// Yeh import add kiya gaya hai
import 'package:waqas_lock/services/device_admin_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
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
          _SettingsTab(),
          _InfoTab(),
        ],
      ),
    );
  }
}

class _SchedulesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add Schedule Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddScheduleDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add New Schedule'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        // Current Status
        Consumer<ScheduleService>(
          builder: (context, scheduleService, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheduleService.hasActiveSchedule
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: scheduleService.hasActiveSchedule
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        scheduleService.hasActiveSchedule
                            ? Icons.lock
                            : Icons.lock_open,
                        color: scheduleService.hasActiveSchedule
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        scheduleService.hasActiveSchedule
                            ? 'Schedule Active'
                            : 'No Active Schedule',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheduleService.hasActiveSchedule
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (scheduleService.hasActiveSchedule) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Current: ${scheduleService.activeSchedule!.name}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    scheduleService.getNextScheduleInfo(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Schedules List
        Expanded(
          child: Consumer<ScheduleService>(
            builder: (context, scheduleService, child) {
              if (scheduleService.schedules.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Schedules Yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first schedule to get started with automatic screen locking',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddScheduleDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Schedule'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: scheduleService.schedules.length,
                itemBuilder: (context, index) {
                  final schedule = scheduleService.schedules[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      schedule.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: schedule.isEnabled
                                            ? null
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Consumer<ScheduleService>(
                                      builder:
                                          (context, scheduleService, child) {
                                        final isActive = scheduleService
                                                .activeSchedule?.id ==
                                            schedule.id;

                                        return Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? Colors.green
                                                    : schedule.isEnabled
                                                        ? Theme.of(context)
                                                            .primaryColor
                                                        : Colors.grey,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                isActive
                                                    ? 'ACTIVE NOW'
                                                    : schedule.isEnabled
                                                        ? 'ENABLED'
                                                        : 'DISABLED',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: schedule.isEnabled,
                                onChanged: (_) =>
                                    scheduleService.toggleSchedule(schedule.id),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Time Information
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: schedule.isEnabled
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: schedule.isEnabled
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${schedule.startTime.formatted} - ${schedule.endTime.formatted}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: schedule.isEnabled
                                        ? null
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Weekdays
                          Wrap(
                            spacing: 4,
                            children: List.generate(7, (index) {
                              final weekday = index + 1;
                              final isSelected =
                                  schedule.weekdays.contains(weekday);

                              return Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (schedule.isEnabled
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? (schedule.isEnabled
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey)
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    ScheduleService.weekdayShortNames[index]
                                        [0],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : (schedule.isEnabled
                                              ? null
                                              : Colors.grey),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 12),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _editSchedule(context, schedule),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _deleteSchedule(context, schedule),
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddScheduleDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditScheduleScreen(),
      ),
    );
  }

  void _editSchedule(BuildContext context, Schedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditScheduleScreen(schedule: schedule),
      ),
    );
  }

  void _deleteSchedule(BuildContext context, Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Are you sure you want to delete "${schedule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<ScheduleService>().deleteSchedule(schedule.id);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Schedule deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // YEH CARD ADD KIYA GAYA HAI
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
                  subtitle: const Text(
                      'Required for screen lock and uninstall protection'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    bool isActive =
                        await DeviceAdminService.isDeviceAdminActive();
                    if (!isActive) {
                      await DeviceAdminService.requestDeviceAdmin();
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

        // Admin PIN Section
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
                  subtitle: const Text(
                      'Update the PIN used to access admin features'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showChangePinDialog(context),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // App Settings Section
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
                  subtitle:
                      const Text('Enable notifications for schedule events'),
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

  void _showChangePinDialog(BuildContext context) {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Admin PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final appState = context.read<AppState>();

              if (!appState.verifyAdminPin(currentPinController.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Current PIN is incorrect'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPinController.text != confirmPinController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('New PINs do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPinController.text.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN must be at least 4 digits'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await appState.updateAdminPin(newPinController.text);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                  children: [
                    Icon(
                      Icons.lock_clock,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Waqas Lock',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Text('Version 1.0.0'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'A powerful screen locking app with timer and scheduling features. '
                  'Perfect for productivity, parental controls, and time management.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  icon: Icons.timer,
                  title: 'Timer Lock',
                  description: 'Set timers to automatically lock the screen',
                ),
                _FeatureItem(
                  icon: Icons.schedule,
                  title: 'Custom Schedules',
                  description:
                      'Create recurring schedules for automatic locking',
                ),
                _FeatureItem(
                  icon: Icons.admin_panel_settings,
                  title: 'Admin Access',
                  description: 'Secure admin panel with PIN protection',
                ),
                _FeatureItem(
                  icon: Icons.lock,
                  title: 'Instant Lock',
                  description: 'Manually lock the screen anytime',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Add/Edit Schedule Screen
class AddEditScheduleScreen extends StatefulWidget {
  final Schedule? schedule;

  const AddEditScheduleScreen({super.key, this.schedule});

  @override
  State<AddEditScheduleScreen> createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  final _nameController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  List<int> _selectedWeekdays = [1, 2, 3, 4, 5]; // Monday to Friday
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      _nameController.text = widget.schedule!.name;
      _startTime = TimeOfDay(
          hour: widget.schedule!.startTime.hour,
          minute: widget.schedule!.startTime.minute);
      _endTime = TimeOfDay(
          hour: widget.schedule!.endTime.hour,
          minute: widget.schedule!.endTime.minute);
      _selectedWeekdays = List.from(widget.schedule!.weekdays);
      _isEnabled = widget.schedule!.isEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.schedule == null ? 'Add Schedule' : 'Edit Schedule'),
        actions: [
          TextButton(
            onPressed: _saveSchedule,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Schedule Name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Schedule Name',
              border: OutlineInputBorder(),
              hintText: 'e.g., Work Hours, Study Time',
            ),
          ),

          const SizedBox(height: 24),

          // Time Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Start Time'),
                          subtitle: Text(
                              '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'),
                          trailing: const Icon(Icons.access_time),
                          onTap: () => _selectTime(context, true),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('End Time'),
                          subtitle: Text(
                              '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}'),
                          trailing: const Icon(Icons.access_time),
                          onTap: () => _selectTime(context, false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Weekdays Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Days',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      final weekday = index + 1;
                      final isSelected = _selectedWeekdays.contains(weekday);

                      return FilterChip(
                        label: Text(ScheduleService.weekdayShortNames[index]),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedWeekdays.add(weekday);
                            } else {
                              _selectedWeekdays.remove(weekday);
                            }
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Enable/Disable
          Card(
            child: SwitchListTile(
              title: const Text('Enable Schedule'),
              subtitle: const Text('Schedule will be active when enabled'),
              value: _isEnabled,
              onChanged: (value) {
                setState(() {
                  _isEnabled = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveSchedule() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a schedule name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final schedule = Schedule(
      id: widget.schedule?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      startTime:
          CustomTimeOfDay(hour: _startTime.hour, minute: _startTime.minute),
      endTime: CustomTimeOfDay(hour: _endTime.hour, minute: _endTime.minute),
      weekdays: _selectedWeekdays,
      isEnabled: _isEnabled,
    );

    final scheduleService = context.read<ScheduleService>();

    if (widget.schedule == null) {
      await scheduleService.addSchedule(schedule);
    } else {
      await scheduleService.updateSchedule(widget.schedule!.id, schedule);
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.schedule == null
              ? 'Schedule added successfully'
              : 'Schedule updated successfully',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}
