import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'chatpage.dart';
import 'drawer.dart';
import 'conversation_provider.dart';
import 'popmenu.dart';


class NewSystemProxy {

  static const MethodChannel _channel = MethodChannel('system_proxy');

  static Future<Map<String, String>?> getProxySettings() async {
    var proxy = {
      "host": "",
      "port": ""
    };
    if (Platform.isAndroid) {
      String proxyStr = await _channel.invokeMethod('getProxySettings');
      print("hi $proxyStr");
      if (proxyStr != "") {
        List<String> args = proxyStr.split(":");
        proxy['host'] = args[0];
        proxy['port'] = args[1];
      }
    }
    else if (Platform.isWindows) {
      String proxyStr = await _channel.invokeMethod('getProxySettings');
      if (proxyStr != ""){
        List<String> args = proxyStr.split(":");
        proxy['host'] = args[0];
        proxy['port'] = args[1];
      }
    }
    return proxy;
  }
}


class ProxiedHttpOverrides extends HttpOverrides {
  String _port;
  String _host;
  ProxiedHttpOverrides(this._host, this._port);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
    // set proxy
      ..findProxy = (uri) {
        if (_host != "" && _port != "") {
          return _host != null ? "PROXY $_host:$_port;" : 'DIRECT';
        } else {
          return "DIRECT";
        }
      };
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  dynamic proxy = await NewSystemProxy.getProxySettings();
  HttpOverrides.global = ProxiedHttpOverrides(proxy['host']!, proxy['port']!);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ConversationProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  // create theme
  final ThemeData theme = ThemeData(
    primarySwatch: Colors.grey,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Chat App',
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            Provider.of<ConversationProvider>(context, listen: true).currentConversationTitle,
            style: const TextStyle(
              fontSize: 20.0, // change font size
              color: Colors.black, // change font color
              fontFamily: 'din-regular', // change font family
            ),
          ),
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          backgroundColor: Colors.grey[100],
          elevation: 0, // remove box shadow
          toolbarHeight: 50,
          actions: [
            CustomPopupMenu(),
          ],
        ),
        drawer: MyDrawer(),
        body: const Center(
          child: ChatPage(),
        ),
      ),
    );
  }
}
