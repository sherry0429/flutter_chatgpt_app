import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'conversation_provider.dart';


void showRenameDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newName = 'YOUR_API_KEY';
        String newGroupId = 'YOUR_GROUP_ID';
        return AlertDialog(
          title: const Text('API Setting'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                // display the current name of the conversation
                decoration: InputDecoration(
                  hintText: Provider.of<ConversationProvider>(context).yourapikey ?? 'Enter API Key',
                ),
                onChanged: (value) {
                  newName = value;
                },
              ),
              TextField(
                // 新增的输入字段用于输入groupId
                decoration: InputDecoration(
                  hintText: Provider.of<ConversationProvider>(context).yourgroupid ?? 'Enter Group ID',
                ),
                onChanged: (value) {
                  newGroupId = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xff55bb8e),
                ),
              ),
              onPressed: () {
                if (newName == '' || newGroupId == '') {
                  Navigator.pop(context);
                  return;
                }
                Provider.of<ConversationProvider>(context, listen: false).yourapikey = newName;
                Provider.of<ConversationProvider>(context, listen: false).yourgroupid = newGroupId;
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }