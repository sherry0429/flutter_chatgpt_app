import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'models.dart';
import 'conversation_provider.dart';
import 'secrets.dart';


class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const MethodChannel _channel = MethodChannel('system_proxy');
  HttpClient _client = HttpClient();
  FocusNode _focusNode = FocusNode();
  final AudioPlayer player = AudioPlayer();

  @override
  void dispose() {
    _client.close();
    player.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  List<int> hexStringToBytes(String hex) {
    final length = hex.length;
    List<int> bytes = List<int>.filled(length ~/ 2, 0);

    for (int i = 0; i < length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }

    return bytes;
  }

  void _playSound(Message message) async {
    final apiKey = Provider.of<ConversationProvider>(context, listen: false).yourapikey;
    final groupId = Provider.of<ConversationProvider>(context, listen: false).yourgroupid;
    final url = Uri.parse('https://api.minimax.chat/v1/t2a_v2?GroupId=' + groupId);
    final converter = JsonUtf8Encoder();

    final payload = {
      "model": "speech-01-240228",
      "text": message.content,
      "stream": false,
      "voice_setting": {
        "voice_id": "wumei_yujie",
        "speed": 1,
        "vol": 1,
        "pitch": 0
      },
      "pronunciation_dict": {},
      "audio_setting": {
        "sample_rate": 32000,
        "bitrate": 128000,
        "format": "mp3",
        "channel": 1
      }
    };
    try {
      return await _client.postUrl(url).then(
              (HttpClientRequest request) {
            request.headers.set('Content-Type', 'application/json');
            request.headers.set('Authorization', 'Bearer $apiKey');
            request.add(converter.convert(payload));
            return request.close();
          }
      ).then((HttpClientResponse response) async {
        var retBody = await response.transform(utf8.decoder).join();
        if (response.statusCode == 200) {
          final data = json.decode(retBody);
          final audioData = data['data']['audio'];
          List<int> audioBytes = hexStringToBytes(audioData);
          final file = File('F://AndroidProject/ChatGpt/output.mp3');
          await file.writeAsBytes(audioBytes);
          await player.play('F://AndroidProject/ChatGpt/output.mp3');
        } else {
          print('audio request error');
        }
      });
    } on Exception catch (_) {
      print('audio generate failed' + _.toString());
    }
  }

  Future<Message?> _sendMessage(List<Map<String, String>> messages) async {
    final apiKey = Provider.of<ConversationProvider>(context, listen: false).yourapikey;
    final groupId = Provider.of<ConversationProvider>(context, listen: false).yourgroupid;
    final url = Uri.parse('https://api.minimax.chat/v1/text/chatcompletion_pro?GroupId=' + groupId);
    final converter = JsonUtf8Encoder();

    final body = {
      "model": "abab5.5s-chat",
      "tokens_to_generate": 1024,
      "reply_constraints": {"sender_type":"BOT", "sender_name": "小妖"},
      "messages":messages,
      "bot_setting":[
        {
          "bot_name": "小妖",
          "content": "小妖"
        }
      ],
      "mask_sensitive_info": false,
    };

    try {
      return await _client.postUrl(url).then(
              (HttpClientRequest request) {
            request.headers.set('Content-Type', 'application/json');
            request.headers.set('Authorization', 'Bearer $apiKey');
            request.add(converter.convert(body));
            return request.close();
          }
      ).then((HttpClientResponse response) async {
        var retBody = await response.transform(utf8.decoder).join();
        if (response.statusCode == 200) {
          final data = json.decode(retBody);
          final completions = data['choices'] as List<dynamic>;
          if (completions.isNotEmpty) {
            final completion = completions[0];
            final content = completion['messages'][0]['text'] as String;
            // delete all the prefix '\n' in content
            final contentWithoutPrefix = content.replaceFirst(
                RegExp(r'^\n+'), '');
            return Message(
                senderId: systemSender.id, content: contentWithoutPrefix);
          }
        } else {
          // invalid api key
          // create a new dialog
          return Message(content: "API KEY is Invalid", senderId: systemSender.id);
        }
      });
    } on Exception catch (_) {
      return Message(content: _.toString(), senderId: systemSender.id);
    }
  }

  //scroll to last message
  void _scrollToLastMessage() {
    final double height = _scrollController.position.maxScrollExtent;
    final double lastMessageHeight =
        _scrollController.position.viewportDimension;
    _scrollController.animateTo(
      height,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  void _addToChat() async {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _textController.clear();
      final userMessage = Message(senderId: userSender.id, content: text);
      setState(() {
        // add to current conversation
        Provider.of<ConversationProvider>(context, listen: false)
            .addMessage(userMessage);
      });
    }
  }

  void _sendMessageNow() async {
    final assistantMessage = await _sendMessage(
        Provider.of<ConversationProvider>(context, listen: false)
            .currentConversationMessages);
    if (assistantMessage != null) {
      setState(() {
        Provider.of<ConversationProvider>(context, listen: false)
            .addMessage(assistantMessage);
      });
    }
  }

  void _sendMessageAndAddToChat() async {
      _addToChat();
      _sendMessageNow();
      _scrollToLastMessage();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return 
    GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      onVerticalDragDown: (_) => FocusScope.of(context).unfocus(),
      child: Scaffold(
      // resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: Consumer<ConversationProvider>(
              builder: (context, conversationProvider, child) {
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: conversationProvider.currentConversationLength,
                  itemBuilder: (BuildContext context, int index) {
                    Message message = conversationProvider
                        .currentConversation.messages[index];
                    return LongPressMenu(
                        message: message,
                        onPlaySound: () async {
                          _playSound(message);
                        },
                        onRegenerate: () async {
                          setState(() {
                            // add to current conversation
                            Provider.of<ConversationProvider>(context, listen: false)
                                .delLastMessage();
                          });
                          _sendMessageNow();
                        },
                        onRetract: () async {
                          setState(() {
                            // add to current conversation
                            Provider.of<ConversationProvider>(context, listen: false)
                                .delLastMessage();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message.senderId != userSender.id)
                                CircleAvatar(
                                  backgroundImage:
                                  AssetImage(systemSender.avatarAssetPath),
                                  radius: 16.0,
                                )
                              else
                                const SizedBox(width: 24.0),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Align(
                                  alignment: message.senderId == userSender.id
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    decoration: BoxDecoration(
                                      color: message.senderId == userSender.id
                                          ? Color(0xff55bb8e)
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      message.content,
                                      style: TextStyle(
                                        color: message.senderId == userSender.id
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              if (message.senderId == userSender.id)
                                CircleAvatar(
                                  backgroundImage:
                                  AssetImage(userSender.avatarAssetPath),
                                  radius: 16.0,
                                )
                              else
                                const SizedBox(width: 24.0),
                            ],
                          ),
                        ));
                  },
                );
              },
            ),
          ),

          // input box
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(32.0),
            ),
            margin:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration.collapsed(
                        hintText: 'Type your message...'),
                    onSubmitted: (String value) {
                        _sendMessageAndAddToChat();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: 
                  // listen to apikey to see if changed
                  Provider.of<ConversationProvider>(context, listen: true)
                          .yourapikey == "YOUR_API_KEY"
                      ? () {
                        showRenameDialog(context);
                      }
                      : () {
                          _sendMessageAndAddToChat();
                        },

                  
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
    
    
  }


}


// 定义 LongPressMenu 组件
class LongPressMenu extends StatefulWidget {
  final Message message;
  final VoidCallback onPlaySound;
  final VoidCallback onRegenerate;
  final VoidCallback onRetract;
  final Widget child;

  const LongPressMenu({
    Key? key,
    required this.message,
    required this.onPlaySound,
    required this.onRegenerate,
    required this.onRetract,
    required this.child,
  }) : super(key: key);

  @override
  _LongPressMenuState createState() => _LongPressMenuState();
}

class _LongPressMenuState extends State<LongPressMenu> {

  Future<void> _showOptionsMenu() async {

  // 获取父控件的位置信息
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    // 计算弹出菜单的位置，这里我们将其放在父控件的下方
    final RelativeRect position = RelativeRect.fromLTRB(
        offset.dx, // X轴偏移
        offset.dy + size.height, // Y轴偏移，放在控件下方
        offset.dx, // X轴偏移，与父控件左边界对齐
        offset.dy + size.height + 10.0, // Y轴偏移，下方10像素
    );

    String? selected = await showMenu(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
          value: 'playSound',
          child: Text('Play Sound'),
        ),
        const PopupMenuItem(
          value: 'regenerate',
          child: Text('Regenerate'),
        ),
        const PopupMenuItem(
          value: 'retract',
          child: Text('Retract'),
        ),
      ],
    );
    switch (selected) {
      case 'playSound':
        widget.onPlaySound();
        break;
      case 'regenerate':
        widget.onRegenerate();
        break;
      case 'retract':
        widget.onRetract();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        // 显示菜单
        _showOptionsMenu();
      },
      child: widget.child,
    );
  }
}