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
      // Handle dot notation for nested context keys
      if (object.containsKey(expression.property.name)) {
        return object[expression.property.name];
      }
    } else if (object == null && objectName == 'Colors') {
      // Handle null Colors object
      print("Handle null Colors object");
      return const ColorsResolver();
    } else if (objectName == 'Colors') {
      // Special handling for `Color` type
      return ColorsResolver();
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
        final resolvedObject = eval(memberExpression.object, context);

        print({
          'target': target,
          'expression': expression,
          'callee': expression.callee,
          'memberExpression': memberExpression,
          'object': memberExpression.object,
          'resolvedObject': resolvedObject
        });

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

  /// Detect if the current `MemberExpression` is part of a method call.
  bool _isPartOfMethodCall(MemberExpression expression) {
    return expression.property.name.contains('(') ||
        expression.property.name.contains('from');
  }
}
