class PendingUploadRecord {
  final String id;
  final String driverId;
  final String jobId;
  final String eventType;
  final List<String> imagePaths;
  final List<String> videoPaths;
  final String? signatureImagePath;

  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PendingUploadRecord({
    required this.id,
    required this.driverId,
    required this.jobId,
    required this.eventType,
    required this.imagePaths,
    required this.videoPaths,
    required this.signatureImagePath,
    required this.attempts,
    required this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  PendingUploadRecord copyWith({
    List<String>? imagePaths,
    List<String>? videoPaths,
    String? signatureImagePath,
    int? attempts,
    String? lastError,
    DateTime? updatedAt,
  }) {
    return PendingUploadRecord(
      id: id,
      driverId: driverId,
      jobId: jobId,
      eventType: eventType,
      imagePaths: imagePaths ?? this.imagePaths,
      videoPaths: videoPaths ?? this.videoPaths,
      signatureImagePath: signatureImagePath ?? this.signatureImagePath,
      attempts: attempts ?? this.attempts,
      lastError: lastError,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'driverId': driverId,
    'jobId': jobId,
    'eventType': eventType,
    'imagePaths': imagePaths,
    'videoPaths': videoPaths,
    'signatureImagePath': signatureImagePath,
    'attempts': attempts,
    'lastError': lastError,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PendingUploadRecord.fromJson(Map<String, dynamic> json) {
    return PendingUploadRecord(
      id: json['id']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      imagePaths: (json['imagePaths'] as List?)?.cast<String>() ?? const [],
      videoPaths: (json['videoPaths'] as List?)?.cast<String>() ?? const [],
      signatureImagePath: json['signatureImagePath']?.toString(),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      lastError: json['lastError']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
