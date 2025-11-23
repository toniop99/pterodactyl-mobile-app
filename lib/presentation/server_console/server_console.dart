import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pterodactyl_app/data/models/server_model.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../data/services/pterodactyl_client_api_service.dart';
import '../../data/services/pterodactyl_service_provider.dart';
import '../../data/services/pterodactyl_websocket_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/command_input_bar.dart';
import './widgets/connection_status_banner.dart';
import './widgets/console_log_entry.dart';
import './widgets/log_filter_sheet.dart';
import './widgets/quick_action_buttons.dart';

/// Server Console Screen - Real-time command execution and log monitoring
class ServerConsole extends StatefulWidget {
  const ServerConsole({super.key});

  @override
  State<ServerConsole> createState() => _ServerConsoleState();
}

class _ServerConsoleState extends State<ServerConsole> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _commandHistory = [];
  int _historyIndex = -1;

  bool _isConnected = false;
  bool _isReconnecting = false;
  bool _isCommandLoading = false;
  bool _autoScroll = true;
  String _currentFilter = 'all';
  int _currentBottomNavIndex = 1;

  late PterodactylClientApiService _apiService;
  late PterodactylWebSocketService _wsService;
  String? _serverIdentifier;
  String? _serverName;
  final List<ConsoleMessage> _logEntries = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    final provider = PterodactylServiceProvider.instance;
    _apiService = provider.apiService;
    _wsService = provider.webSocketService;

    // Get server identifier from route arguments or use first server
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConsole();
    });
  }

  Future<void> _initializeConsole() async {
    try {
      // Get server identifier from arguments or fetch first server
      final args = ModalRoute.of(context)?.settings.arguments as ServerModel?;
      if (args != null) {
        _serverIdentifier = args.identifier;
        _serverName = args.name;
      } else {
        final servers = await _apiService.getServers();
        if (servers.isNotEmpty) {
          _serverIdentifier = servers.first.identifier;
          _serverName = servers.first.name;
        }
      }

      if (_serverIdentifier != null) {
        await _connectWebSocket();
      }
    } catch (e) {
      _showError('Failed to initialize console: $e');
    }
  }

  Future<void> _connectWebSocket() async {
    if (_serverIdentifier == null) return;

    setState(() {
      _isReconnecting = true;
    });

    try {
      // Connect to WebSocket
      await _wsService.connect(
        serverIdentifier: _serverIdentifier!,
      );

      _wsService.stateStream.listen((state) {
        if (mounted) {

          if(state == WebSocketState.connected) {
            _wsService.requestLogs();
          }

          setState(() {
            _isConnected = state == WebSocketState.connected ||
                state == WebSocketState.authenticated;
            _isReconnecting = state == WebSocketState.connecting;
          });
        }
      });

      // Listen to WebSocket messages
      _wsService.messageStream.listen((message) {
        if (mounted) {
          setState(() {
            _logEntries.add(message);
            if (_logEntries.length > 1000) {
              _logEntries.removeAt(0);
            }
          });
          if (_autoScroll) {
            _scrollToBottom();
          }
        }
      });

      setState(() {
        _isReconnecting = false;
      });
    } catch (e) {
      setState(() {
        _isReconnecting = false;
      });
      _showError('Failed to connect WebSocket: $e');
    }
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isAtBottom = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50;
      if (_autoScroll != isAtBottom) {
        setState(() {
          _autoScroll = isAtBottom;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  List<ConsoleMessage> _getFilteredLogs() {
    if (_currentFilter == 'all') {
      return _logEntries;
    }
    return _logEntries
        .where((log) => log.type.name.toLowerCase() == _currentFilter)
        .toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogFilterSheet(
        currentFilter: _currentFilter,
        onFilterChanged: (filter) {
          setState(() {
            _currentFilter = filter;
          });
        },
      ),
    );
  }

  Future<void> _executeCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty || _isCommandLoading || _serverIdentifier == null) {
      return;
    }

    setState(() {
      _isCommandLoading = true;
    });

    _commandHistory.insert(0, command);
    _historyIndex = -1;

    try {
      _wsService.sendCommand(command);

      _commandController.clear();

      if (_autoScroll) {
        _scrollToBottom();
      }
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showError('Failed to send command: $e');
    } finally {
      setState(() {
        _isCommandLoading = false;
      });
    }
  }

  void _navigateHistory(bool up) {
    if (_commandHistory.isEmpty) return;

    setState(() {
      if (up) {
        if (_historyIndex < _commandHistory.length - 1) {
          _historyIndex++;
          _commandController.text = _commandHistory[_historyIndex];
        }
      } else {
        if (_historyIndex > 0) {
          _historyIndex--;
          _commandController.text = _commandHistory[_historyIndex];
        } else if (_historyIndex == 0) {
          _historyIndex = -1;
          _commandController.clear();
        }
      }
    });
  }

  void _handleQuickCommand(String command) {
    _commandController.text = command;
    if (!command.endsWith(' ')) {
      _executeCommand();
    }
  }

  void _shareLogSegment() {
    final filteredLogs = _getFilteredLogs();
    final logText = filteredLogs
        .map((log) => '[${log.timeFormatted}] ${log.message}')
        .join('\n');

    Clipboard.setData(ClipboardData(text: logText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _attemptReconnection() async {
    await _connectWebSocket();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  double _adjustTitleFontSize(String title) {
    final baseSize = 16.sp;
    if (_serverName != null && _serverIdentifier != null) {
      final totalLength = title.length;
      if (totalLength > 30) {
        return baseSize - 6.sp;
      } else if (totalLength > 20) {
        return baseSize - 4.sp;
      }
    }
    return baseSize;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredLogs = _getFilteredLogs();

    return Scaffold(
      appBar: CustomAppBar(
        title: '$_serverName - $_serverIdentifier',
        titleTextStyle: TextStyle(fontSize: _adjustTitleFontSize('$_serverName - $_serverIdentifier')),
        variant: CustomAppBarVariant.withStatus,
        showConnectionStatus: true,
        isConnected: _isConnected && !_isReconnecting,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'filter_list',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _showFilterSheet,
            tooltip: 'Filter logs',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'share',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _shareLogSegment,
            tooltip: 'Share logs',
          ),
        ],
      ),
      body: Column(
        children: [
          ConnectionStatusBanner(
            isConnected: _isConnected,
            isReconnecting: _isReconnecting,
            onRetry: _attemptReconnection,
          ),
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              child: filteredLogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName:
                                _isReconnecting ? 'sync' : 'filter_list_off',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 48,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _isReconnecting
                                ? 'Connecting to server...'
                                : 'No logs match current filter',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return ConsoleLogEntry(
                          timestamp: log.timeFormatted,
                          message: log.message,
                          type: log.type.name,
                        );
                      },
                    ),
            ),
          ),
          QuickActionButtons(
            onCommandSelected: _handleQuickCommand,
            isEnabled: _isConnected && !_isCommandLoading,
          ),
          CommandInputBar(
            controller: _commandController,
            isLoading: _isCommandLoading,
            onSend: _executeCommand,
            onHistoryUp: () => _navigateHistory(true),
            onHistoryDown: () => _navigateHistory(false),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
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

          if (index != 1) {
            Navigator.pushNamed(context, routes[index]);
          }
        },
      ),
    );
  }
}
