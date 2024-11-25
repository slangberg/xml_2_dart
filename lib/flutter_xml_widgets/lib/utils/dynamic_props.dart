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

/// Evaluates expressions for dynamic props like colors, JSON, or context mapping.
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

    // Handle hex color codes like #RRGGBB or #AARRGGBB
    if (expression.startsWith('#')) {
      return _getColorFromHex(expression);
    }

    // Delegate to ColorParser for Colors.<color> or Color.fromARGB/RGBO
    if (expression.startsWith('Colors.') ||
        expression.startsWith('Color.from')) {
      return ColorParser.parseColor(expression);
    }

    // Handle JSON for complex props
    // if (expression.startsWith('{{') &&
    //     expression.endsWith('}}') &&
    //     isJson(expression)) {
    //   return json.decode(expression);
    // }

    // Handle dot notation for nested context keys
    if (expression.contains('.')) {
      return _resolveDotNotationKey(expression, context);
    }

    // Default case: Return as a context key or string
    return context[expression] ?? expression;
  } catch (e) {
    throw Exception('Error evaluating expression: $expression. Error: $e');
  }
}

/// Resolves a key with dot notation (e.g., `user.name`) in the given context.
dynamic _resolveDotNotationKey(String key, Map<String, dynamic> context) {
  try {
    final parts = key.split('.');
    dynamic value = context;

    for (final part in parts) {
      if (value is Map<String, dynamic>) {
        value = value[part];
      } else if (value is List) {
        final index = int.tryParse(part);
        if (index != null && index >= 0 && index < value.length) {
          value = value[index];
        } else {
          throw Exception('Invalid list index: $part');
        }
      } else {
        throw Exception('Invalid key access: $part');
      }
    }

    return value;
  } catch (e) {
    throw Exception('Error resolving dot notation key: $key. Error: $e');
  }
}

/// Converts a hex color string to a [Color].
Color _getColorFromHex(String hexColor) {
  final buffer = StringBuffer();
  if (hexColor.length == 7) buffer.write('ff');
  buffer.write(hexColor.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
