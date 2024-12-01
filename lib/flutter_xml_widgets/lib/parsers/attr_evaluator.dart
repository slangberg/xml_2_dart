import 'package:flutter/material.dart';
import 'package:expressions/expressions.dart';

import 'color_resolver.dart';

class AttributeEvaluator extends ExpressionEvaluator {
  const AttributeEvaluator();

  @override
  dynamic evalMemberExpression(
      MemberExpression expression, Map<String, dynamic> context) {
    final object = eval(expression.object, context);

    String objectName;
    if (expression.object is Identifier) {
      objectName = (expression.object as Identifier).name;
    } else {
      objectName = expression.object.toString();
    }

    print({
      'name': expression.property.name,
      'objectName': objectName,
      'expression': expression,
      'resolvedObject': object,
      'objectType': object.runtimeType,
      'context': context
    });

    // Distinguish between property lookups and methods
    if (object is ColorsResolver) {
      print('object is ColorsResolver');
      // Check if the property is being accessed as part of a method call
      if (_isPartOfMethodCall(expression)) {
        // Return the method resolver instead of property value
        print('Returning method resolver');
        return object.resolveMethod(expression.property.name);
      } else {
        // Handle Colors.<color> like Colors.blue
        return object.resolve(expression.property.name);
      }
    } else if (object is Map<String, dynamic>) {
      return _resolveDotNotation(object, expression.property.name);
    } else if (objectName == 'Colors') {
      // Handle null Colors object
      print("Handle null Colors object");
      return const ColorsResolver();
    }

    throw Exception(
        'Unsupported member expression: ${expression.property.name}');
  }

  @override
  dynamic evalCallExpression(
      CallExpression expression, Map<String, dynamic> context) {
    try {
      dynamic target;

      if (expression.callee is MemberExpression) {
        // Resolve the MemberExpression
        final memberExpression = expression.callee as MemberExpression;

        String objectName;
        if (expression.callee is Identifier) {
          objectName = (memberExpression.object as Identifier).name;
        } else {
          objectName = memberExpression.object.toString();
        }

        if (objectName == 'Colors') {
          // If it's a ColorsResolver, resolve the method
          target = const ColorsResolver()
              .resolveMethod(memberExpression.property.name);
        }
      } else {
        // Handle cases where callee is a simple Identifier
        target = eval(expression.callee, context);
      }

      // Resolve the arguments
      final args =
          expression.arguments.map((arg) => eval(arg, context)).toList();

      print(
          'Evaluating call expression: $expression, Target: $target, Args: $args');

      // If the target is callable, invoke it
      if (target is Function) {
        return Function.apply(target, args);
      }

      throw Exception('Target is not callable: $target');
    } catch (e) {
      throw Exception("evalCallExpression eval error: $e");
    }
  }

  dynamic _resolveDotNotation(dynamic object, String key) {
    try {
      final parts = key.split('.');
      dynamic current = object;

      for (final part in parts) {
        if (current is Map<String, dynamic>) {
          if (!current.containsKey(part)) {
            throw Exception('Key not found: $part in $current');
          }
          current = current[part];
        } else if (current is List) {
          final index = int.tryParse(part);
          if (index != null && index >= 0 && index < current.length) {
            current = current[index];
          } else {
            throw Exception('Invalid list index: $part in $current');
          }
        } else if (current != null &&
            current.toString().startsWith('Instance of')) {
          // Resolve methods or properties on objects dynamically
          final result = _resolveObjectProperty(current, part);
          if (result == null) {
            throw Exception('Property $part not found in object $current');
          }
          current = result;
        } else {
          throw Exception('Unsupported object type for key $part in $current');
        }
      }

      return current;
    } catch (e) {
      throw Exception('Error resolving dot notation: $key. Error: $e');
    }
  }

  /// Dynamically resolve properties or methods on objects
  dynamic _resolveObjectProperty(dynamic object, String property) {
    final typeMirror = object.runtimeType;
    if (typeMirror.toString().contains(property)) {
      return object;
    }
    return null;
  }

  /// Detect if the current `MemberExpression` is part of a method call.
  bool _isPartOfMethodCall(MemberExpression expression) {
    return expression.property.name.contains('(') ||
        expression.property.name.contains('from');
  }
}
