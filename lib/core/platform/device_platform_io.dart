import 'dart:io';

/// VM/mobile: real platform.
String get deviceType => Platform.isIOS ? 'ios' : 'android';
