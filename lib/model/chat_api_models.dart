class ConversationOpenResponse {
  final bool status;
  final int conversationId;
  final bool existing;

  ConversationOpenResponse({
    required this.status,
    required this.conversationId,
    required this.existing,
  });

  factory ConversationOpenResponse.fromJson(Map<String, dynamic> json) {
    return ConversationOpenResponse(
      status: (json['status'] as bool?) ?? false,
      conversationId: (json['conversation_id'] as num?)?.toInt() ?? 0,
      existing: (json['existing'] as bool?) ?? false,
    );
  }
}

class ApiChatMessage {
  final int id;
  final int senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String? message;
  final String createdAt; // server formatted string
  final bool read;
  final String? attachment; // server path or null
  final bool policyViolation;
  final bool hidden;
  final List<String> piiTypes;

  ApiChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.message,
    required this.createdAt,
    required this.read,
    required this.attachment,
    required this.policyViolation,
    required this.hidden,
    required this.piiTypes,
  });

  factory ApiChatMessage.fromJson(Map<String, dynamic> json) {
    return ApiChatMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      senderId: (json['sender_id'] as num?)?.toInt() ?? 0,
      senderName: (json['sender_name'] as String?) ?? '',
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      message: json['message'] as String?,
      createdAt: (json['created_at'] as String?) ?? '',
      read: (json['read'] as bool?) ?? false,
      attachment: json['attachment'] as String?,
      policyViolation: (json['policy_violation'] as bool?) ?? false,
      hidden: (json['hidden'] as bool?) ?? false,
      piiTypes: (json['pii_types'] is List)
          ? List<String>.from((json['pii_types'] as List).map((e) => e.toString()))
          : const <String>[],
    );
  }
}

class ApiSendResponse {
  final bool status;
  final int id;
  final bool flagged;
  final List<String> piiTypes;

  ApiSendResponse({
    required this.status,
    required this.id,
    required this.flagged,
    required this.piiTypes,
  });

  factory ApiSendResponse.fromJson(Map<String, dynamic> json) {
    return ApiSendResponse(
      status: (json['status'] as bool?) ?? false,
      id: (json['id'] as num?)?.toInt() ?? 0,
      flagged: (json['flagged'] as bool?) ?? false,
      piiTypes: (json['pii_types'] is List)
          ? List<String>.from((json['pii_types'] as List).map((e) => e.toString()))
          : const <String>[],
    );
  }
}

class ChatConversationUser {
  final int id;
  final String name;
  final String? avatarUrl;

  ChatConversationUser({required this.id, required this.name, this.avatarUrl});

  factory ChatConversationUser.fromJson(Map<String, dynamic> json) {
    return ChatConversationUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class ChatConversationLastMessage {
  final int id;
  final String preview;
  final String createdAt;
  final bool read;

  ChatConversationLastMessage({
    required this.id,
    required this.preview,
    required this.createdAt,
    required this.read,
  });

  factory ChatConversationLastMessage.fromJson(Map<String, dynamic> json) {
    return ChatConversationLastMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      preview: (json['preview'] as String?) ?? '',
      createdAt: (json['created_at'] as String?) ?? '',
      read: (json['read'] as bool?) ?? false,
    );
  }
}

class ChatConversation {
  final int id;
  final String title;
  final ChatConversationUser? otherUser;
  final ChatConversationLastMessage? lastMessage;
  final int unreadCount;
  final String? conversationType;
  final String? lastSnippet; // fallback if no lastMessage
  final String? lastAt; // fallback timestamp
  final String? updatedAt;

  ChatConversation({
    required this.id,
    required this.title,
    this.otherUser,
    this.lastMessage,
    required this.unreadCount,
    this.conversationType,
    this.lastSnippet,
    this.lastAt,
    this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final hasLastMessage = json['last_message'] is Map<String, dynamic>;
    return ChatConversation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      otherUser: json['other_user'] is Map<String, dynamic>
          ? ChatConversationUser.fromJson(
              json['other_user'] as Map<String, dynamic>)
          : null,
      lastMessage: hasLastMessage
          ? ChatConversationLastMessage.fromJson(
              json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      conversationType: json['conversation_type'] as String?,
      lastSnippet: json['last_snippet'] as String?,
      lastAt: json['last_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  factory PaginationMeta.fromFlat({
    required int page,
    required int perPage,
    required int total,
  }) {
    // Derive lastPage from total/perPage
    final lp = perPage > 0 ? ((total + perPage - 1) ~/ perPage) : 1;
    return PaginationMeta(
      currentPage: page,
      lastPage: lp,
      perPage: perPage,
      total: total,
    );
  }
}

class ChatUserItem {
  final int id;
  final String displayName;
  final String? avatarUrl;
  final String? userType;

  ChatUserItem({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.userType,
  });

  factory ChatUserItem.fromJson(Map<String, dynamic> json) {
    return ChatUserItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      displayName: (json['display_name'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      userType: json['user_type'] as String?,
    );
  }
}

