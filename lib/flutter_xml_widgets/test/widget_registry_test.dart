import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xml_to_dart/flutter_xml_widgets/lib/widgets/widget_registry.dart';

void main() {
  group('WidgetRegistry Tests', () {
    setUp(() {
      // Clear the registry before each test
      WidgetRegistry.register(
        'TestWidget',
        ({
          required Map<String, dynamic> props,
          required Map<String, dynamic> context,
          required List<Widget> children,
          required List<XmlElement> rawChildren,
        }) {
          return Text(props['value'] ?? '');
        },
      );
    });

    test('register and retrieve a widget without transformers', () {
      WidgetRegistry.register(
        'TestWidget',
        ({
          required Map<String, dynamic> props,
          required Map<String, dynamic> context,
          required List<Widget> children,
          required List<XmlElement> rawChildren,
        }) {
          return Text(props['value'] ?? '');
        },
      );

      final builder = WidgetRegistry.getBuilder('TestWidget');
      expect(builder, isNotNull);

      final widget = builder!(
        props: {'value': 'Hello, World!'},
        context: {},
        children: [],
        rawChildren: [],
      );

      expect(widget, isA<Text>());
      expect((widget as Text).data, 'Hello, World!');
    });

    test('register and retrieve a widget with transformers', () {
      WidgetRegistry.register(
        'TestWidget',
        ({
          required Map<String, dynamic> props,
          required Map<String, dynamic> context,
          required List<Widget> children,
          required List<XmlElement> rawChildren,
        }) {
          return Container(
            padding: props['padding'],
            color: props['color'],
          );
        },
        {
          'padding': (value) => EdgeInsets.all(double.parse(value)),
          'color': (value) => Color(int.parse(value)),
        },
      );

      final builder = WidgetRegistry.getBuilder('TestWidget');
      final transformers = WidgetRegistry.getTransformers('TestWidget');

      expect(builder, isNotNull);
      expect(transformers, isNotNull);

      final transformedProps = {
        'padding': transformers!['padding']!('10.0'),
        'color': transformers['color']!('0xFF0000FF'),
      };

      final widget = builder!(
        props: transformedProps,
        context: {},
        children: [],
        rawChildren: [],
      );

      expect(widget, isA<Container>());
      final container = widget as Container;
      expect(container.padding, EdgeInsets.all(10.0));
      expect(container.color, Color(0xFF0000FF));
    });

    test('retrieve non-existent widget returns null', () {
      final builder = WidgetRegistry.getBuilder('NonExistentWidget');
      expect(builder, isNull);
    });

    test('retrieve transformers for non-existent widget returns null', () {
      final transformers = WidgetRegistry.getTransformers('NonExistentWidget');
      expect(transformers, isNull);
    });
  });
}
