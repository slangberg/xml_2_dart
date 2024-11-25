import 'package:flutter/material.dart';
import 'widget_registry.dart';

void registerDefaultWidgets() {
  WidgetRegistry.register(
    'Text',
    (props, children, context) {
      return Text(
        props['value'] ?? '',
        style: TextStyle(
          fontSize: props['fontSize'],
          color: props['color'],
        ),
      );
    },
    {
      // 'fontSize': (value) => double.parse(value),
    },
  );

  WidgetRegistry.register(
    'Container',
    (props, children, context) {
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
    (props, children, context) {
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
}
