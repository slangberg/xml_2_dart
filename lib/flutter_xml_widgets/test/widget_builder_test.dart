import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xml_to_dart/flutter_xml_widgets/lib/widgets/default_widgets.dart';
import 'package:xml_to_dart/flutter_xml_widgets/lib/widgets/widget_registry.dart';

void main() {
  group('WidgetRegistry Tests', () {
    setUp(() {
      // Clear the registry before each test
      registerDefaultWidgets();
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

    group('Default Widgets Tests', () {
      testWidgets('renders Text widget with correct props',
          (WidgetTester tester) async {
        final builder = WidgetRegistry.getBuilder('Text');
        expect(builder, isNotNull);

        final widget = builder!(
          props: {
            'value': 'Hello, World!',
            'fontSize': 20.0,
            'color': Colors.red
          },
          context: {},
          children: [],
          rawChildren: [],
        );

        await tester.pumpWidget(MaterialApp(home: widget));

        expect(find.text('Hello, World!'), findsOneWidget);
        final textWidget = tester.widget<Text>(find.text('Hello, World!'));
        expect(textWidget.style?.fontSize, 20.0);
        expect(textWidget.style?.color, Colors.red);
      });

      testWidgets('renders Container widget with correct props',
          (WidgetTester tester) async {
        final builder = WidgetRegistry.getBuilder('Container');
        expect(builder, isNotNull);

        final widget = builder!(
          props: {'padding': const EdgeInsets.all(10.0), 'color': Colors.blue},
          context: {},
          children: [Text('Child')],
          rawChildren: [],
        );

        await tester.pumpWidget(MaterialApp(home: widget));

        final containerWidget =
            tester.widget<Container>(find.byType(Container));
        expect(containerWidget.padding, const EdgeInsets.all(10.0));
        expect(containerWidget.color, Colors.blue);
        expect(find.text('Child'), findsOneWidget);
      });
    });
  });

  test('ForEach widget builds correctly', () {
    final builder = WidgetRegistry.getBuilder('ForEach');
    expect(builder, isNotNull);

    final rawXml =
        '<p><Container padding="0"><Text fontSize="20" value="{item}" /></Container></p>';
    final rawChildren = XmlDocument.parse(rawXml)
        .rootElement
        .children
        .whereType<XmlElement>()
        .toList();

    final list = ['1', '2', '3'];

    final props = {
      'list': list,
      'itemAs': 'item',
    };

    final widget = builder!(
      props: props,
      children: [],
      context: {},
      rawChildren: rawChildren,
    );

    expect(widget, isA<Column>());
    final columnWidget = widget as Column;
    expect(columnWidget.children.length, 3);

    for (var i = 0; i < columnWidget.children.length; i++) {
      final childColumn = columnWidget.children[i] as Column;
      expect(childColumn.children.length, 1);
      final containerWidget = childColumn.children.first as Container;
      expect(containerWidget, isA<Container>());
      final textWidget = containerWidget.child as Text;
      expect(textWidget, isA<Text>());
      expect(textWidget.data, list[i]);
      // expect(find.text(list[i]), findsOneWidget);
    }
  });

  test('ForEach widget throws exception when list is null', () {
    final builder = WidgetRegistry.getBuilder('ForEach');
    expect(builder, isNotNull);

    expect(
      () => builder!(
        props: {
          'itemAs': 'item',
        },
        children: [],
        context: {},
        rawChildren: [],
      ),
      throwsException,
    );
  });
}
