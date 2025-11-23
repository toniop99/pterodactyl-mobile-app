
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:universal_html/html.dart' as html;

import '../../core/app_export.dart';
import '../../data/services/pterodactyl_client_api_service.dart';
import '../../data/services/pterodactyl_service_provider.dart';
import '../../data/models/backup_model.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/backup_card_widget.dart';
import './widgets/backup_schedule_widget.dart';
import './widgets/empty_backup_state_widget.dart';
import './widgets/storage_usage_widget.dart';

class BackupManagement extends StatefulWidget {
  const BackupManagement({super.key});

  @override
  State<BackupManagement> createState() => _BackupManagementState();
}

class _BackupManagementState extends State<BackupManagement> {
  int _currentBottomNavIndex = 4;
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterMethod = 'all';
  final TextEditingController _searchController = TextEditingController();

  late PterodactylClientApiService _apiService;
  String? _serverIdentifier;
  List<BackupModel> _backups = [];
  List<BackupModel> _filteredBackups = [];

  final double _usedSpace = 11.8;
  final double _totalSpace = 50.0;
  final String _scheduleFrequency = "daily";
  final int _retentionDays = 7;

  @override
  void initState() {
    super.initState();

    // Initialize API service
    _apiService = PterodactylServiceProvider.instance.apiService;

    // Get server identifier and load backups
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBackups();
    });
  }

  Future<void> _initializeBackups() async {
    try {
      // Get server identifier from arguments or fetch first server
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      if (args != null) {
        _serverIdentifier = args;
      } else {
        final servers = await _apiService.getServers();
        if (servers.isNotEmpty) {
          _serverIdentifier = servers.first.identifier;
        }
      }

      if (_serverIdentifier != null) {
        await _loadBackups();
      }
    } catch (e) {
      _showError('Failed to initialize backups: $e');
    }
  }

  Future<void> _loadBackups() async {
    if (_serverIdentifier == null) return;

    setState(() => _isLoading = true);

    try {
      final backups = await _apiService.getBackups(_serverIdentifier!);

      if (mounted) {
        setState(() {
          _backups = backups;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load backups: $e');
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredBackups = _backups.where((backup) {
        final matchesSearch =
            backup.name.toLowerCase().contains(_searchQuery.toLowerCase());

        // Filter by method if specified
        // Note: BackupModel doesn't have method field, so we skip this filter
        final matchesFilter = _filterMethod == 'all';

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateBackupDialog() {
    final TextEditingController nameController = TextEditingController(
      text: 'backup_${DateTime.now().millisecondsSinceEpoch}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Manual Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Backup Name',
                hintText: 'Enter backup name',
              ),
            ),
            SizedBox(height: 2.h),
            const Text(
              'This will create a complete backup of your server data.',
            ),
            SizedBox(height: 1.h),
            const Text(
              'Estimated time: 5-10 minutes',
              style: TextStyle(fontStyle: FontStyle.italic),
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
              Navigator.pop(context);
              _createBackup(nameController.text.trim());
            },
            child: const Text('Create Backup'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup(String name) async {
    if (_serverIdentifier == null || name.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.createBackup(_serverIdentifier!, name);

      Fluttertoast.showToast(
        msg: "Backup creation started",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      // Reload backups after a delay
      await Future.delayed(const Duration(seconds: 2));
      await _loadBackups();
    } catch (e) {
      _showError('Failed to create backup: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadBackup(BackupModel backup) async {
    if (_serverIdentifier == null) return;

    try {
      final downloadUrl = await _apiService.getBackupDownloadUrl(
        _serverIdentifier!,
        backup.uuid,
      );

      // Open download URL in browser
      if (kIsWeb) {
        html.window.open(downloadUrl, '_blank');
      } else {
        // For mobile, show URL or implement download
        Fluttertoast.showToast(
          msg: "Download URL: $downloadUrl",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }

      Fluttertoast.showToast(
        msg: "Download started",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      _showError('Failed to download backup: $e');
    }
  }

  void _showRestoreDialog(BackupModel backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restore from: ${backup.name}'),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'warning',
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Server will be stopped during restoration. This action cannot be undone.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
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
            onPressed: () {
              Navigator.pop(context);
              _restoreBackup(backup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup(BackupModel backup) async {
    // Note: Pterodactyl API doesn't have direct restore endpoint
    // This would typically be handled through server console commands
    Fluttertoast.showToast(
      msg: "Restore functionality requires server console access",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _shareBackup(Map<String, dynamic> backup) {
    Fluttertoast.showToast(
      msg: "Sharing backup: ${backup['name']}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showDeleteDialog(BackupModel backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text(
            'Are you sure you want to delete ${backup.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBackup(backup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBackup(BackupModel backup) async {
    if (_serverIdentifier == null) return;

    try {
      await _apiService.deleteBackup(_serverIdentifier!, backup.uuid);

      setState(() {
        _backups.removeWhere((b) => b.uuid == backup.uuid);
        _applyFilters();
      });

      Fluttertoast.showToast(
        msg: "Backup deleted",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      _showError('Failed to delete backup: $e');
    }
  }

  void _showRenameDialog(Map<String, dynamic> backup) {
    final controller = TextEditingController(text: backup['name']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Backup'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Backup Name',
            hintText: 'Enter new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _renameBackup(backup, controller.text);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _renameBackup(Map<String, dynamic> backup, String newName) {
    if (newName.trim().isEmpty) return;

    setState(() {
      backup['name'] = newName;
    });

    Fluttertoast.showToast(
      msg: "Backup renamed",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showBackupDetails(Map<String, dynamic> backup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  backup['name'],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 2.h),
                _buildDetailRow('Created', backup['createdAt']),
                _buildDetailRow('Size', backup['size']),
                _buildDetailRow('Method', backup['method']),
                _buildDetailRow('Status', backup['status']),
                SizedBox(height: 3.h),
                Text(
                  'File Contents',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 1.h),
                if ((backup['files'] as List).isNotEmpty)
                  ...(backup['files'] as List).map((file) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 0.5.h),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'folder',
                              color: Theme.of(context).colorScheme.primary,
                              size: 16,
                            ),
                            SizedBox(width: 2.w),
                            Text(file),
                          ],
                        ),
                      ))
                else
                  Text(
                    'No file information available',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                SizedBox(height: 3.h),
                Text(
                  'Creation Logs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    backup['logs'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog() {
    String selectedFrequency = _scheduleFrequency;
    int selectedRetention = _retentionDays;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Backup Schedule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Frequency'),
                SizedBox(height: 1.h),
                DropdownButtonFormField<String>(
                  initialValue: selectedFrequency,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedFrequency = value);
                    }
                  },
                ),
                SizedBox(height: 2.h),
                const Text('Retention Period (days)'),
                SizedBox(height: 1.h),
                TextFormField(
                  initialValue: selectedRetention.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter number of days',
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null) {
                      selectedRetention = parsed;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Fluttertoast.showToast(
                  msg: "Schedule updated",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup Old Backups'),
        content: const Text(
          'This will delete backups older than the retention period. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Cleanup completed",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
            child: const Text('Cleanup'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Backups'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name',
                hintText: 'Enter backup name',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              initialValue: _filterMethod,
              decoration: const InputDecoration(
                labelText: 'Filter by method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'manual', child: Text('Manual')),
                DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _filterMethod = value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _filterMethod = 'all';
                _searchController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Backup Management',
        variant: CustomAppBarVariant.standard,
        actions: [
          IconButton(
            onPressed: _showSearchDialog,
            icon: CustomIconWidget(
              iconName: 'search',
              color: colorScheme.onSurface,
              size: 24,
            ),
            tooltip: 'Search',
          ),
          PopupMenuButton<String>(
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: colorScheme.onSurface,
              size: 24,
            ),
            onSelected: (value) {
              if (value == 'schedule') {
                _showScheduleDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'schedule',
                child: Text('Backup Schedule'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBackups,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredBackups.isEmpty
                ? EmptyBackupStateWidget(
                    onCreateBackup: _showCreateBackupDialog,
                  )
                : ListView(
                    children: [
                      SizedBox(height: 2.h),
                      StorageUsageWidget(
                        usedSpace: _usedSpace,
                        totalSpace: _totalSpace,
                        onCleanup: _showCleanupDialog,
                      ),
                      BackupScheduleWidget(
                        frequency: _scheduleFrequency,
                        retentionDays: _retentionDays,
                        onEdit: _showScheduleDialog,
                      ),
                      SizedBox(height: 2.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(
                          'Backups (${_filteredBackups.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      ..._filteredBackups.map((backup) {
                        // Convert BackupModel to Map for widget compatibility
                        final backupMap = {
                          "id": backup.uuid,
                          "name": backup.name,
                          "createdAt": backup.completedAt?.toString() ??
                              backup.createdAt.toString(),
                          "status":
                              backup.isSuccessful ? "completed" : "failed",
                          "method": "manual",
                          "size":
                              "${(backup.bytes / (1024 * 1024)).toStringAsFixed(2)} MB",
                          "progress": 1.0,
                          "files": [],
                          "logs": "Backup completed",
                        };

                        return BackupCardWidget(
                          backup: backupMap,
                          onTap: () => _showBackupDetails(backupMap),
                          onDownload: () => _downloadBackup(backup),
                          onRestore: () => _showRestoreDialog(backup),
                          onShare: () => _shareBackup(backupMap),
                          onDelete: () => _showDeleteDialog(backup),
                          onRename: () => _showRenameDialog(backupMap),
                        );
                      }),
                      SizedBox(height: 10.h),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBackupDialog,
        tooltip: 'Create Backup',
        child: CustomIconWidget(
          iconName: 'add',
          color: colorScheme.onTertiary,
          size: 24,
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() => _currentBottomNavIndex = index);
          final routes = [
            '/server-dashboard',
            '/server-console',
            '/file-manager',
            '/server-settings',
            '/backup-management',
          ];
          if (index < routes.length) {
            Navigator.pushNamed(context, routes[index]);
          }
        },
      ),
    );
  }
}
