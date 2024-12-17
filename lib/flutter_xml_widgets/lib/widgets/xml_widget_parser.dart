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
  dynamic parseXml(String xmlString, {bool? debug, bool? validateProps}) {
    final document = XmlDocument.parse(xmlString);
    if (debug != null && debug) {
      return debugTree(document.rootElement);
    }
    return _buildWidgetFromXml(document.rootElement, validateProps ?? true);
  }

  dynamic debugTree(XmlElement element) {
    final tagName = element.name.local;
    final attributes = <String, dynamic>{};
    for (final attribute in element.attributes) {
      attributes[attribute.name.local] = evaluateDynamicProp(attribute.value);
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
  Widget _buildWidgetFromXml(XmlElement element, bool validateProps) {
    final tagName = element.name.local;

    // Parse attributes and evaluate dynamic expressions
    final attributes = <String, dynamic>{};

    final widgetConfig = WidgetRegistry.getWidgetConfig(tagName);

    final propTransformers = WidgetRegistry.getTransformers(tagName) ?? {};

    for (final attribute in element.attributes) {
      final key = attribute.name.local;

      final evaluatedPropValue = evaluateDynamicProp(attribute.value);

      if (validateProps) {
        WidgetRegistry.validateSingleProp(
            tagName, key, evaluatedPropValue, true);
      }

      if (propTransformers.containsKey(key)) {
        final transformedValue =
            propTransformers[key]!(evaluateDynamicProp(attribute.value));
        // WidgetRegistry.validateSingleProp(
        //     tagName, key, transformedValue, false);
        attributes[key] = transformedValue;
      } else {
        attributes[key] = evaluateDynamicProp(attribute.value);
      }
    }

    final builder = WidgetRegistry.getBuilder(tagName);

    final rawChildren = element.children.whereType<XmlElement>().toList();

    rawChildren.where((child) => child.name.local == 'Slot').forEach((child) {
      String bindTo = child.getAttribute('bindTo') as String;
      Widget parsedWidget = _buildWidgetFromXml(
          child.children.whereType<XmlElement>().first, validateProps);
      attributes[bindTo] = parsedWidget;
    });

    final children = widgetConfig.parseChildren
        ? [const SizedBox.shrink()] as List<Widget>
        : rawChildren
            .where((child) => child.name.local != 'Slot')
            .map((child) => _buildWidgetFromXml(child, validateProps))
            .toList();

    if (builder != null) {
      return builder(
          props: attributes,
          context: context,
          children: children,
          rawChildren: rawChildren);
    }

    throw UnknownWidgetException(tagName);
  }

  /// Evaluate dynamic expressions within attributes
  dynamic evaluateDynamicProp(String value) {
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
