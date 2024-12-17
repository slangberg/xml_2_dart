import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml_to_dart/flutter_xml_widgets/lib/utils/exceptions.dart';
import 'package:xml_to_dart/flutter_xml_widgets/lib/widgets/widget_registry.dart';

import 'package:xml_to_dart/flutter_xml_widgets/lib/widgets/xml_widget_parser.dart';

// import '../xml_widget_parser.dart'; // Adjust the path as necessary

void main() {
  group('XmlWidgetParser', () {
    late XmlWidgetParser parser;

    setUp(() {
      // WidgetRegistry.clearDirectory();
      WidgetRegistry.register(
        tag: 'Test',
        builder: ({
          required Map<String, dynamic> props,
          required List<Widget> children,
          required Map<String, dynamic> context,
          required List<XmlNode> rawChildren,
        }) {
          final child =
              props['child'] != null ? [props['child'] as Widget] : children;

          return Container(
            key: Key('root'),
            child: Column(children: child),
          );
        },
      );

      WidgetRegistry.register(
        tag: 'Text',
        builder: ({
          required Map<String, dynamic> props,
          required List<Widget> children,
          required Map<String, dynamic> context,
          required List<XmlNode> rawChildren,
        }) {
          return Text(props['value']);
        },
      );

      parser = XmlWidgetParser(context: {});
    });

    test('parseXml with debug mode', () {
      final xmlString = '<Test><child name="test"/></Test>';
      final result = parser.parseXml(xmlString, debug: true);
      expect(result, isA<Map>());
      expect(result['tag'], 'Test');
      expect(result['children'][0]['tag'], 'child');
      expect(result['children'][0]['attributes']['name'], 'test');
    });

    test('WidgetRegistry registers widgets correctly', () {
      expect(WidgetRegistry.getBuilder('Test'), isNotNull);
      expect(WidgetRegistry.getBuilder('Text'), isNotNull);
      expect(WidgetRegistry.getBuilder('Slot'), isNotNull);
    });

    test('parseXml without debug mode', () {
      final xmlString = '<Text value="Hello, World!" />';
      final result = parser.parseXml(xmlString);
      expect(result, isA<Text>());
      expect((result as Text).data, 'Hello, World!');
    });

    test('_evaluateDynamicProp with static value', () {
      final result = parser.evaluateDynamicProp('staticValue');
      expect(result, 'staticValue');
    });

    test('_evaluateDynamicProp with dynamic expression', () {
      parser = XmlWidgetParser(context: {'item': 'DynamicValue'});
      final result = parser.evaluateDynamicProp('{item}');
      expect(result, 'DynamicValue');
    });

    test('_evaluateDynamicProp with interpolated string', () {
      parser = XmlWidgetParser(context: {'item': 'DynamicValue'});
      final result = parser.evaluateDynamicProp('Value is {item}');
      expect(result, 'Value is DynamicValue');
    });

    test('_buildWidgetFromXml with valid widget', () {
      final xmlString = '<Text value="Hello, World!" />';
      final result = parser.parseXml(xmlString);
      expect(result, isA<Text>());
      expect((result as Text).data, 'Hello, World!');
    });

    test('_buildWidgetFromXml with unknown widget', () {
      final xmlString = '<UnknownWidget value="Hello, World!" />';
      expect(() => parser.parseXml(xmlString),
          throwsA(isA<UnknownWidgetException>()));
    });

    test('_buildWidgetFromXml with Slot widget', () {
      const xmlString = '''
        <Test>
          <Slot bindTo="child">
            <Text value="Hello, Slot!" />
          </Slot>
          <Text value="Outside" />
        </Test>
      ''';
      final result = parser.parseXml(xmlString);
      expect(result, isA<Container>());
      final container = result as Container;
      expect(container.child, isA<Column>());
      final column = container.child as Column;
      print(column.children);
      expect(column.children[0], isA<Text>());
      final text = column.children[0] as Text;
      expect(text.data, 'Hello, Slot!');
    });

    test('parseXml with nested widgets', () {
      const xmlString = '''
        <Test>
          <Text value="Nested Text 1" />
          <Text value="Nested Text 2" />
        </Test>
      ''';
      final result = parser.parseXml(xmlString);
      expect(result, isA<Container>());
      final container = result as Container;
      expect(container.child, isA<Column>());
      final column = container.child as Column;
      expect(column.children.length, 2);
      expect(column.children[0], isA<Text>());
      expect((column.children[0] as Text).data, 'Nested Text 1');
      expect(column.children[1], isA<Text>());
      expect((column.children[1] as Text).data, 'Nested Text 2');
    });

    test('parseXml with attributes', () {
      final xmlString = '<Text value="Hello, World!" />';
      final result = parser.parseXml(xmlString);
      expect(result, isA<Text>());
      final text = result as Text;
      expect(text.data, 'Hello, World!');
    });
  });
}
