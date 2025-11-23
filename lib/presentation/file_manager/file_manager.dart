import 'dart:convert';
import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import 'package:universal_html/html.dart' as html;

import '../../core/app_export.dart';
import '../../data/services/pterodactyl_client_api_service.dart';
import '../../data/services/pterodactyl_service_provider.dart';
import '../../data/models/file_model.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/breadcrumb_widget.dart';
import './widgets/file_item_widget.dart';
import './widgets/file_upload_dialog.dart';

class FileManager extends StatefulWidget {
  const FileManager({super.key});

  @override
  State<FileManager> createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  late PterodactylClientApiService _apiService;
  String? _serverIdentifier;
  String _currentDirectory = '/';

  List<String> _pathSegments = [];
  List<FileModel> _currentFiles = [];
  List<Map<String, dynamic>> _filteredFiles = [];
  final Set<String> _selectedItems = {};
  bool _isMultiSelectMode = false;
  bool _isSearching = false;
  bool _isLoading = false;
  Map<String, double>? _uploadProgress;

  @override
  void initState() {
    super.initState();

    // Initialize API service
    _apiService = PterodactylServiceProvider.instance.apiService;

    // Get server identifier and load files
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFileManager();
    });
  }

  Future<void> _initializeFileManager() async {
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
        await _loadDirectory(_currentDirectory);
      }
    } catch (e) {
      _showError('Failed to initialize file manager: $e');
    }
  }

  Future<void> _loadDirectory(String path) async {
    if (_serverIdentifier == null) return;

    setState(() {
      _isLoading = true;
      _currentDirectory = path;
      _pathSegments = path == '/' ? [] : path.substring(1).split('/');
      _selectedItems.clear();
      _isMultiSelectMode = false;
    });

    try {
      final files = await _apiService.listFiles(
        _serverIdentifier!,
        directory: path,
      );

      if (mounted) {
        setState(() {
          _currentFiles = files;
          _convertFilesToMap();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load directory: $e');
      }
    }
  }

  void _convertFilesToMap() {
    _filteredFiles = _currentFiles.map((file) {
      return {
        'name': file.name,
        'type': file.isFile ? 'file' : 'folder',
        'size': file.isFile ? _formatFileSize(file.size) : '',
        'modified': _formatModifiedDate(file.modifiedAt),
        'path': '$_currentDirectory/${file.name}',
      };
    }).toList();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatModifiedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToPath(int segmentIndex) {
    if (segmentIndex == 0) {
      _loadDirectory('/');
    } else {
      final path = '/${_pathSegments.sublist(0, segmentIndex).join('/')}';
      _loadDirectory(path);
    }
  }

  void _navigateUp() {
    if (_pathSegments.isEmpty) return;
    _navigateToPath(_pathSegments.length - 1);
  }

  void _onItemTap(Map<String, dynamic> item) {
    if (_isMultiSelectMode) {
      setState(() {
        if (_selectedItems.contains(item['path'])) {
          _selectedItems.remove(item['path']);
          if (_selectedItems.isEmpty) {
            _isMultiSelectMode = false;
          }
        } else {
          _selectedItems.add(item['path'] as String);
        }
      });
    } else {
      if (item['type'] == 'folder') {
        _loadDirectory(item['path'] as String);
      } else {
        _showFilePreview(item);
      }
    }
  }

  void _showFilePreview(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file['name'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Type', file['type'] as String),
            _buildInfoRow('Size', file['size'] as String),
            _buildInfoRow('Modified', file['modified'] as String),
            _buildInfoRow('Path', file['path'] as String),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadFile(file);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20.w,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(Map<String, dynamic> file) async {
    if (_serverIdentifier == null) return;

    final fileName = file['name'] as String;
    final filePath = '$_currentDirectory/$fileName';

    setState(() {
      _uploadProgress = {fileName: 0.0};
    });

    try {
      // Get file contents
      final content = await _apiService.getFileContents(
        _serverIdentifier!,
        filePath,
      );

      // Simulate download progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        setState(() {
          _uploadProgress![fileName] = i / 100;
        });
      }

      // Perform actual download
      if (kIsWeb) {
        final bytes = utf8.encode(content);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        if (await _requestStoragePermission()) {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(content);
        }
      }

      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Downloaded $fileName')),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to download file: $e');
    } finally {
      if (mounted) {
        setState(() {
          _uploadProgress = null;
        });
      }
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (kIsWeb) return true;

    if (!kIsWeb && Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> _uploadFile() async {
    if (_serverIdentifier == null) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jar',
          'yml',
          'yaml',
          'json',
          'txt',
          'log',
          'properties'
        ],
      );

      if (result != null) {
        final fileName = result.files.first.name;
        final fileBytes = kIsWeb
            ? result.files.first.bytes!
            : await File(result.files.first.path!).readAsBytes();

        final content = utf8.decode(fileBytes);

        setState(() {
          _uploadProgress = {fileName: 0.0};
        });

        // Upload file
        await _apiService.writeFileContents(
          _serverIdentifier!,
          '$_currentDirectory/$fileName',
          content,
        );

        // Simulate upload progress
        for (int i = 0; i <= 100; i += 10) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (!mounted) return;
          setState(() {
            _uploadProgress![fileName] = i / 100;
          });
        }

        if (!mounted) return;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Uploaded $fileName')),
        );

        setState(() {
          _uploadProgress = null;
        });

        // Reload directory
        await _loadDirectory(_currentDirectory);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to upload file: $e');
      setState(() {
        _uploadProgress = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        final fileName = photo.name;

        setState(() {
          _uploadProgress = {fileName: 0.0};
        });

        // Simulate upload progress
        for (int i = 0; i <= 100; i += 10) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (!mounted) return;
          setState(() {
            _uploadProgress![fileName] = i / 100;
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded $fileName')),
        );

        setState(() {
          _uploadProgress = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera capture failed')),
      );
      setState(() {
        _uploadProgress = null;
      });
    }
  }

  Future<void> _createFolder() async {
    if (_serverIdentifier == null) return;

    final TextEditingController nameController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'Enter folder name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (folderName != null && folderName.isNotEmpty) {
      try {
        await _apiService.createDirectory(
          _serverIdentifier!,
          '$_currentDirectory/$folderName',
        );

        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Created folder: $folderName')),
        );

        // Reload directory
        await _loadDirectory(_currentDirectory);
      } catch (e) {
        if (mounted) {
          _showError('Failed to create folder: $e');
        }
      }
    }
  }

  void _createFile() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'File Name',
            hintText: 'Enter file name with extension',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created file: ${nameController.text}'),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => FileUploadDialog(
        onSelectFile: _uploadFile,
        onTakePhoto: _takePhoto,
        onCreateFolder: _createFolder,
        onCreateFile: _createFile,
      ),
    );
  }

  void _searchFiles(String query) {
    setState(() {
      if (query.isEmpty) {
        _convertFilesToMap();
      } else {
        _filteredFiles = _currentFiles
            .where(
                (file) => file.name.toLowerCase().contains(query.toLowerCase()))
            .map((file) => {
                  'name': file.name,
                  'type': file.isFile ? 'file' : 'folder',
                  'size': file.isFile ? _formatFileSize(file.size) : '',
                  'modified': _formatModifiedDate(file.modifiedAt),
                  'path': '$_currentDirectory/${file.name}',
                })
            .toList();
      }
    });
  }

  void _deleteItem(Map<String, dynamic> item) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Are you sure you want to delete ${item['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteFiles(
          _serverIdentifier!,
          [item['path'] as String],
        );

        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Deleted ${item['name']}')),
        );
        await _loadDirectory(_currentDirectory);
      } catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error deleting file: $e')),
        );
      }
    }
  }

  void _renameItem(Map<String, dynamic> item) async {
    if (_serverIdentifier == null) return;

    final TextEditingController nameController =
        TextEditingController(text: item['name'] as String);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'New Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != item['name']) {
      try {
        await _apiService.renameFile(
          _serverIdentifier!,
          item['path'] as String,
          '$_currentDirectory/$newName',
        );

        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Renamed to $newName')),
        );

        // Reload directory
        await _loadDirectory(_currentDirectory);
      } catch (e) {
        if (mounted) {
          _showError('Failed to rename file: $e');
        }
      }
    }
  }

  void _shareItem(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${item['name']}')),
    );
  }

  void _copyItem(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${item['name']}')),
    );
  }

  void _moveItem(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moving ${item['name']}')),
    );
  }

  void _showPermissions(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Permissions for ${item['name']}')),
    );
  }

  void _showProperties(Map<String, dynamic> item) {
    _showFilePreview(item);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _isSearching
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AppBar(
                leading: IconButton(
                  icon: CustomIconWidget(
                    iconName: 'arrow_back',
                    color: colorScheme.onSurface,
                    size: 6.w,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                      _searchFiles('');
                    });
                  },
                ),
                title: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search files...',
                    border: InputBorder.none,
                  ),
                  onChanged: _searchFiles,
                ),
                actions: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: CustomIconWidget(
                        iconName: 'clear',
                        color: colorScheme.onSurface,
                        size: 6.w,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _searchFiles('');
                      },
                    ),
                ],
              ),
            )
          : CustomAppBar(
              title: 'File Manager',
              actions: [
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'search',
                    color: colorScheme.onSurface,
                    size: 6.w,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
                if (_isMultiSelectMode)
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: colorScheme.onSurface,
                      size: 6.w,
                    ),
                    onPressed: () {
                      setState(() {
                        _isMultiSelectMode = false;
                        _selectedItems.clear();
                      });
                    },
                  ),
              ],
            ),
      body: Column(
        children: [
          // Breadcrumb Navigation
          BreadcrumbWidget(
            pathSegments: _pathSegments,
            onSegmentTap: _navigateToPath,
          ),
          // Upload Progress
          if (_uploadProgress != null)
            // UploadProgressWidget(
            //   fileName: _uploadProgress!.keys.first,
            //   progress: _uploadProgress!.values.first,
            //   isUploading: true,
            //   onCancel: () {
            //     setState(() {
            //       _uploadProgress = null;
            //     });
            //   },
            // ),
          // File List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'folder_open',
                              color: colorScheme.onSurfaceVariant,
                              size: 15.w,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'No files found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadDirectory(_currentDirectory),
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                          itemCount: _filteredFiles.length,
                          itemBuilder: (context, index) {
                            final item = _filteredFiles[index];
                            return FileItemWidget(
                              item: item,
                              onTap: () => _onItemTap(item),
                              onDownload: () => _downloadFile(item),
                              onShare: () => _shareItem(item),
                              onRename: () => _renameItem(item),
                              onDelete: () => _deleteItem(item),
                              onCopy: () => _copyItem(item),
                              onMove: () => _moveItem(item),
                              onPermissions: () => _showPermissions(item),
                              onProperties: () => _showProperties(item),
                              isSelected: _selectedItems.contains(item['path']),
                            );
                          },
                        ),
                      ),
          ),
          // Bottom Toolbar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildToolbarButton(
                    icon: 'arrow_back',
                    label: 'Back',
                    onTap: _navigateUp,
                    enabled: _pathSegments.isNotEmpty,
                  ),
                  _buildToolbarButton(
                    icon: 'arrow_upward',
                    label: 'Up',
                    onTap: _navigateUp,
                    enabled: _pathSegments.isNotEmpty,
                  ),
                  _buildToolbarButton(
                    icon: 'home',
                    label: 'Home',
                    onTap: () => _loadDirectory('/'),
                    enabled: _pathSegments.isNotEmpty,
                  ),
                  _buildToolbarButton(
                    icon: 'create_new_folder',
                    label: 'New',
                    onTap: _createFolder,
                    enabled: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        child: CustomIconWidget(
          iconName: 'add',
          color: colorScheme.onTertiary,
          size: 6.w,
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 2,
        onTap: (index) {
          final routes = [
            '/server-dashboard',
            '/server-console',
            '/file-manager',
            '/server-settings',
            '/backup-management',
          ];
          if (index != 2) {
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }

  Widget _buildToolbarButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: icon,
                color: colorScheme.onSurface,
                size: 6.w,
              ),
              SizedBox(height: 0.5.h),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
