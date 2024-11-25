import 'package:flutter/widgets.dart';
import 'package:xml/xml.dart';
import '../utils/dynamic_props.dart';
import '../utils/exceptions.dart';
import 'widget_registry.dart';

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
      // Handle inline expressions like {count > 10}
      if (value.startsWith('{') && value.endsWith('}')) {
        final evaluator = ExpressionEvaluator(context);
        final innerExpression = value.substring(1, value.length - 1);
        return evaluator.evaluate(innerExpression);
      }

      // Handle numeric strings
      // final doubleValue = double.tryParse(value);
      // if (doubleValue != null) {
      //   return doubleValue; // Return as double if the value is numeric
      // }

      // Handle colors or other expressions
      if (value.startsWith('Colors.')) {
        return evaluateExpression(
            value, {}); // Use existing evaluateExpression logic for colors
      }

      // Handle string interpolation (replace {key} with context values)
      final regex = RegExp(r'\{(.*?)\}');
      if (regex.hasMatch(value)) {
        return value.replaceAllMapped(regex, (match) {
          final key = match.group(1) ?? '';
          if (context.containsKey(key)) {
            return context[key].toString();
          }
          throw Exception('Key not found in context: $key');
        });
      }

      // Default case: return the original string
      return value;
    } catch (e) {
      throw Exception('Error evaluating prop: $value. Error: $e');
    }
  }
}
