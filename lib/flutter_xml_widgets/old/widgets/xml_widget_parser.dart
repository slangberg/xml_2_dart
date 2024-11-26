import 'package:flutter/widgets.dart';
import 'package:xml/xml.dart';
import '../utils/expression_evaluator.dart';
import '../../lib/utils/exceptions.dart';
import '../../lib/widgets/widget_registry.dart';

// import 'expression_evaluator.dart';

class XmlWidgetParser {
  final Map<String, dynamic> context;

  XmlWidgetParser({required this.context});

  Widget parseXml(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    return _buildWidgetFromXml(document.rootElement);
  }

  Widget _buildWidgetFromXml(XmlElement element) {
    final tag = element.name.local;
    final props = <String, dynamic>{};

    // Extract props and evaluate them
    element.attributes.forEach((attr) {
      final propTransformers = WidgetRegistry.getTransformers(tag) ?? {};
      final key = attr.name.local;

      // Use the unified evaluation function for all props
      if (propTransformers.containsKey(key)) {
        props[key] = propTransformers[key]!(_evaluateDynamicProp(attr.value));
      } else {
        props[key] = _evaluateDynamicProp(attr.value);
      }
    });

    // Handle children
    final children = element.children
        .whereType<XmlElement>()
        .map(_buildWidgetFromXml)
        .toList();

    // Handle text content dynamically with context embedding
    if (element.children.whereType<XmlText>().isNotEmpty) {
      final textContent = element.text.trim();
      if (textContent.isNotEmpty) {
        props['content'] = _evaluateDynamicProp(textContent);
      }
    }

    // Retrieve the builder and build the widget
    final builder = WidgetRegistry.getBuilder(tag);
    if (builder != null) {
      print("Building widget: $tag with props: $props");
      return builder(props, children, context);
    }

    throw UnknownWidgetException(tag);
  }

  dynamic _evaluateDynamicProp(String value) {
    try {
      // Check if the value starts and ends with curly braces
      if (value.startsWith('{') && value.endsWith('}')) {
        final innerExpression = value.substring(1, value.length - 1);

        // Use ExpressionEvaluator for complex expressions
        return evaluateExpression(innerExpression, context);
      }

      // Fallback for other cases
      return value;
    } catch (e) {
      throw Exception(
          'Error evaluating prop: $value. Context: $context. Error: $e');
    }
  }
}
