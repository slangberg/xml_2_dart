import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:expressions/expressions.dart';
import 'package:xml_to_dart/flutter_xml_widgets/lib/utils/exceptions.dart';
import 'package:xml_to_dart/flutter_xml_widgets/lib/widgets/widget_registry.dart';

import '../parsers/attr_evaluator.dart';
import '../parsers/color_resolver.dart';

// void main() {
//   const xmlString = '''
// <Container color="{Color.fromARGB(255, 255, 0, 0)}">
//   <If condition="{isLoggedIn}">
//     <Text value="Welcome {user.name}" fontSize="{60}" color="{Colors.white}" />
//   </If>
// </Container>
// ''';

//   final context = {
//     'isLoggedIn': true,
//     'user': {'name': 'John Doe'},
//     'Colors': const ColorsResolver(),
//   };

//   final parser = XmlWidgetParser(context: context);
//   final result = parser.parseXml(xmlString);

//   print(result);
// }

class XmlWidgetParser {
  final Map<String, dynamic> context;

  XmlWidgetParser({required Map<String, dynamic> context})
      : context = {
          ...context,
          'Colors': const ColorsResolver(),
        };

  /// Parse the entire XML string and process the root element
  dynamic parseXml(String xmlString, {bool? debug}) {
    final document = XmlDocument.parse(xmlString);
    if (debug != null && debug) {
      return debugTree(document.rootElement);
    }
    return _buildWidgetFromXml(document.rootElement);
  }

  dynamic debugTree(XmlElement element) {
    final tagName = element.name.local;
    final attributes = <String, dynamic>{};
    for (final attribute in element.attributes) {
      attributes[attribute.name.local] = _evaluateDynamicProp(attribute.value);
    }

    final children =
        element.children.whereType<XmlElement>().map(debugTree).toList();

    return {
      'tag': tagName,
      'attributes': attributes,
      'children': children,
    };
  }

  /// Recursively build widgets or parse attributes from XML elements
  Widget _buildWidgetFromXml(XmlElement element) {
    final tagName = element.name.local;

    // Parse attributes and evaluate dynamic expressions
    final attributes = <String, dynamic>{};
    for (final attribute in element.attributes) {
      final propTransformers = WidgetRegistry.getTransformers(tagName) ?? {};
      final key = attribute.name.local;

      if (propTransformers.containsKey(key)) {
        attributes[key] =
            propTransformers[key]!(_evaluateDynamicProp(attribute.value));
      } else {
        attributes[key] = _evaluateDynamicProp(attribute.value);
      }
    }

    // Process children
    final children = element.children
        .whereType<XmlElement>()
        .map(_buildWidgetFromXml)
        .toList();

    final builder = WidgetRegistry.getBuilder(tagName);
    if (builder != null) {
      return builder(attributes, children, context);
    }

    throw UnknownWidgetException(tagName);
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
