import 'package:petitparser/petitparser.dart';

class ExpressionGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref0(expression).end();

  Parser expression() => ref0(orExpression);

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

  Parser factor() => ref0(value) | ref0(parentheses);

  Parser value() => (ref0(number) | ref0(boolean) | ref0(identifier));

  Parser number() =>
      digit().plus().flatten().trim().map((value) => double.parse(value));

  Parser boolean() =>
      (string('true') | string('false')).trim().map((value) => value == 'true');

  Parser identifier() => letter().plus().flatten().trim();

  Parser parentheses() =>
      char('(').trim() & ref0(expression) & char(')').trim();
}
