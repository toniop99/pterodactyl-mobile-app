/// Pterodactyl Server Model
class ServerModel {
  final String identifier;
  final int internalId;
  final String uuid;
  final String name;
  final String node;
  final SftpDetails sftpDetails;
  final String description;
  final ServerStatus status;
  final ServerResourceUsage? resources;
  final ServerLimits limits;
  final ServerFeatureLimits featureLimits;
  final bool isServerOwner;
  final bool isSuspended;
  final bool isInstalling;
  final bool isTransferring;
  final ServerAllocation allocation;

  ServerModel({
    required this.identifier,
    required this.internalId,
    required this.uuid,
    required this.name,
    required this.node,
    required this.sftpDetails,
    required this.description,
    required this.status,
    this.resources,
    required this.limits,
    required this.featureLimits,
    required this.isServerOwner,
    required this.isSuspended,
    required this.isInstalling,
    required this.isTransferring,
    required this.allocation,
  });

  factory ServerModel.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? json;
    
    // Find the default allocation
    final allocations = attributes['relationships']?['allocations']?['data'] as List<dynamic>? ?? [];
    final defaultAllocationData = allocations.firstWhere(
      (alloc) => alloc['attributes']['is_default'] == true,
      orElse: () => allocations.isNotEmpty ? allocations.first : null,
    );

    return ServerModel(
      identifier: attributes['identifier'] ?? '',
      internalId: attributes['internal_id'] ?? 0,
      uuid: attributes['uuid'] ?? '',
      name: attributes['name'] ?? '',
      node: attributes['node'] ?? '',
      sftpDetails: SftpDetails.fromJson(attributes['sftp_details'] ?? {}),
      description: attributes['description'] ?? '',
      status: ServerStatus.fromString(attributes['status'] ?? ServerStatus.unknown.value),
      resources: attributes['resources'] != null
          ? ServerResourceUsage.fromJson(attributes['resources'])
          : null,
      limits: ServerLimits.fromJson(attributes['limits'] ?? {}),
      featureLimits:
          ServerFeatureLimits.fromJson(attributes['feature_limits'] ?? {}),
      isServerOwner: attributes['server_owner'] ?? false,
      isSuspended: attributes['is_suspended'] ?? false,
      isInstalling: attributes['is_installing'] ?? false,
      isTransferring: attributes['is_transferring'] ?? false,
      allocation: ServerAllocation.fromJson(defaultAllocationData?['attributes'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'internal_id': internalId,
      'uuid': uuid,
      'name': name,
      'node': node,
      'sftp_details': sftpDetails.toJson(),
      'description': description,
      'status': status.value,
      'resources': resources?.toJson(),
      'limits': limits.toJson(),
      'feature_limits': featureLimits.toJson(),
      'server_owner': isServerOwner,
      'is_suspended': isSuspended,
      'is_installing': isInstalling,
      'is_transferring': isTransferring,
      'allocation': allocation.toJson(),
    };
  }

  ServerModel copyWith({
    String? identifier,
    int? internalId,
    String? uuid,
    String? name,
    String? node,
    SftpDetails? sftpDetails,
    String? description,
    ServerStatus? status,
    ServerResourceUsage? resources,
    ServerLimits? limits,
    ServerFeatureLimits? featureLimits,
    bool? isServerOwner,
    bool? isSuspended,
    bool? isInstalling,
    bool? isTransferring,
    ServerAllocation? allocation,
  }) {
    return ServerModel(
      identifier: identifier ?? this.identifier,
      internalId: internalId ?? this.internalId,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      node: node ?? this.node,
      sftpDetails: sftpDetails ?? this.sftpDetails,
      description: description ?? this.description,
      status: status ?? this.status,
      resources: resources ?? this.resources,
      limits: limits ?? this.limits,
      featureLimits: featureLimits ?? this.featureLimits,
      isServerOwner: isServerOwner ?? this.isServerOwner,
      isSuspended: isSuspended ?? this.isSuspended,
      isInstalling: isInstalling ?? this.isInstalling,
      isTransferring: isTransferring ?? this.isTransferring,
      allocation: allocation ?? this.allocation,
    );
  }
}

/// SFTP Details
class SftpDetails {
  final String ip;
  final int port;

  SftpDetails({required this.ip, required this.port});

  factory SftpDetails.fromJson(Map<String, dynamic> json) {
    return SftpDetails(
      ip: json['ip'] ?? '',
      port: json['port'] ?? 2022,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'port': port,
    };
  }
}

/// Server Allocation
class ServerAllocation {
  final int id;
  final String ip;
  final String? ipAlias;
  final int port;
  final String? notes;
  final bool isDefault;

  ServerAllocation({
    required this.id,
    required this.ip,
    this.ipAlias,
    required this.port,
    this.notes,
    required this.isDefault,
  });

