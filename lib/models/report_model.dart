import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants/app_constants.dart';

class ReportLocation extends Equatable {
  final double lat;
  final double lng;
  final String? address;

  const ReportLocation({
    required this.lat,
    required this.lng,
    this.address,
  });

  LatLng toLatLng() => LatLng(lat, lng);

  factory ReportLocation.fromJson(Map<String, dynamic> json) => ReportLocation(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        address: json['address'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (address != null) 'address': address,
      };

  @override
  List<Object?> get props => [lat, lng, address];
}

class Report extends Equatable {
  final String id;
  final String type;
  final String material;
  final ReportLocation location;
  final String? photoUrl;
  final String status;
  final DateTime timestamp;
  final String reporterUserId;
  final String? description;
  final String? assignedRecyclerId;
  final String? aiSeverity;
  final String? aiRecommendation;

  const Report({
    required this.id,
    required this.type,
    required this.material,
    required this.location,
    this.photoUrl,
    required this.status,
    required this.timestamp,
    required this.reporterUserId,
    this.description,
    this.assignedRecyclerId,
    this.aiSeverity,
    this.aiRecommendation,
  });

  bool get isPending => status == ReportStatus.pending;
  bool get isOnTheWay => status == ReportStatus.onTheWay;
  bool get isCompleted => status == ReportStatus.completed;

  Report copyWith({
    String? id,
    String? type,
    String? material,
    ReportLocation? location,
    String? photoUrl,
    String? status,
    DateTime? timestamp,
    String? reporterUserId,
    String? description,
    String? assignedRecyclerId,
    String? aiSeverity,
    String? aiRecommendation,
  }) {
    return Report(
      id: id ?? this.id,
      type: type ?? this.type,
      material: material ?? this.material,
      location: location ?? this.location,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      reporterUserId: reporterUserId ?? this.reporterUserId,
      description: description ?? this.description,
      assignedRecyclerId: assignedRecyclerId ?? this.assignedRecyclerId,
      aiSeverity: aiSeverity ?? this.aiSeverity,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
    );
  }

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        type: json['type'] as String,
        material: json['material'] as String,
        location: ReportLocation.fromJson(json['location'] as Map<String, dynamic>),
        photoUrl: json['photoUrl'] as String?,
        status: json['status'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        reporterUserId: json['reporterUserId'] as String,
        description: json['description'] as String?,
        assignedRecyclerId: json['assignedRecyclerId'] as String?,
        aiSeverity: json['aiSeverity'] as String?,
        aiRecommendation: json['aiRecommendation'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'material': material,
        'location': location.toJson(),
        if (photoUrl != null) 'photoUrl': photoUrl,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'reporterUserId': reporterUserId,
        if (description != null) 'description': description,
        if (assignedRecyclerId != null) 'assignedRecyclerId': assignedRecyclerId,
        if (aiSeverity != null) 'aiSeverity': aiSeverity,
        if (aiRecommendation != null) 'aiRecommendation': aiRecommendation,
      };

  @override
  List<Object?> get props => [
        id,
        type,
        material,
        location,
        photoUrl,
        status,
        timestamp,
        reporterUserId,
        description,
        assignedRecyclerId,
        aiSeverity,
        aiRecommendation,
      ];
}
