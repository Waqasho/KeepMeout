import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waqas_lock/services/app_state.dart';
import 'package:waqas_lock/services/timer_service.dart';
import 'package:waqas_lock/services/schedule_service.dart';
import 'package:waqas_lock/services/device_admin_service.dart';
import 'package:waqas_lock/screens/admin_screen.dart';
import 'package:waqas_lock/screens/lock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waqas Lock'),
        actions: [
          Consumer<AppState>(
            builder: (context, appState, child) {
              return IconButton(
                icon: Icon(
                  appState.isAdminMode ? Icons.admin_panel_settings : Icons.settings,
                ),
                onPressed: () {
                  if (appState.isAdminMode) {
                    Navigator.pushNamed(context, '/admin');
                  } else {
                    _showAdminPinDialog(context);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_clock,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Waqas Lock',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Consumer<AppState>(
                      builder: (context, appState, child) {
                        return Text(
                          appState.isAdminMode ? 'Admin Mode Active' : 'User Mode',
                          style: TextStyle(
                            color: appState.isAdminMode ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Timer Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Timer Lock',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Consumer<TimerService>(
                      builder: (context, timerService, child) {
                        if (timerService.isRunning) {
                          return Column(
                            children: [
                              // Timer Display
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Time Remaining',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      timerService.formattedTime,
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    LinearProgressIndicator(
                                      value: timerService.progress,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        timerService.isAboutToExpire 
                                            ? Colors.red 
                                            : Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${timerService.percentageElapsed}% Complete',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Timer Controls
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => timerService.stopTimer(),
                                      icon: const Icon(Icons.stop),
                                      label: const Text('Stop'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showAddTimeDialog(context),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Time'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.timer_off,
                                      size: 48,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No Timer Active',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Set a timer to automatically lock the screen',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Quick Timer Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _startQuickTimer(context, 15),
                                      child: const Text('15 min'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _startQuickTimer(context, 30),
                                      child: const Text('30 min'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _startQuickTimer(context, 60),
                                      child: const Text('1 hour'),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              ElevatedButton.icon(
                                onPressed: () => _showCustomTimerDialog(context),
                                icon: const Icon(Icons.schedule),
                                label: const Text('Custom Timer'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Schedule Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Schedules',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Consumer<ScheduleService>(
                      builder: (context, scheduleService, child) {
                        if (scheduleService.schedules.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.schedule_outlined,
                                  size: 48,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Schedules',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create schedules to automatically lock the screen at specific times',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Navigate to admin screen to add schedule
                                    Navigator.pushNamed(context, '/admin');
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Schedule'),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return Column(
                          children: [
                            // Current Status
                            Container(
                              width: double.infinity,
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
                                        size: 20,
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
                                    const SizedBox(height: 4),
                                    Text(
                                      scheduleService.activeSchedule!.name,
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
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Text(
                              '${scheduleService.schedules.length} schedule(s) configured',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<AppState>().lockScreen();
                            },
                            icon: const Icon(Icons.lock),
                            label: const Text('Lock Now'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Consumer<TimerService>(
                            builder: (context, timerService, child) {
                              return ElevatedButton.icon(
                                onPressed: timerService.isRunning
                                    ? () => timerService.stopTimer()
                                    : () => _showTimerDialog(context),
                                icon: Icon(
                                  timerService.isRunning ? Icons.stop : Icons.timer,
                                ),
                                label: Text(
                                  timerService.isRunning ? 'Stop Timer' : 'Start Timer',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: timerService.isRunning
                                      ? Colors.red
                                      : Theme.of(context).primaryColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startQuickTimer(BuildContext context, int minutes) {
    context.read<TimerService>().startTimer(
      minutes,
      onComplete: () {
        context.read<AppState>().lockScreen();
      },
    );
  }

  void _showAdminPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Access'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter Admin PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final appState = context.read<AppState>();
              if (appState.enterAdminMode(pinController.text)) {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid PIN'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Enter'),
          ),
        ],
      ),
    );
  }

  void _showTimerDialog(BuildContext context) {
    int minutes = 30;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lock screen for $minutes minutes'),
              Slider(
                value: minutes.toDouble(),
                min: 1,
                max: 120,
                divisions: 119,
                label: '$minutes min',
                onChanged: (value) {
                  setState(() {
                    minutes = value.round();
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<TimerService>().startTimer(
                  minutes,
                  onComplete: () {
                    context.read<AppState>().lockScreen();
                  },
                );
                Navigator.pop(context);
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTimeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add 5 minutes'),
              onTap: () {
                context.read<TimerService>().addTime(5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add 15 minutes'),
              onTap: () {
                context.read<TimerService>().addTime(15);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add 30 minutes'),
              onTap: () {
                context.read<TimerService>().addTime(30);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCustomTimerDialog(BuildContext context) {
    int hours = 0;
    int minutes = 30;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Custom Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Hours'),
                        DropdownButton<int>(
                          value: hours,
                          items: List.generate(24, (index) => index)
                              .map((hour) => DropdownMenuItem(
                                    value: hour,
                                    child: Text(hour.toString()),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              hours = value ?? 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Minutes'),
                        DropdownButton<int>(
                          value: minutes,
                          items: List.generate(60, (index) => index)
                              .map((minute) => DropdownMenuItem(
                                    value: minute,
                                    child: Text(minute.toString()),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              minutes = value ?? 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Total: ${hours}h ${minutes}m',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (hours == 0 && minutes == 0) ? null : () {
                final totalMinutes = hours * 60 + minutes;
                context.read<TimerService>().startTimer(
                  totalMinutes,
                  onComplete: () {
                    context.read<AppState>().lockScreen();
                  },
                );
                Navigator.pop(context);
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

