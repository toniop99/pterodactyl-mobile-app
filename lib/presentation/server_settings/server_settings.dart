import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/dropdown_setting_widget.dart';
import './widgets/port_management_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/slider_setting_widget.dart';
import './widgets/text_field_setting_widget.dart';
import './widgets/toggle_setting_widget.dart';

/// Server Settings Screen
/// Provides comprehensive configuration management for game server parameters
class ServerSettings extends StatefulWidget {
  const ServerSettings({super.key});

  @override
  State<ServerSettings> createState() => _ServerSettingsState();
}

class _ServerSettingsState extends State<ServerSettings> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  late TextEditingController _serverNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _startupCommandController;

  // Settings state
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  // General settings
  late String _serverName;
  late String _description;
  late String _startupCommand;

  // Performance settings
  double _cpuLimit = 2.0;
  double _ramLimit = 4096.0;
  double _diskLimit = 10240.0;

  // Network settings
  List<Map<String, dynamic>> _ports = [];

  // Boolean settings
  bool _autoStart = true;
  bool _crashDetection = true;
  bool _backupScheduling = false;

  // Dropdown settings
  String _javaVersion = 'Java 17';
  String _gameMode = 'Survival';

  // Current usage mock data
  final String _currentCpuUsage = '45%';
  final String _currentRamUsage = '2.1 GB';
  final String _currentDiskUsage = '5.2 GB';

  // Bottom navigation
  int _currentBottomNavIndex = 3; // Settings tab

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _initializeSettings() {
    // Initialize with mock server data
    _serverName = 'Minecraft Survival Server';
    _description = 'A friendly survival server for the community';
    _startupCommand = 'java -Xmx4G -Xms1G -jar server.jar nogui';

    _serverNameController = TextEditingController(text: _serverName);
    _descriptionController = TextEditingController(text: _description);
    _startupCommandController = TextEditingController(text: _startupCommand);

    // Initialize ports
    _ports = [
      {"port": 25565, "protocol": "TCP"},
      {"port": 25575, "protocol": "TCP (RCON)"},
    ];

    // Add listeners to detect changes
    _serverNameController.addListener(_onSettingChanged);
    _descriptionController.addListener(_onSettingChanged);
    _startupCommandController.addListener(_onSettingChanged);
  }

  void _onSettingChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _serverNameController.dispose();
    _descriptionController.dispose();
    _startupCommandController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
            'You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Discard',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSaving = false;
      _hasUnsavedChanges = false;
    });

    if (mounted) {
      Fluttertoast.showToast(
        msg: "Settings saved successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: Colors.white,
      );

      Navigator.of(context).pop();
    }
  }

  void _addPort() {
    showDialog(
      context: context,
      builder: (context) {
        final portController = TextEditingController();
        String selectedProtocol = 'TCP';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Port'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Port Number',
                      hintText: 'e.g., 25565',
                    ),
                  ),
                  SizedBox(height: 2.h),
                  DropdownButtonFormField<String>(
                    value: selectedProtocol,
                    items: ['TCP', 'UDP', 'TCP/UDP'].map((String protocol) {
                      return DropdownMenuItem<String>(
                        value: protocol,
                        child: Text(protocol),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedProtocol = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Protocol',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final port = int.tryParse(portController.text);
                    if (port != null && port > 0 && port <= 65535) {
                      setState(() {
                        _ports.add({
                          "port": port,
                          "protocol": selectedProtocol,
                        });
                        _hasUnsavedChanges = true;
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removePort(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Port'),
        content: Text(
            'Are you sure you want to remove port ${_ports[index]["port"]}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _ports.removeAt(index);
                _hasUnsavedChanges = true;
              });
              Navigator.of(context).pop();
            },
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteServerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Server'),
        content: const Text(
          'This action cannot be undone. All server data, files, and backups will be permanently deleted. Type "DELETE" to confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteConfirmationDialog();
            },
            child: Text(
              'Continue',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Type "DELETE" to confirm server deletion:'),
            SizedBox(height: 2.h),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: 'DELETE',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (confirmController.text == 'DELETE') {
                Navigator.of(context).pop();
                Fluttertoast.showToast(
                  msg: "Server deletion initiated",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  textColor: Colors.white,
                );
                Navigator.of(context).pushReplacementNamed('/server-dashboard');
              }
            },
            child: Text(
              'Delete Server',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Server Settings',
          variant: CustomAppBarVariant.standard,
          actions: [
            if (_hasUnsavedChanges)
              TextButton(
                onPressed: () {
                  setState(() {
                    _serverNameController.text = _serverName;
                    _descriptionController.text = _description;
                    _startupCommandController.text = _startupCommand;
                    _hasUnsavedChanges = false;
                  });
                },
                child: const Text('Cancel'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 2.h),

                // General Settings Section
                SettingsSectionWidget(
                  title: 'General',
                  initiallyExpanded: true,
                  children: [
                    TextFieldSettingWidget(
                      label: 'Server Name',
                      hint: 'Enter server name',
                      controller: _serverNameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Server name is required';
                        }
                        if (value.length < 3) {
                          return 'Server name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    TextFieldSettingWidget(
                      label: 'Description',
                      hint: 'Enter server description',
                      controller: _descriptionController,
                      maxLines: 3,
                    ),
                    TextFieldSettingWidget(
                      label: 'Startup Command',
                      hint: 'Enter startup command',
                      controller: _startupCommandController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Startup command is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                // Performance Settings Section
                SettingsSectionWidget(
                  title: 'Performance',
                  children: [
                    SliderSettingWidget(
                      label: 'CPU Limit',
                      value: _cpuLimit,
                      min: 1.0,
                      max: 8.0,
                      divisions: 7,
                      unit: 'cores',
                      currentUsage: _currentCpuUsage,
                      onChanged: (value) {
                        setState(() {
                          _cpuLimit = value;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    SliderSettingWidget(
                      label: 'RAM Limit',
                      value: _ramLimit,
                      min: 1024.0,
                      max: 16384.0,
                      divisions: 15,
                      unit: 'MB',
                      currentUsage: _currentRamUsage,
                      onChanged: (value) {
                        setState(() {
                          _ramLimit = value;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    SliderSettingWidget(
                      label: 'Disk Limit',
                      value: _diskLimit,
                      min: 5120.0,
                      max: 51200.0,
                      divisions: 45,
                      unit: 'MB',
                      currentUsage: _currentDiskUsage,
                      onChanged: (value) {
                        setState(() {
                          _diskLimit = value;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  ],
                ),

                // Network Settings Section
                SettingsSectionWidget(
                  title: 'Network',
                  children: [
                    PortManagementWidget(
                      ports: _ports,
                      onAddPort: _addPort,
                      onRemovePort: _removePort,
                    ),
                  ],
                ),

                // Security Settings Section
                SettingsSectionWidget(
                  title: 'Security',
                  children: [
                    ToggleSettingWidget(
                      label: 'Auto-start on Boot',
                      description:
                          'Automatically start server when system boots',
                      value: _autoStart,
                      onChanged: (value) {
                        setState(() {
                          _autoStart = value;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    ToggleSettingWidget(
                      label: 'Crash Detection',
                      description: 'Automatically restart server on crash',
                      value: _crashDetection,
                      onChanged: (value) {
                        setState(() {
                          _crashDetection = value;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    ToggleSettingWidget(
                      label: 'Backup Scheduling',
                      description: 'Enable automatic backup scheduling',
                      value: _backupScheduling,
                      onChanged: (value) {
                        setState(() {
                          _backupScheduling = value;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  ],
                ),

                // Advanced Settings Section
                SettingsSectionWidget(
                  title: 'Advanced',
                  children: [
                    DropdownSettingWidget(
                      label: 'Java Version',
                      value: _javaVersion,
                      options: ['Java 8', 'Java 11', 'Java 17', 'Java 21'],
                      onChanged: (value) {
                        setState(() {
                          _javaVersion = value!;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    DropdownSettingWidget(
                      label: 'Game Mode',
                      value: _gameMode,
                      options: [
                        'Survival',
                        'Creative',
                        'Adventure',
                        'Spectator'
                      ],
                      onChanged: (value) {
                        setState(() {
                          _gameMode = value!;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    SizedBox(height: 2.h),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showDeleteServerDialog,
                        icon: CustomIconWidget(
                          iconName: 'delete_forever',
                          color: colorScheme.error,
                          size: 20,
                        ),
                        label: Text(
                          'Delete Server',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme.error),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10.h),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasUnsavedChanges)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow,
                      blurRadius: 8.0,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 6.h),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ),
            CustomBottomBar(
              currentIndex: _currentBottomNavIndex,
              onTap: (index) {
                if (index == _currentBottomNavIndex) return;

                if (_hasUnsavedChanges) {
                  _onWillPop().then((shouldNavigate) {
                    if (shouldNavigate) {
                      setState(() {
                        _currentBottomNavIndex = index;
                      });

                      final routes = [
                        '/server-dashboard',
                        '/server-console',
                        '/file-manager',
                        '/server-settings',
                        '/backup-management',
                      ];

                      Navigator.pushReplacementNamed(context, routes[index]);
                    }
                  });
                } else {
                  setState(() {
                    _currentBottomNavIndex = index;
                  });

                  final routes = [
                    '/server-dashboard',
                    '/server-console',
                    '/file-manager',
                    '/server-settings',
                    '/backup-management',
                  ];

                  Navigator.pushReplacementNamed(context, routes[index]);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
