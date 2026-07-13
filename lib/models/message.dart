class ChatMessage {
  static const networkingBodyPrefix = '__ULIMA_NETWORKING_CARD__:';

  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String senderRoleLabel;
  final bool isModerator;
  final int weight;
  final String body;
  final DateTime createdAt;
  final String messageType;
  final int? networkingOwnerId;

  // HU23: borrado suave por el profesor. Cuando `deleted` es true, el mensaje se
  // muestra como lápida "eliminado por <deletedBy>".
  final bool deleted;
  final String? deletedBy;
  final String? deletedByRole;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.senderRoleLabel,
    required this.isModerator,
    required this.weight,
    required this.body,
    required this.createdAt,
    this.messageType = 'text',
    this.networkingOwnerId,
    this.deleted = false,
    this.deletedBy,
    this.deletedByRole,
  });

  String get text => body;
  DateTime get timestamp => createdAt;
  bool get isNetworkingCard => messageType == 'networking_card';

  factory ChatMessage.fromMap(String id, Map<dynamic, dynamic> map) {
    final role = (map['senderRole'] ?? map['role'] ?? 'student').toString();
    final createdAt = _parseDateTime(map['createdAt'] ?? map['timestamp']);
    final body = (map['body'] ?? map['text'] ?? '').toString();
    final networkingOwnerFromBody = _parseNetworkingOwnerId(body);
    final rawMessageType = (map['messageType'] ?? map['type'])?.toString();

    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: (map['senderName'] ?? map['displayName'] ?? 'Participante')
          .toString(),
      senderRole: role,
      senderRoleLabel:
          (map['senderRoleLabel'] ?? map['roleLabel'] ?? _labelFor(role))
              .toString(),
      isModerator: map['moderator'] == true || _isModeratorRole(role),
      weight: _parseInt(map['weight']) ?? _weightFor(role),
      body: body,
      createdAt: createdAt,
      messageType:
          rawMessageType ??
          (networkingOwnerFromBody == null ? 'text' : 'networking_card'),
      networkingOwnerId:
          _parseInt(map['networkingOwnerId']) ?? networkingOwnerFromBody,
      deleted: map['deleted'] == true,
      deletedBy: map['deletedBy']?.toString(),
      deletedByRole: map['deletedByRole']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'senderRoleLabel': senderRoleLabel,
      'moderator': isModerator,
      'weight': weight,
      'body': body,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'messageType': messageType,
      if (networkingOwnerId != null) 'networkingOwnerId': networkingOwnerId,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static int? _parseNetworkingOwnerId(String body) {
    if (!body.startsWith(networkingBodyPrefix)) return null;
    return int.tryParse(body.substring(networkingBodyPrefix.length).trim());
  }

  static bool _isModeratorRole(String role) =>
      role == 'teacher' ||
      role == 'jp' ||
      role == 'delegate' ||
      role == 'subdelegate';

  static int _weightFor(String role) {
    switch (role) {
      case 'teacher':
        return 100;
      case 'jp':
        return 90;
      case 'delegate':
        return 70;
      case 'subdelegate':
        return 60;
      default:
        return 10;
    }
  }

  static String _labelFor(String role) {
    switch (role) {
      case 'teacher':
        return 'Profesor';
      case 'jp':
        return 'Jefe de Práctica';
      case 'delegate':
        return 'Delegado';
      case 'subdelegate':
        return 'Subdelegado';
      default:
        return 'Alumno';
    }
  }
}
