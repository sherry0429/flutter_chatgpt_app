import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'conversation_provider.dart';
import 'models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';


class CustomPopupMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
        const PopupMenuItem(
          value: "rename",
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rename'),
          ),
        ),
        const PopupMenuItem(
          value: "refresh",
          child: ListTile(
            leading: Icon(Icons.refresh),
            title: Text('Refresh'),
          ),
        ),
        const PopupMenuItem(
          value: "delete",
          child: ListTile(
            leading: Icon(Icons.delete),
            title: Text('Delete'),
          ),
        ),
        const PopupMenuItem(
          value: "set_background",
          child: ListTile(
            leading: Icon(Icons.image),
            title: Text('Set Background'),
          ),
        ),
        const PopupMenuItem(
          value: "edit_systeminfo",
          child: ListTile(
            leading: Icon(Icons.edit_note),
            title: Text('Edit System Info'),
          ),
        ),
      ],
      
      elevation: 2,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onSelected: (value) async {
        if (value == "rename") {
          await _renameConversation(context);
        } else if (value == "delete") {
          // delete
          await Provider.of<ConversationProvider>(context, listen: false)
              .removeCurrentConversation();
        } else if (value == "refresh") {
          // refresh
          await Provider.of<ConversationProvider>(context, listen: false)
              .clearCurrentConversation();
        } else if (value == "set_background") {
          _setBackground(context);
        } else if (value == "edit_systeminfo") {
          _editSystemInfo(context);
        }
      },
    );
  }


  Future<void> _renameConversation(BuildContext context) async {
    String newName = '';
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Conversation'),
          content: TextField(
            decoration: InputDecoration(
              hintText: Provider.of<ConversationProvider>(context, listen: false)
                  .currentConversation
                  .title,
            ),
            onChanged: (value) {
              newName = value;
            },
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
                'Rename',
                style: TextStyle(
                  color: Color(0xff55bb8e),
                ),
              ),
              onPressed: () async {
                await Provider.of<ConversationProvider>(context, listen: false)
                    .renameConversation(newName);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _setBackground(BuildContext context) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        Provider.of<ConversationProvider>(context, listen: false)
            .setBackgroundImage(image.path);
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        Provider.of<ConversationProvider>(context, listen: false)
            .setBackgroundImage(result.files.single.path!);
      }
    }
  }

  void _editSystemInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newSystemInfo = Provider.of<ConversationProvider>(context, listen: false)
            .currentConversation
            .systemInfo;
        return AlertDialog(
          title: const Text('Edit System Info'),
          content: TextField(
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: 'Enter new system info',
            ),
            controller: TextEditingController(text: newSystemInfo),
            onChanged: (value) {
              newSystemInfo = value;
            },
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
                Provider.of<ConversationProvider>(context, listen: false)
                    .updateSystemInfo(newSystemInfo);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}


