import 'package:flutter/material.dart';
import 'models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ConversationProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];
  int _currentConversationIndex = 0;
  String apikey = "";
  String groupId = "";

  List<Conversation> get conversations => _conversations;
  int get currentConversationIndex => _currentConversationIndex;
  String get currentConversationTitle =>
      _conversations[_currentConversationIndex].title;
  int get currentConversationLength =>
      _conversations[_currentConversationIndex].messages.length;
  String get yourapikey => apikey;
  String get yourgroupid => groupId;
  Conversation get currentConversation =>
      _conversations[_currentConversationIndex];
  // get current conversation's messages format
  //'messages': [
  //   {'role': 'user', 'content': text},
  // ],
  List<Map<String, String>> get currentConversationMessages {
    List<Map<String, String>> messages = [];
    final nameAndMaster = _conversations[_currentConversationIndex]
        .extractFirstTwoCommaSeparatedValues();
    var conversationMessages =
        _conversations[_currentConversationIndex].messages;

    // If there are more than 100 messages, take only the last 100
    if (conversationMessages.length > 100) {
      conversationMessages =
          conversationMessages.sublist(conversationMessages.length - 100);
    }

    for (Message message in conversationMessages) {
      messages.add({
        'sender_type': message.senderId == 'User' ? 'USER' : 'BOT',
        'sender_name':
            message.senderId == 'User' ? nameAndMaster[0] : nameAndMaster[1],
        'text': message.content
      });
    }
    return messages;
  }

  Future<void> deleteConversationAudioFiles(String title) async {
    final directory = await getApplicationDocumentsDirectory();
    final sanitizedTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final path = '${directory.path}/$sanitizedTitle';

    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> renameConversationAudioFolder(
      String oldTitle, String newTitle) async {
    final directory = await getApplicationDocumentsDirectory();
    final sanitizedOldTitle = oldTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final sanitizedNewTitle = newTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final oldPath = '${directory.path}/$sanitizedOldTitle';
    final newPath = '${directory.path}/$sanitizedNewTitle';

    final dir = Directory(oldPath);
    if (await dir.exists()) {
      await dir.rename(newPath);
    }
  }

  // 保存数据
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // 保存 API 密钥和组 ID
    await prefs.setString('apikey', apikey);
    await prefs.setString('groupId', groupId);

    // 将对话列表转换为 JSON 并保存
    List<String> conversationsJson =
        _conversations.map((conv) => jsonEncode(conv.toJson())).toList();
    await prefs.setStringList('conversations', conversationsJson);

    // 保存当前对话索引
    await prefs.setInt('currentConversationIndex', _currentConversationIndex);
  }

  // 加载数据
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载 API 密钥和组 ID
    apikey = prefs.getString('apikey') ?? "";
    groupId = prefs.getString('groupId') ?? "";

    // 加载对话列表
    List<String>? conversationsJson = prefs.getStringList('conversations');
    if (conversationsJson != null) {
      _conversations = conversationsJson
          .map((json) => Conversation.fromJson(jsonDecode(json)))
          .toList();
    } else {
      _conversations.add(Conversation(
          messages: [], title: 'new conversation', systemInfo: ''));
    }

    // 加载当前对话索引
    _currentConversationIndex = prefs.getInt('currentConversationIndex') ?? 0;

    notifyListeners();
  }

  // 在数据变化时调用此方法
  void _saveDataAndNotify() {
    saveData();
    notifyListeners();
  }

  // initialize provider conversation list
  ConversationProvider() {
    loadData();
  }

  // change conversations
  set conversations(List<Conversation> value) {
    _conversations = value;
    _saveDataAndNotify();
    notifyListeners();
  }

  // change current conversation
  set currentConversationIndex(int value) {
    _currentConversationIndex = value;
    _saveDataAndNotify();
    notifyListeners();
  }

  // change api key
  set yourapikey(String value) {
    apikey = value;
    _saveDataAndNotify();
    notifyListeners();
  }

  set yourgroupid(String value) {
    groupId = value;
    _saveDataAndNotify();
    notifyListeners();
  }

  // add to current conversation
  void addMessage(Message message) {
    _conversations[_currentConversationIndex].messages.add(message);
    _saveDataAndNotify();
    notifyListeners();
  }

  void delLastMessage() {
    if (_conversations.isNotEmpty &&
        _conversations[_currentConversationIndex].messages.isNotEmpty) {
      _conversations[_currentConversationIndex].messages.removeLast();
      _saveDataAndNotify();
      notifyListeners();
    }
  }

  void updateMessage(int index, Message updatedMessage) {
    _conversations[_currentConversationIndex].messages[index] = updatedMessage;
    notifyListeners();
  }

  // add a new empty conversation
  // default title is 'new conversation ${_conversations.length}'
  void addEmptyConversation(String title, String systemInfo) {
    if (title == '') {
      title = 'new conversation ${_conversations.length}';
    }
    _conversations
        .add(Conversation(messages: [], title: title, systemInfo: systemInfo));
    _currentConversationIndex = _conversations.length - 1;
    _saveDataAndNotify();
    notifyListeners();
  }

  // add new conversation
  void addConversation(Conversation conversation) {
    _conversations.add(conversation);
    _currentConversationIndex = _conversations.length - 1;
    _saveDataAndNotify();
    notifyListeners();
  }

  // remove conversation by index
  Future<void> removeConversation(int index) async {
    _conversations.removeAt(index);
    _currentConversationIndex = _conversations.length - 1;
    _saveDataAndNotify();
    notifyListeners();
  }

  // remove current conversation
  Future<void> removeCurrentConversation() async {
    _conversations.removeAt(_currentConversationIndex);
    _currentConversationIndex = _conversations.length - 1;
    if (_conversations.isEmpty) {
      addEmptyConversation('', '');
    }
    await deleteConversationAudioFiles(currentConversation.title);
    _saveDataAndNotify();
    notifyListeners();
  }

  //rename conversation
  Future<void> renameConversation(String title) async {
    if (title == "") {
      // no title, use default title
      title = 'new conversation ${_currentConversationIndex}';
    }
    final oldTitle = currentConversation.title;
    await renameConversationAudioFolder(oldTitle, title);
    _conversations[_currentConversationIndex].title = title;
    _saveDataAndNotify();
    notifyListeners();
  }

  // set background
  void setBackgroundImage(String imagePath) {
    if (imagePath == "") {
      imagePath = '';
    }
    _conversations[_currentConversationIndex].imagePath = imagePath;
    _saveDataAndNotify();
    notifyListeners();
  }

  // update systeminfo
  void updateSystemInfo(String systeminfo) {
    if (systeminfo == "") {
      systeminfo = '';
    }
    _conversations[_currentConversationIndex].systemInfo = systeminfo;
    _saveDataAndNotify();
    notifyListeners();
  }

  // clear all conversations
  void clearConversations() {
    _conversations.clear();
    addEmptyConversation('', '');
    _saveDataAndNotify();
    notifyListeners();
  }

  // clear current conversation
  Future<void> clearCurrentConversation() async {
    await deleteConversationAudioFiles(currentConversation.title);
    _conversations[_currentConversationIndex].messages.clear();
    _saveDataAndNotify();
    notifyListeners();
  }
}

const String model = "gpt-3.5-turbo";

final Sender systemSender = Sender(
    name: 'System', avatarAssetPath: 'resources/avatars/ChatGPT_logo.png');
final Sender userSender =
    Sender(name: 'User', avatarAssetPath: 'resources/avatars/person.png');
