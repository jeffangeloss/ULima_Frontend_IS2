// lib/models/alert_model.dart
// Modelo de alerta de riesgo académico o alta carga.

class AlertModel {
  final int id;
  final int studentId;
  final String type; // academic_risk | high_load
  final String title;
  final String message;
  bool isRead;
  final DateTime createdAt;
  final String? courseName;
  final String? sectionCode;

  AlertModel({
    required this.id,
    required this.studentId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.courseName,
    this.sectionCode,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as int? ?? 0,
      studentId: json['studentId'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      courseName: json['courseName'] as String?,
      sectionCode: json['sectionCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'type': type,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'courseName': courseName,
      'sectionCode': sectionCode,
    };
  }
}
