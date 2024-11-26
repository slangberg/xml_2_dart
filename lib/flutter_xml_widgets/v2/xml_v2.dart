import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:expressions/expressions.dart';

import 'attr_evaluator.dart';
import 'color_resolver.dart';

void main() {
  const xmlString = '''
<Container color="{Color.fromARGB(255, 255, 0, 0)}">
  <If condition="{isLoggedIn}">
    <Text value="Welcome {user.name}" fontSize="{60}" color="{Colors.white}" />
  </If>
</Container>
''';

  final context = {
    'isLoggedIn': true,
    'user': {'name': 'John Doe'},
    'Colors': const ColorsResolver(),
  };

  final parser = XmlWidgetParser(context: context);
  final result = parser.parseXml(xmlString);

  print(result);
}

class XmlWidgetParser {
  final Map<String, dynamic> context;

  XmlWidgetParser({required this.context});

  /// Parse the entire XML string and process the root element
  dynamic parseXml(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    return _buildWidgetFromXml(document.rootElement);
  }

  /// Recursively build widgets or parse attributes from XML elements
  dynamic _buildWidgetFromXml(XmlElement element) {
    final tagName = element.name.local;

    // Parse attributes and evaluate dynamic expressions
    final attributes = <String, dynamic>{};
    for (final attribute in element.attributes) {
      attributes[attribute.name.local] = _evaluateDynamicProp(attribute.value);
    }

    // Process children
    final children = element.children
        .whereType<XmlElement>()
        .map(_buildWidgetFromXml)
        .toList();

    return {
      'tag': tagName,
      'attributes': attributes,
      'children': children,
    };
  }

  /// Evaluate dynamic expressions within attributes
  dynamic _evaluateDynamicProp(String value) {
    if (value.startsWith('{') && value.endsWith('}')) {
      // Expression inside `{}`: evaluate it
      final expression = value.substring(1, value.length - 1);
      const evaluator = AttributeEvaluator();
      return evaluator.eval(Expression.parse(expression), context);
    } else if (value.contains('{') && value.contains('}')) {
      // Interpolated string: replace placeholders dynamically
      final regex = RegExp(r'\{(.*?)\}');
      return value.replaceAllMapped(regex, (match) {
        final expression = match.group(1) ?? '';
        const evaluator = AttributeEvaluator();
        return evaluator.eval(Expression.parse(expression), context).toString();
      });
    }

    // Static value: return as-is
    return value;
  }
}