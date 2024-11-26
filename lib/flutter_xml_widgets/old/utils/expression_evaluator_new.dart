import 'package:expressions/expressions.dart';
import 'dart:math';

void main() {
  example_2();
}

// Example 2: evaluate expression with custom evaluator
void example_2() {
  // Parse expression:
  var expression = Expression.parse("'Hello '+person.name");

  // Create context containing all the variables and functions used in the expression
  var context = {
    'person': {'name': 'Jane'}
  };

  // The default evaluator can not handle member expressions like `person.name`.
  // When you want to use these kind of expressions, you'll need to create a
  // custom evaluator that implements the `evalMemberExpression` to get property
  // values of an object (e.g. with `dart:mirrors` or some other strategy).
  const evaluator = MyEvaluator();
  var r = evaluator.eval(expression, context);

  print(r); // = 'Hello Jane'
}

class MyEvaluator extends ExpressionEvaluator {
  const MyEvaluator();

  @override
  dynamic evalMemberExpression(
      MemberExpression expression, Map<String, dynamic> context) {
    var object = eval(expression.object, context).toJson();
    return object[expression.property.name];
  }
}
