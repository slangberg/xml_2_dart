import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'widget_registry.dart';
import 'xml_widget_parser.dart';

typedef PropS = dynamic Function({
  required Map<String, dynamic> props,
  List<Widget> children,
  required Map<String, dynamic> context,
  required List<XmlNode> rawChildren,
});

void registerDefaultWidgets() {
  WidgetRegistry.register(
    'Text',
    ({
      required Map<String, dynamic> props,
      required List<Widget> children,
      required Map<String, dynamic> context,
      required List<XmlNode> rawChildren,
    }) {
      return Text(
        props['value'] ?? '',
        style: TextStyle(
          fontSize: props['fontSize'],
          color: props['color'],
        ),
      );
    },
    {
      'fontSize': (value) => double.parse(value),
    },
  );

  WidgetRegistry.register(
    'Container',
    ({
      required Map<String, dynamic> props,
      required List<Widget> children,
      required Map<String, dynamic> context,
      required List<XmlNode> rawChildren,
    }) {
      return Container(
        padding: props['padding'],
        color: props['color'],
        child: children.isNotEmpty ? children.first : null,
      );
    },
    {
      'padding': (value) => EdgeInsets.all(double.parse(value)),
    },
  );

  WidgetRegistry.register(
    'If',
    ({
      required Map<String, dynamic> props,
      required List<Widget> children,
      required Map<String, dynamic> context,
      required List<XmlNode> rawChildren,
    }) {
      final condition = props['condition'] as bool;
      final elseChild = props['elseChild'] as Widget?;
      final trueChildren = children;

      // Render based on condition
      if (condition) {
        return Column(children: trueChildren); // Render children for `true`
      } else if (elseChild != null) {
        return elseChild; // Render fallback widget for `false`
      }
      return const SizedBox.shrink(); // Default to an empty widget
    },
    {},
  );

  WidgetRegistry.register(
    'ForEach',
    ({
      required Map<String, dynamic> props,
      required List<Widget> children,
      required Map<String, dynamic> context,
      required List<XmlNode> rawChildren,
    }) {
      // Retrieve the list to iterate over from the props
      final list = props['list'] as List<dynamic>?;
      if (list == null) {
        throw Exception('The "list" prop is required for Foreach.');
      }

      // Retrieve the key accessor or default to 'item'
      final keyAccessor = props['itemAs'] as String? ?? 'item';

      // Build widgets for each item in the list
      final repeatedWidgets = list.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        // Extend the context with the current item or key accessor
        final extendedContext = Map<String, dynamic>.from(context);

        extendedContext[keyAccessor] = item;
        extendedContext['index'] = index;

        // Build children widgets with the extended context
        final renderedChildren = rawChildren.map(
          (child) => XmlWidgetParser(context: extendedContext)
              .parseXml(rawChildren.toString()),
        );

        print('Rendered Children: $renderedChildren');

        return Column(children: renderedChildren.toList().cast<Widget>());
      }).toList();

      // Return the repeated widgets in a column (or customize as needed)
      return Column(children: repeatedWidgets);
    },
  );
}
