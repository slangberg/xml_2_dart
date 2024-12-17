import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xml_to_dart/flutter_xml_widgets/lib/widgets/widget_registry.dart';

void main() {
  group('WidgetRegistry Tests', () {
    setUp(() {
      // Clear the registry before each test
      WidgetRegistry.register(
        tag: 'TestWidget',
        builder: ({
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
        tag: 'TestWidget',
        builder: ({
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

    test('register and retrieve a widget with parseChildren option', () {
      WidgetRegistry.register(
        tag: 'ParseChildrenWidget',
        builder: ({
          required Map<String, dynamic> props,
          required Map<String, dynamic> context,
          required List<Widget> children,
          required List<XmlElement> rawChildren,
        }) {
          return Column(children: children);
        },
        parseChildren: true,
      );

      final builder = WidgetRegistry.getBuilder('ParseChildrenWidget');
      expect(builder, isNotNull);

      final widget = builder!(
        props: {},
        context: {},
        children: [Text('Child 1'), Text('Child 2')],
        rawChildren: [],
      );

      expect(widget, isA<Column>());
      expect((widget as Column).children.length, 2);
    });

    test(
        'register and retrieve a widget with raw children when parseChildren is false',
        () {
      WidgetRegistry.register(
        tag: 'RawChildrenWidget',
        builder: ({
          required Map<String, dynamic> props,
          required Map<String, dynamic> context,
          required List<Widget> children,
          required List<XmlElement> rawChildren,
        }) {
          return Column(
            children: rawChildren.map((e) => Text(e.toString())).toList(),
          );
        },
        parseChildren: false,
      );

      final builder = WidgetRegistry.getBuilder('RawChildrenWidget');
      expect(builder, isNotNull);

      final rawXml =
          '<p><Container padding="0.00"><Text fontSize="{20}" value="{item}" /></Container></p>';
      final document = XmlDocument.parse(rawXml);
      final rawChildren =
          document.rootElement.children.whereType<XmlElement>().toList();

      final widget = builder!(
        props: {},
        context: {},
        children: [],
        rawChildren: rawChildren,
      );

      expect(widget, isA<Column>());
      expect((widget as Column).children.length, rawChildren.length);
      expect(
          (widget.children.first as Text).data, rawChildren.first.toString());
    });

    test('register and retrieve a widget with pre and post transform', () {
      WidgetRegistry.register(
        tag: 'TransformWidget',
        builder: ({
          required Map<String, dynamic> props,
          required Map<String, dynamic> context,
          required List<Widget> children,
          required List<XmlElement> rawChildren,
        }) {
          return Text(props['value'] ?? '');
        },
        propConfigs: {
          'value': PropConfig(
            transformer: (value) => 'Transformed $value',
          ),
        },
      );

      final builder = WidgetRegistry.getBuilder('TransformWidget');

      final transformers = WidgetRegistry.getTransformers('TransformWidget');
      expect(builder, isNotNull);

      final widget = builder!(
        props: {'value': 'Hello'},
        context: {},
        children: [],
        rawChildren: [],
      );

      expect(widget, isA<Text>());
      expect(transformers!['value']!('Hello'), 'Transformed Hello');
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
