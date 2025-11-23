import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pterodactyl_app/core/logger.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../data/models/server_model.dart';
import '../../data/services/pterodactyl_client_api_service.dart';
import '../../data/services/pterodactyl_service_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/empty_state_widget.dart';
import './widgets/search_filter_header_widget.dart';
import './widgets/server_card_widget.dart';

/// Server Dashboard screen providing comprehensive overview of all managed game servers
class ServerDashboard extends StatefulWidget {
  const ServerDashboard({super.key});

  @override
  State<ServerDashboard> createState() => _ServerDashboardState();
}

class _ServerDashboardState extends State<ServerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<ServerModel> _servers = [];
  List<ServerModel> _filteredServers = [];
  bool _isLoading = false;
  bool _isConnected = true;
  String _selectedFilter = 'all';
  late PterodactylClientApiService _apiService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _apiService = PterodactylServiceProvider.instance.apiService;
    _loadServers();
    _startRealtimeUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServers() async {
    setState(() => _isLoading = true);
    try {
      final servers = await _apiService.getServers();

      if (mounted) {
        setState(() {
          _servers = servers;
          _filteredServers = List.from(_servers);
          _isLoading = false;
          _isConnected = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isConnected = false;
        });
        Fluttertoast.showToast(
          msg: "Failed to load servers: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  Future<ServerResourceUsage?> _getResourcesForServer(String identifier) async {
    try {
      final resources = await _apiService.getServerResources(identifier);
      return resources;
    } catch (e) {
      return null;
    }
  }

  void _startRealtimeUpdates() {
    Future.delayed(const Duration(seconds: 10), () async {
      if (mounted && _servers.isNotEmpty) {
        try {
          List<ServerModel> updatedServers = List.from(_servers);

          for (int i = 0; i < updatedServers.length; i++) {
            try {
              final resources = await _getResourcesForServer(updatedServers[i].identifier);
              if (mounted) {
                updatedServers[i] =
                    updatedServers[i].copyWith(
                      resources: resources, 
                      status: ServerStatus.fromString(resources?.currentState ?? 'unknown')
                    );
              }
            } catch (e) {
              // Silently continue if resource fetch fails for individual server
              AppLogger.warning(
                  'Failed to fetch resources for ${updatedServers[i].identifier}: $e');
            }
          }
          if (mounted) {
            setState(() {
              // order updated servers based on status priority and then name
              updatedServers.sort((a, b) {
                final statusPriority = {
                  ServerStatus.running.value : 1,
                  ServerStatus.starting.value : 2,
                  ServerStatus.stopping.value : 3,
                  ServerStatus.offline.value : 4,
                  ServerStatus.unknown.value : 5,
                };
                final aPriority = statusPriority[a.status.value] ?? 99;
                final bPriority = statusPriority[b.status.value] ?? 99;
                if (aPriority != bPriority) {
                  return aPriority.compareTo(bPriority);
                }
                return a.name.compareTo(b.name);
              });

              _servers = updatedServers;
              _applyFilter();
            });
          }
        } catch (e) {
          AppLogger.error('Error in realtime updates: $e');
        }
        _startRealtimeUpdates();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _applyFilter();
    });
  }

  void _onFilterPressed() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'Filter Servers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(),
            _buildFilterOption('All Servers', 'all'),
            _buildFilterOption('Online', 'online'),
            _buildFilterOption('Offline', 'offline'),
            _buildFilterOption('Starting', 'starting'),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ListTile(
      leading: CustomIconWidget(
        iconName: isSelected ? 'check_circle' : 'radio_button_unchecked',
        color: isSelected
            ? AppTheme.primaryLight
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(label),
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        _applyFilter();
        Navigator.pop(context);
      },
    );
  }

  void _applyFilter() {
    List<ServerModel> tempServers = List.from(_servers);
    final query = _searchController.text.toLowerCase();

    if (query.isNotEmpty) {
      tempServers = tempServers.where((server) {
        return server.name.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedFilter != 'all') {
      tempServers = tempServers.where((server) {
        final status = server.status.value.toLowerCase();
        return status == _selectedFilter;
      }).toList();
    }

    setState(() {
      _filteredServers = tempServers;
    });
  }

  Future<void> _onRefresh() async {
    await _loadServers();
    Fluttertoast.showToast(
      msg: "Servers refreshed",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onServerTap(ServerModel server) {
    Navigator.pushNamed(
      context,
      '/server-console',
      arguments: server,
    );
  }

  Future<void> _showActionConfirmation(
      String action, ServerModel server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Server'),
        content: Text('Are you sure you want to $action "${server.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _executePowerAction(server, action);
    }
  }

  Future<void> _executePowerAction(ServerModel server, String action) async {
    try {
      final powerSignal = action.toLowerCase();
      await _apiService.sendPowerAction(server.identifier, powerSignal);
      Fluttertoast.showToast(
        msg: "$action command sent to ${server.name}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      // Refresh server list after action
      await Future.delayed(const Duration(seconds: 2));
      await _loadServers();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to $action server: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _onAddServer() {
    Fluttertoast.showToast(
      msg: "Add server functionality",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Server Dashboard',
        variant: CustomAppBarVariant.withStatus,
        showConnectionStatus: true,
        isConnected: _isConnected,
        showSettingsButton: true,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'notifications',
              size: 6.w,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              Fluttertoast.showToast(
                msg: "Notifications",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Console'),
                Tab(text: 'Files'),
                Tab(text: 'Settings'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildPlaceholderTab('Console'),
                _buildPlaceholderTab('Files'),
                _buildPlaceholderTab('Settings'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 0,
        onTap: (index) {
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
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddServer,
        tooltip: 'Add Server',
        child: const CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return Column(
      children: [
        SearchFilterHeaderWidget(
          searchController: _searchController,
          onSearchChanged: _onSearchChanged,
          onFilterPressed: _onFilterPressed,
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredServers.isEmpty
                  ? EmptyStateWidget(onAddServer: _onAddServer)
                  : RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        padding: EdgeInsets.only(top: 2.h, bottom: 2.h),
                        itemCount: _filteredServers.length,
                        itemBuilder: (context, index) {
                          final server = _filteredServers[index];
                          // Convert ServerModel to Map for widget compatibility
                          final serverMap = {
                            "id": server.internalId,
                            "name": server.name,
                            "gameType": server.description,
                            "gameIcon":
                                "https://images.unsplash.com/photo-1522152767612-d2f4703f22e6",
                            "gameIconLabel": "${server.name} server icon",
                            "status": server.status.value,
                            "currentPlayers": 0, // Would come from resources
                            "cpuUsage": ((server.resources?.resources.cpuAbsolute ?? 0) / 100),
                            "ramUsage": (server.resources?.resources.memoryBytes ?? 0) /
                                (server.limits.memoryInBytes),
                            "uptime": server.resources?.resources.uptimeFormatted ?? '0h 0m',
                            "lastUpdated": DateTime.now(),
                          };
                          return ServerCardWidget(
                            server: serverMap,
                            onTap: () => _onServerTap(server),
                            onStart: () =>
                                _showActionConfirmation('Start', server),
                            onStop: () =>
                                _showActionConfirmation('Stop', server),
                            onRestart: () =>
                                _showActionConfirmation('Restart', server),
                            onViewLogs: () {
                              Navigator.pushNamed(
                                context,
                                '/server-console',
                                arguments: server.identifier,
                              );
                            },
                            onBackup: () {
                              Navigator.pushNamed(
                                context,
                                '/backup-management',
                                arguments: server.identifier,
                              );
                            },
                            onSettings: () {
                              Navigator.pushNamed(
                                context,
                                '/server-settings',
                                arguments: server.identifier,
                              );
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderTab(String tabName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'construction',
            size: 20.w,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            '$tabName Tab',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 1.h),
          Text(
            'This tab will be implemented in the next phase',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
