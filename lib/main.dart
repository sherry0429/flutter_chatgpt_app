import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:system_proxy/system_proxy.dart';

import 'chatpage.dart';
import 'drawer.dart';
import 'conversation_provider.dart';
import 'popmenu.dart';


class NewSystemProxy extends SystemProxy {

  static const MethodChannel _channel = MethodChannel('system_proxy');

  static Future<Map<String, String>?> getProxySettings() async {
    if (Platform.isAndroid) {

      dynamic proxySettingRes = await _channel.invokeMethod('getProxySettings');
      if (proxySettingRes != null) {
        Map<String, dynamic> proxySetting = Map<String, dynamic>.from(proxySettingRes);
        return {
          "port": proxySetting['port'].toString(),
          "host": proxySetting['host'].toString(),
        };
      }
    }
    else if (Platform.isIOS) {
      // 有代理时
      // {FTPPassive: 1, HTTPEnable: 1, HTTPPort: 8899, HTTPSProxy: 127.0.0.1, HTTPSPort: 8899, __SCOPED__: {en0: {HTTPEnable: 1, HTTPPort: 8899, HTTPSProxy: 127.0.0.1, HTTPSPort: 8899, FTPPassive: 1, HTTPProxy: 127.0.0.1, SOCKSEnable: 0, HTTPSEnable: 1}}, HTTPProxy: 127.0.0.1, HTTPSEnable: 1, SOCKSEnable: 0}
      // 无代理时
      // {FTPPassive: 1, HTTPEnable: 0, __SCOPED__: {en0: {HTTPEnable: 0, FTPPassive: 1, SOCKSEnable: 0, HTTPSEnable: 0}}, HTTPSEnable: 0, SOCKSEnable: 0}
      dynamic proxySettingRes = await _channel.invokeMethod('getProxySettings');
      Map<String, dynamic> proxySetting = Map<String, dynamic>.from(proxySettingRes);
      if (proxySetting['HTTPEnable'] == 1) {
        return {
          "port": proxySetting['HTTPPort'].toString(),
          "host": proxySetting['HTTPProxy'].toString(),
        };
      }
    }
    else if (Platform.isWindows) {
      String proxyStr = await _channel.invokeMethod('getProxySettings');
      if (proxyStr != ""){
        List<String> args = proxyStr.split(":");
        return {
          "host": args[0],
          "port": args[1],
        };
      }
      return null;
      // Map<String, dynamic> proxySetting = Map<String, dynamic>.from(proxySettingRes);
      // print(proxySetting);
    }
    return null;
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
          return "";
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
