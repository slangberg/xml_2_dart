import 'package:flutter/material.dart';

class ColorsResolver {
  const ColorsResolver();

  /// Resolve predefined colors like `Colors.blue`.
  dynamic resolve(String colorName) {
    const colorMap = {
      'blue': Colors.blue,
      'red': Colors.red,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'white': Colors.white,
      'black': Colors.black,
    };

    return colorMap[colorName] ??
        (throw Exception('Unknown color: $colorName'));
  }

  /// Resolve methods like `Color.fromARGB(...)` or `Color.fromRGBO(...)`.
  dynamic resolveMethod(String methodName) {
    const methodMap = {
      'fromARGB': Color.fromARGB,
      'fromRGBO': Color.fromRGBO,
    };

    return methodMap[methodName] ??
        (throw Exception('Unsupported color method: $methodName'));
  }

  /// Handle dynamic method calls with arguments
  dynamic resolveWithArgs(String methodName, List<dynamic> args) {
    final method = resolveMethod(methodName);
    if (method is Function) {
      return Function.apply(method, args);
    }
    throw Exception('Invalid method: $methodName');
  }
}
