// Model classes for the chat app

// conversations include multiple messages
class Conversation {
  final List<Message> messages;
  String title;
  String systemInfo;
  String imagePath = '';

  Conversation({required this.messages, required this.title, required this.systemInfo, this.imagePath = ''});

  Map<String, dynamic> toJson() => {
    'messages': messages.map((m) => m.toJson()).toList(),
    'title': title,
    'systemInfo': systemInfo.isEmpty ? '' : systemInfo,
    'imagePath': imagePath.isEmpty ? '' : imagePath, // 处理为空的情况
  };

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      messages: (json['messages'] as List).map((m) => Message.fromJson(m)).toList(),
      title: json['title'],
      systemInfo: json['systemInfo'] ?? '',
      imagePath: json['imagePath'] ?? '', // 提供默认值为空字符串
    );
  }

  // 新增方法：提取systemInfo中前两个逗号之间的字符串
   List<String> extractFirstTwoCommaSeparatedValues() {
     // 检查逗号数量
     int commaCount = systemInfo.contains('\n') ? systemInfo.split('\n').length - 1 : 0;
     // 如果逗号数量少于2，则返回默认配置
     if (commaCount < 2) {
       return ["主人", "小灵"];
     }
     // 否则，提取前两个逗号之间的字符串
     List<String> parts = systemInfo.split('\n'); // 分割成最多三部分
     return [parts[0], parts[1]]; // 返回前两个部分
   }
}

// Sender should have name and avatar
class Sender {
  final String name;
  final String avatarAssetPath;
  // id
  final String id;

  Sender({required this.name, required this.avatarAssetPath, String? id})
      : id = id ?? name;
}

// message should have role, content, timestamp
class Message {
  final String content;
  final DateTime timestamp;
  // sender id
  final String senderId;

  Message({required this.content, required this.senderId, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'content': content,
    'timestamp': timestamp.toIso8601String()
  };

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      senderId: json['senderId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp'])
    );
  }
}
