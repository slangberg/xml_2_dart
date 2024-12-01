import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:expressions/expressions.dart';
import 'package:xml_to_dart/flutter_xml_widgets/lib/utils/exceptions.dart';
import 'package:xml_to_dart/flutter_xml_widgets/lib/widgets/widget_registry.dart';

import '../parsers/attr_evaluator.dart';
import '../parsers/color_resolver.dart';

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

    final rawChildren = element.children.whereType<XmlElement>().toList();

    final children = rawChildren.map(debugTree).toList();

    return {
      'tag': tagName,
      'attributes': attributes,
      'children': children,
      'rawChildren': rawChildren,
    };
  }

  /// Recursively build widgets or parse attributes from XML elements
  Widget _buildWidgetFromXml(XmlElement element,
      {Map<String, dynamic>? replacementContext}) {
    final tagName = element.name.local;

    // Parse attributes and evaluate dynamic expressions
    final attributes = <String, dynamic>{};

    final localContext = replacementContext ?? context;

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

    final builder = WidgetRegistry.getBuilder(tagName);

    final rawChildren = element.children.whereType<XmlElement>().toList();

    final children = attributes.containsKey('list')
        ? [] as List<Widget>
        : rawChildren.map(_buildWidgetFromXml).toList();

    if (builder != null) {
      return builder!(
          props: attributes,
          context: localContext,
          children: children,
          rawChildren: rawChildren);
    }

    throw UnknownWidgetException(tagName);
  }

  /// Evaluate dynamic expressions within attributes
  dynamic _evaluateDynamicProp(String value,
      {Map<String, dynamic>? replacementContext}) {
    if (value.startsWith('{') && value.endsWith('}')) {
      // Expression inside `{}`: evaluate it
      final expression = value.substring(1, value.length - 1);
      const evaluator = AttributeEvaluator();
      return evaluator.eval(
          Expression.parse(expression), replacementContext ?? context);
    } else if (value.contains('{') && value.contains('}')) {
      // Interpolated string: replace placeholders dynamically
      final regex = RegExp(r'\{(.*?)\}');
      return value.replaceAllMapped(regex, (match) {
        final expression = match.group(1) ?? '';
        const evaluator = AttributeEvaluator();
        return evaluator
            .eval(Expression.parse(expression), replacementContext ?? context)
            .toString();
      });
    }

    // Static value: return as-is
    return value;
  }
}
