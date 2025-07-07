import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waqas_lock/services/app_state.dart';
import 'package:waqas_lock/services/device_admin_service.dart';
import 'package:waqas_lock/services/schedule_service.dart';

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
          _InfoTab(), // Yeh ab error nahi dega
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
                        color:
                            scheduleService.hasActiveSchedule ? Colors.green : Colors.grey,
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
                                      builder: (context, scheduleService,
                                          child) {
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
