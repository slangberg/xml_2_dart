import 'expression_parser.dart';

class ExpressionEvaluator {
  final Map<String, dynamic> context;

  ExpressionEvaluator(this.context);

  dynamic evaluate(String expression) {
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
    } else if (value is Map && value['type'] == 'ternary') {
      final condition = _resolveValues(value['condition']);
      final trueValue = _resolveValues(value['trueValue']);
      final falseValue = _resolveValues(value['falseValue']);
      return condition ? trueValue : falseValue;
    } else if (value is List) {
      return value.map(_resolveValues).toList();
    }
    return value;
  }
}
