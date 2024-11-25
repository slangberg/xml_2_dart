import 'package:flutter/material.dart';

class ColorParser {
  /// Parses a color expression such as `Colors.blue`, `Colors.blue.withOpacity(0.5)`,
  /// `Color.fromRGBO(255, 0, 0, 1.0)`, or `Color.fromARGB(255, 255, 0, 0)`.
  static Color parseColor(String expression) {
    try {
      if (expression.startsWith('Colors.')) {
        return _parseColorsExpression(expression);
      }

      if (expression.startsWith('Color.fromRGBO(')) {
        return _parseFromRGBO(expression);
      }

      if (expression.startsWith('Color.fromARGB(')) {
        return _parseFromARGB(expression);
      }

      throw Exception('Unsupported color expression: $expression');
    } catch (e) {
      throw Exception('Error parsing color expression: $expression. Error: $e');
    }
  }

  /// Parses expressions like `Colors.blue` or `Colors.blue.withOpacity(0.5)`.
  static Color _parseColorsExpression(String expression) {
    final parts = expression.split('.');
    final baseColor = _getColorFromName(parts[1]);

    // If no method is applied, return the base color
    if (parts.length == 2) {
      return baseColor;
    }

    // Handle method calls like `withOpacity()`
    if (parts[2].contains('(')) {
      final methodName = parts[2].split('(')[0];
      final args = _extractArguments(parts[2]);
      return Function.apply(baseColor.getClassMethod(methodName), args);
    }

    throw Exception('Unsupported Colors expression: $expression');
  }

  /// Resolves a MaterialColor or Color by name
  static Color _getColorFromName(String colorName) {
    try {
      final colorMap = {
        'red': Colors.red,
        'pink': Colors.pink,
        'purple': Colors.purple,
        'deepPurple': Colors.deepPurple,
        'indigo': Colors.indigo,
        'blue': Colors.blue,
        'lightBlue': Colors.lightBlue,
        'cyan': Colors.cyan,
        'teal': Colors.teal,
        'green': Colors.green,
        'lightGreen': Colors.lightGreen,
        'lime': Colors.lime,
        'yellow': Colors.yellow,
        'amber': Colors.amber,
        'orange': Colors.orange,
        'deepOrange': Colors.deepOrange,
        'brown': Colors.brown,
        'grey': Colors.grey,
        'blueGrey': Colors.blueGrey,
        'white': Colors.white,
        'black': Colors.black,
      };

      final resolvedColor = colorMap[colorName];
      if (resolvedColor == null) {
        throw Exception('Unknown MaterialColor or Color: $colorName');
      }
      return resolvedColor;
    } catch (e) {
      throw Exception('Error resolving MaterialColor: $colorName. Error: $e');
    }
  }

  /// Parses `Color.fromRGBO(r, g, b, a)` into a `Color`.
  static Color _parseFromRGBO(String expression) {
    try {
      final args = _extractArguments(expression);
      if (args.length != 4) {
        throw Exception('Invalid arguments for Color.fromRGBO: $expression');
      }

      return Color.fromRGBO(
        args[0].toInt(), // Red
        args[1].toInt(), // Green
        args[2].toInt(), // Blue
        args[3], // Opacity
      );
    } catch (e) {
      throw Exception('Error parsing Color.fromRGBO: $expression. Error: $e');
    }
  }

  /// Parses `Color.fromARGB(a, r, g, b)` into a `Color`.
  static Color _parseFromARGB(String expression) {
    try {
      final args = _extractArguments(expression);
      if (args.length != 4) {
        throw Exception('Invalid arguments for Color.fromARGB: $expression');
      }

      return Color.fromARGB(
        args[0].toInt(), // Alpha
        args[1].toInt(), // Red
        args[2].toInt(), // Green
        args[3].toInt(), // Blue
      );
    } catch (e) {
      throw Exception('Error parsing Color.fromARGB: $expression. Error: $e');
    }
  }

  /// Extracts arguments from a method call like `withOpacity(0.5)`
  static List<dynamic> _extractArguments(String methodCall) {
    final argsString = methodCall.split('(')[1].replaceFirst(')', '');
    return argsString
        .split(',')
        .map((e) => double.tryParse(e.trim()) ?? e.trim())
        .toList();
  }
}

/// Extension to resolve methods for MaterialColor or Color
extension MethodResolver on Color {
  /// Resolves the method from the Color object
  Function getClassMethod(String methodName) {
    final methods = {
      'withOpacity': this.withOpacity,
      'withAlpha': this.withAlpha,
    };

    if (methods.containsKey(methodName)) {
      return methods[methodName]!;
    } else {
      throw Exception('Method not supported: $methodName');
    }
  }
}