  factory ServerAllocation.fromJson(Map<String, dynamic> json) {
    return ServerAllocation(
      id: json['id'] ?? 0,
      ip: json['ip'] ?? '',
      ipAlias: json['ip_alias'],
      port: json['port'] ?? 0,
      notes: json['notes'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ip': ip,
      'ip_alias': ipAlias,
      'port': port,
      'notes': notes,
      'is_default': isDefault,
    };
  }
}

/// Server Status Enum
enum ServerStatus {
  running('running'),
  offline('offline'),
  starting('starting'),
  stopping('stopping'),
  unknown('unknown');

  final String value;
  const ServerStatus(this.value);

  static int getPriority(ServerStatus status) {
    switch (status) {
      case ServerStatus.running:
        return 1;
      case ServerStatus.starting:
        return 2;
      case ServerStatus.stopping:
        return 3;
      case ServerStatus.offline:
        return 4;
      case ServerStatus.unknown:
        return 5;
    }
  }

  static ServerStatus fromString(String status) {
    return ServerStatus.values.firstWhere(
      (e) => e.value == status.toLowerCase(),
      orElse: () => ServerStatus.unknown,
    );
  }
}



/// Server Resource Limits
class ServerLimits {
  final int memoryInMBytes;
  final int swap;
  final int disk;
  final int io;
  final int cpu;

  ServerLimits({
    required this.memoryInMBytes,
    required this.swap,
    required this.disk,
    required this.io,
    required this.cpu,
  });

  factory ServerLimits.fromJson(Map<String, dynamic> json) {
    return ServerLimits(
      memoryInMBytes: json['memory'] ?? 1,
      swap: json['swap'] ?? 0,
      disk: json['disk'] ?? 0,
      io: json['io'] ?? 500,
      cpu: json['cpu'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memory': memoryInMBytes,
      'swap': swap,
      'disk': disk,
      'io': io,
      'cpu': cpu,
    };
  }

  double get memoryInBytes => memoryInMBytes * 1024 * 1024;
}

/// Server Feature Limits
class ServerFeatureLimits {
  final int databases;
  final int allocations;
  final int backups;

  ServerFeatureLimits({
    required this.databases,
    required this.allocations,
    required this.backups,
  });

  factory ServerFeatureLimits.fromJson(Map<String, dynamic> json) {
    return ServerFeatureLimits(
      databases: json['databases'] ?? 0,
      allocations: json['allocations'] ?? 0,
      backups: json['backups'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'databases': databases,
      'allocations': allocations,
      'backups': backups,
    };
  }
}

/// Server Resource Usage
class ServerResourceUsage {
  final String currentState;
  final bool isSuspended;
  final ServerResources resources;

  ServerResourceUsage({
    required this.currentState,
    required this.isSuspended,
    required this.resources,
  });

  factory ServerResourceUsage.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? json;
    return ServerResourceUsage(
      currentState: attributes['current_state'] ?? 'offline',
      isSuspended: attributes['is_suspended'] ?? false,
      resources: ServerResources.fromJson(attributes['resources'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_state': currentState,
      'is_suspended': isSuspended,
      'resources': resources.toJson(),
    };
  }
}

/// Server Resources
class ServerResources {
  final int memoryBytes;
  final int memoryLimitBytes;
  final int cpuAbsolute;
  final int diskBytes;
  final int networkRxBytes;
  final int networkTxBytes;
  final int uptimeInMilliseconds;

  ServerResources({
    required this.memoryBytes,
    required this.memoryLimitBytes,
    required this.cpuAbsolute,
    required this.diskBytes,
    required this.networkRxBytes,
    required this.networkTxBytes,
    required this.uptimeInMilliseconds,
  });

  factory ServerResources.fromJson(Map<String, dynamic> json) {
    return ServerResources(
      memoryBytes: json['memory_bytes'] ?? 0,
      memoryLimitBytes: json['memory_limit_bytes'] ?? 1,
      cpuAbsolute: (json['cpu_absolute'] ?? 0).round(),
      diskBytes: json['disk_bytes'] ?? 0,
      networkRxBytes: json['network_rx_bytes'] ?? 0,
      networkTxBytes: json['network_tx_bytes'] ?? 0,
      uptimeInMilliseconds: json['uptime'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memory_bytes': memoryBytes,
      'memory_limit_bytes': memoryLimitBytes,
      'cpu_absolute': cpuAbsolute,
      'disk_bytes': diskBytes,
      'network_rx_bytes': networkRxBytes,
      'network_tx_bytes': networkTxBytes,
      'uptime': uptimeInMilliseconds,
    };
  }

  double get memoryMB => memoryBytes / 1024 / 1024;
  double get diskGB => diskBytes / 1024 / 1024 / 1024;
  String get cpuPercent => (cpuAbsolute).toStringAsFixed(1);
  String get uptimeFormatted {
    // If uptimeInMilliseconds is less that an hour, show minutes only
    // If uptimeInMilliseconds is less than a day, show hours and minutes
    // Otherwise, show days, hours, and minutes
    final totalSeconds = uptimeInMilliseconds ~/ 1000;
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
