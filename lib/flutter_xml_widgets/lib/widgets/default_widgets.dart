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
    tag: 'Text',
    builder: ({
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
    propConfigs: {
      'fontSize': PropConfig(
          transformer: (value) => double.parse(value),
          preTransformType: String,
          type: double),
    },
  );

  WidgetRegistry.register(
    tag: 'Container',
    builder: ({
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
    propConfigs: {
      'padding': PropConfig(
          transformer: (value) => EdgeInsets.all(value.toDouble()),
          preTransformType: int,
          type: EdgeInsets),
    },
  );

  WidgetRegistry.register(
    tag: 'If',
    builder: ({
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
  );

  WidgetRegistry.register(
    tag: 'ForEach',
    parseChildren: false,
    builder: ({
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
              .parseXml(child.toString()),
        );

        // print(
        //     'Rendered Children: $renderedChildren, rawChildren: $rawChildren');

        return Column(
            key: Key('repeatedWidget_$index'),
            children: renderedChildren.toList().cast<Widget>());
      }).toList();

      // Return the repeated widgets in a column (or customize as needed)
      return Column(
        key: const Key('repeatedWidgetsColumn'),
        mainAxisAlignment: MainAxisAlignment.start,
        children: repeatedWidgets,
      );
    },
  );
}
