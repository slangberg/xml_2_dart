import 'dart:convert';
import 'package:flutter/material.dart';

import 'expression_parser.dart';

class ExpressionEvaluator {
  final Map<String, dynamic> context;

  ExpressionEvaluator(this.context);

  dynamic evaluate(String expression) {
    print("ExpressionEvaluator.evaluate expression: $expression");
    final parser = ExpressionGrammarDefinition().build();
    final result = parser.parse(expression);

    if (result.isFailure) {
      throw Exception('Failed to parse expression: $expression');
    }

    return _resolveValues(result.value);
  }

  dynamic _resolveValues(dynamic value) {
    if (value is String && context.containsKey(value)) {
      return context[value];
    } else if (value is List) {
      return value.map(_resolveValues).toList();
    }
    return value;
  }
}

// Evaluates expressions for dynamic props like colors, JSON, or context mapping.
dynamic evaluateExpression(dynamic expression, Map<String, dynamic> context) {
  print("DynamicProps Evaluating expression: $expression");
  if (expression is! String) {
    return expression;
  }

  try {
    // Delegate to ExpressionEvaluator for inline logical/comparison operators
    if (expression.startsWith('{') && expression.endsWith('}')) {
      final evaluator = ExpressionEvaluator(context);
      final innerExpression = expression.substring(1, expression.length - 1);
      return evaluator.evaluate(innerExpression);
    }

    if (expression.startsWith('#')) {
      return _getColorFromHex(expression);
    }

    // Handle ARGB color codes
    if (expression.startsWith('Color.fromARGB(')) {
      return _parseColorFromARGB(expression);
    }

    // Handle Colors.<color>[.<method>]
    if (expression.startsWith('Colors.')) {
      final parts = expression.split('.');
      final baseColor = _getColorFromName(parts[1]);

      // If no method is applied, return the base color
      if (parts.length == 2) {
        return baseColor;
      }

      // Handle method calls like `withOpacity`
      if (parts[2].contains('(')) {
        final methodName = parts[2].split('(')[0];
        final args = _extractArguments(parts[2]);
        return Function.apply(baseColor.getClassMethod(methodName), args);
      }
    }

    // Handle JSON for complex props
    if (expression.startsWith('{{') &&
        expression.endsWith('}}') &&
        isJson(expression)) {
      return json.decode(expression);
    }

    // Default case
    return expression;
  } catch (e) {
    throw Exception('Error evaluating expression: $expression. Error: $e');
  }
}

/// Checks if a string is valid JSON
bool isJson(String input) {
  try {
    json.decode(input);
    return true;
  } catch (_) {
    return false;
  }
}

/// Converts a hex color string to a [Color]
Color _getColorFromHex(String hexColor) {
  final buffer = StringBuffer();
  if (hexColor.length == 7) buffer.write('ff');
  buffer.write(hexColor.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// Parses Color.fromARGB(r, g, b, a) to a [Color]
Color _parseColorFromARGB(String expression) {
  final args = expression
      .replaceFirst('Color.fromARGB(', '')
      .replaceFirst(')', '')
      .split(',')
      .map((e) => int.parse(e.trim()))
      .toList();

  if (args.length == 4) {
    return Color.fromARGB(args[0], args[1], args[2], args[3]);
  } else {
    throw Exception('Invalid ARGB color format: $expression');
  }
}

/// Dynamically resolves MaterialColor by name
Color _getColorFromName(String colorName) {
  try {
    // Use Dart's reflection-like capabilities for MaterialColor
    final materialColors = {
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
      'black': Colors.black,
      'white': Colors.white,
    };

    final resolvedColor = materialColors[colorName];
    if (resolvedColor == null) {
      throw Exception('Unknown MaterialColor or Color: $colorName');
    }
    return resolvedColor;
  } catch (e) {
    throw Exception('Error resolving MaterialColor: $colorName. Error: $e');
  }
}

/// Extracts arguments from a method call like `withOpacity(0.5)`
List<dynamic> _extractArguments(String methodCall) {
  final argsString = methodCall.split('(')[1].replaceFirst(')', '');
  return argsString.split(',').map((e) => double.parse(e.trim())).toList();
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
