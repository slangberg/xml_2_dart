import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml_to_dart/flutter_xml_widgets/lib/utils/expression_evaluator.dart';

void main() {
  group('Expression Evaluation Tests', () {
    late Map<String, dynamic> context;

    setUp(() {
      context = {
        'isLoggedIn': true,
        'user': {
          'name': 'John Doe',
        },
        'Colors': {
          'blue': Colors.blue,
          'red': Colors.red,
        },
      };
    });

    test('Ternary expression evaluates correctly', () {
      const expression = '{isLoggedIn ? Colors.blue : Colors.red}';
      final result = evaluateExpression(expression, context);
      expect(result, Colors.blue);

      // Modify the context to test the false case
      context['isLoggedIn'] = false;
      final falseResult = evaluateExpression(expression, context);
      expect(falseResult, Colors.red);
    });

    test('Dot notation resolves correctly', () {
      const expression = '{user.name}';
      final result = evaluateExpression(expression, context);
      expect(result, 'John Doe');
    });

    test('Color method withOpacity evaluates correctly', () {
      const expression = '{Colors.red.withOpacity(0.5)}';
      final result = evaluateExpression(expression, context);
      expect(result, Colors.red.withOpacity(0.5));
    });

    test('String interpolation resolves correctly', () {
      const expression = 'Hello, {user.name}!';
      final result = evaluateExpression(expression, context);
      expect(result, 'Hello, John Doe!');
    });

    test('Hex color resolves correctly', () {
      const expression = '#FF5733';
      final result = evaluateExpression(expression, context);
      expect(result, const Color(0xFFFF5733));
    });

    test('Invalid key throws exception', () {
      const expression = '{invalidKey}';
      expect(() => evaluateExpression(expression, context),
          throwsA(isA<Exception>()));
    });

    test('Invalid dot notation key throws exception', () {
      const expression = '{user.invalidKey}';
      expect(() => evaluateExpression(expression, context),
          throwsA(isA<Exception>()));
    });

    test('Unsupported color method throws exception', () {
      const expression = '{Colors.blue.unsupportedMethod()}';
      expect(() => evaluateExpression(expression, context),
          throwsA(isA<Exception>()));
    });
  });
}
