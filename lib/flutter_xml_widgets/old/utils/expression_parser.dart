import 'package:petitparser/petitparser.dart';

class ExpressionGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref0(expression).end();

  Parser expression() => ref0(ternaryExpression);

  /// Parses ternary expressions of the form `condition ? trueValue : falseValue`.
  Parser ternaryExpression() => (ref0(orExpression) &
              (string('?').trim() &
                      ref0(expression) &
                      string(':').trim() &
                      ref0(expression))
                  .optional())
          .map((values) {
        if (values[1] == null) {
          // No ternary operator, return the base condition
          return values[0];
        } else {
          // Ternary operator present, parse condition, trueValue, and falseValue
          final condition = values[0];
          final trueValue =
              values[1][1]; // Extract trueValue from the second part
          final falseValue =
              values[1][3]; // Extract falseValue from the second part

          return {
            'type': 'ternary',
            'condition': condition,
            'trueValue': trueValue,
            'falseValue': falseValue,
          };
        }
      });

  Parser orExpression() => ref0(andExpression)
          .separatedBy(string('||').trim(), includeSeparators: false)
          .map((values) {
        return values.reduce((a, b) => a || b);
      });

  Parser andExpression() => ref0(equalityExpression)
          .separatedBy(string('&&').trim(), includeSeparators: false)
          .map((values) {
        return values.reduce((a, b) => a && b);
      });

  Parser equalityExpression() => ref0(comparisonExpression)
          .separatedBy(
        string('==').trim() | string('!=').trim(),
        includeSeparators: true,
      )
          .map((values) {
        var result = values.first;
        for (var i = 1; i < values.length; i += 2) {
          final operator = values[i];
          final nextValue = values[i + 1];
          if (operator == '==') {
            result = result == nextValue;
          } else if (operator == '!=') {
            result = result != nextValue;
          }
        }
        return result;
      });

  Parser comparisonExpression() => ref0(arithmeticExpression)
          .separatedBy(
        string('<=').trim() |
            string('<').trim() |
            string('>=').trim() |
            string('>').trim(),
        includeSeparators: true,
      )
          .map((values) {
        var result = values.first;
        for (var i = 1; i < values.length; i += 2) {
          final operator = values[i];
          final nextValue = values[i + 1];
          if (operator == '<=') {
            result = result <= nextValue;
          } else if (operator == '<') {
            result = result < nextValue;
          } else if (operator == '>=') {
            result = result >= nextValue;
          } else if (operator == '>') {
            result = result > nextValue;
          }
        }
        return result;
      });

  Parser arithmeticExpression() => ref0(term)
          .separatedBy(
        string('+').trim() | string('-').trim(),
        includeSeparators: true,
      )
          .map((values) {
        var result = values.first;
        for (var i = 1; i < values.length; i += 2) {
          final operator = values[i];
          final nextValue = values[i + 1];
          if (operator == '+') {
            result = result + nextValue;
          } else if (operator == '-') {
            result = result - nextValue;
          }
        }
        return result;
      });

  Parser term() => ref0(factor)
          .separatedBy(
        string('*').trim() | string('/').trim(),
        includeSeparators: true,
      )
          .map((values) {
        var result = values.first;
        for (var i = 1; i < values.length; i += 2) {
          final operator = values[i];
          final nextValue = values[i + 1];
          if (operator == '*') {
            result = result * nextValue;
          } else if (operator == '/') {
            result = result / nextValue;
          }
        }
        return result;
      });

  Parser factor() => ref0(dotNotation) | ref0(value) | ref0(parentheses);

  /// Parses dot notation keys like `user.name`
  Parser dotNotation() =>
      ref0(identifier).separatedBy(char('.')).flatten().trim();

  Parser value() => (ref0(number) | ref0(boolean) | ref0(identifier));

  Parser number() =>
      digit().plus().flatten().trim().map((value) => double.parse(value));

  Parser boolean() =>
      (string('true') | string('false')).trim().map((value) => value == 'true');

  Parser identifier() => letter().plus().flatten().trim();

  Parser parentheses() =>
      char('(').trim() & ref0(expression) & char(')').trim();
}
