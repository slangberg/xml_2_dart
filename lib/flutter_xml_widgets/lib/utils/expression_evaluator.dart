import 'dart:convert';
import 'package:flutter/material.dart';
import 'color_parser.dart';
import 'expression_parser.dart';

class ExpressionEvaluator {
  final Map<String, dynamic> context;

  ExpressionEvaluator(this.context);

  dynamic evaluate(String expression) {
    print("ExpressionEvaluator.evaluate expression: $expression");
    final parser = ExpressionGrammarDefinition().build();
    final result = parser.parse(expression);

    if (result.isFailure) {
      throw Exception(
          'ExpressionGrammarDefinition failed to parse: $expression');
    }

    return _resolveValues(result.value);
  }

  dynamic _resolveValues(dynamic value) {
    if (value is Map && value['type'] == 'ternary') {
      print('Resolving ternary expression: $value');
      // Resolve ternary expression
      final condition = _resolveValues(value['condition']);
      final trueValue = _resolveValues(value['trueValue']);
      final falseValue = _resolveValues(value['falseValue']);
      return condition ? trueValue : falseValue;
    } else if (value is String && context.containsKey(value)) {
      print('Resolving context expression: $value: ${context[value]}');
      // Resolve simple keys directly from context

      return context[value];
    } else if (value is String && value.contains('.')) {
      // Resolve dot notation dynamically
      print('Resolving dot notion expression: $value');
      return _resolveDotNotationKey(value, context);
    } else if (value is List) {
      // Resolve lists recursively
      return value.map(_resolveValues).toList();
    }
    return value; // Return value as-is if no further resolution is needed
  }
}

/// Evaluates expressions for dynamic props like colors, JSON, or context mapping.
dynamic evaluateExpression(dynamic expression, Map<String, dynamic> context) {
  print("Evaluating expression: $expression");
  if (expression is! String) {
    return expression; // Return as-is if not a string
  }

  try {
    // Delegate to ExpressionEvaluator for expressions wrapped in {}
    if (expression.startsWith('{') && expression.endsWith('}')) {
      final evaluator = ExpressionEvaluator(context);
      final innerExpression = expression.substring(1, expression.length - 1);
      return evaluator.evaluate(innerExpression);
    }

    // Handle string interpolation (e.g., "Welcome, {user.name}!")
    final regex = RegExp(r'\{(.*?)\}');
    if (regex.hasMatch(expression)) {
      return expression.replaceAllMapped(regex, (match) {
        final key = match.group(1) ?? '';
        return evaluateExpression(key, context).toString();
      });
    }

    // Handle hex color codes like #RRGGBB or #AARRGGBB
    if (expression.startsWith('#')) {
      return _getColorFromHex(expression);
    }

    // Handle dot notation or native variables/methods
    if (expression.contains('.')) {
      print("Resolving dot notation key: $expression");
      return _resolveDotNotationKey(expression, context);
    }

    // Default case: Return as a context key or string
    return context[expression] ?? expression;
  } catch (e) {
    throw Exception('Error evaluating expression: $expression. Error: $e');
  }
}

/// Resolves a key with dot notation (e.g., `user.name`) in the given context.
/// If the first key does not exist in the context, treats the string as a method call or native variable.
dynamic _resolveDotNotationKey(String key, Map<String, dynamic> context) {
  try {
    final parts = key.split('.');
    final firstKey = parts.first;

    // Check if the first key exists in the context
    if (!context.containsKey(firstKey)) {
      print(
          "Key not found in context: $firstKey trying _handleNativeOrMethodCall");
      // If not found in context, return the key as a method call or native variable
      return _handleNativeOrMethodCall(key);
    }

    // If found in context, proceed with dot notation resolution
    dynamic value = context[firstKey];
    for (var i = 1; i < parts.length; i++) {
      final part = parts[i];
      if (value is Map<String, dynamic>) {
        if (!value.containsKey(part)) {
          throw Exception('Key not found: $part in $value');
        }
        value = value[part];
      } else if (value is List) {
        final index = int.tryParse(part);
        if (index != null && index >= 0 && index < value.length) {
          value = value[index];
        } else {
          throw Exception('Invalid list index: $part in $value');
        }
      } else if (value != null &&
          value.toString().startsWith('Color') &&
          part.contains('withOpacity')) {
        print("_handleColorMethod");
        return _handleColorMethod(value, part);
      } else {
        throw Exception('Invalid key access: $part in $value');
      }
    }

    return value;
  } catch (e) {
    throw Exception('Error resolving dot notation key: $key. Error: $e');
  }
}

/// Handles method calls or native variable lookups when the key is not found in the context.
dynamic _handleNativeOrMethodCall(String key) {
  // Add support for native method calls or fallback logic
  if (key.startsWith('Colors.')) {
    return ColorParser.parseColor(key);
  }
  throw Exception('Unknown variable or method call: $key');
}

/// Handles color-specific method calls (e.g., `Colors.blue.withOpacity(0.5)`).
dynamic _handleColorMethod(dynamic color, String method) {
  try {
    if (method.startsWith('withOpacity')) {
      final args = RegExp(r'withOpacity\((.*?)\)').firstMatch(method);
      if (args != null) {
        final opacity = double.parse(args.group(1)!);
        return (color as Color).withOpacity(opacity);
      }
    }
    throw Exception('Unsupported color method: $method');
  } catch (e) {
    throw Exception('Error handling color method: $method. Error: $e');
  }
}

/// Converts a hex color string to a [Color].
Color _getColorFromHex(String hexColor) {
  final buffer = StringBuffer();
  if (hexColor.length == 7)
    buffer.write('ff'); // Add alpha channel if not provided
  buffer.write(hexColor.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
