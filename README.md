# xml_to_dart

![Header](header.jpg)

A Flutter project that parses XML to dynamically build Flutter widgets.

`xml_to_dart` is a versatile Flutter library designed to dynamically build Flutter widget trees from XML strings. By leveraging this library, developers can create complex and dynamic UIs based on external data sources or configurations. The library supports contextual data binding, allowing XML attributes to be dynamically resolved using a context map. Additionally, it provides a straightforward mechanism for registering custom widgets, enabling extensive customization and flexibility. With built-in error handling and a robust parsing mechanism, `xml_to_dart` simplifies the process of generating Flutter widgets from XML, making it an essential tool for dynamic UI generation in Flutter applications.

## Getting Started

This project demonstrates how to parse XML strings and convert them into Flutter widgets using a custom XML widget parser.

### Project Structure

- **lib/main.dart**: The entry point of the application. It sets up the context and parses an XML string to build the widget tree.
- **lib/flutter_xml_widgets**: Contains the core functionality for parsing XML and building widgets.
  - **lib/flutter_xml_widgets/lib/parsers/color_resolver.dart**: Contains the `ColorsResolver` class for resolving color values.
  - **lib/flutter_xml_widgets/lib/widgets/xml_widget_parser.dart**: Contains the `XmlWidgetParser` class for parsing XML strings and building widgets.
  - **lib/flutter_xml_widgets/lib/widgets/widget_registry.dart**: Manages the registration and retrieval of widget builders.
  - **lib/flutter_xml_widgets/lib/utils/exceptions.dart**: Defines custom exceptions used in the project.
- **test**: Contains unit tests for the XML widget parser and related functionality.
  - **lib/flutter_xml_widgets/test/xml_widget_parser_test.dart**: Tests for the `XmlWidgetParser` class.
  - **lib/flutter_xml_widgets/test/widget_registry_test.dart**: Tests for the `WidgetRegistry` class.
  - **lib/flutter_xml_widgets/test/widget_builder_test.dart**: Tests for individual widget builders.

### Running the Project

To run the project, use the following command:

```sh
flutter run
```

### Example Code

Here is an example of how to use the XML widget parser in your Flutter project:

```dart
import 'package:flutter/material.dart';
import './flutter_xml_widgets/flutter_xml_widgets.dart';

void main() {
  registerDefaultWidgets();

  const xml = '''
<Container padding="10" color="{isLoggedIn ? Colors.blue : Colors.red}">
  <ForEach list="{items}">
    <Container padding="5" color="{Colors.green}">
        <Text value="{item.name}" />
    </Container>
  </ForEach>
</Container>
  ''';

  final parser = XmlWidgetParser(context: {
    'isLoggedIn': true,
    'userName': 'John Doe',
    'user': {'name': 'John Doe'},
    'items': [
      {'name': 'Item 1'},
      {'name': 'Item 2'},
      {'name': 'Item 3'},
    ]
  });

  runApp(
    MaterialApp(
      home: Scaffold(
        body: parser.parseXml(xml),
      ),
    ),
  );
}


import 'package:flutter/material.dart';
import './flutter_xml_widgets/flutter_xml_widgets.dart';

void main() {
  registerDefaultWidgets();

  const xml = '''
<Container padding="10" color="{isLoggedIn ? Colors.blue : Colors.red}">
  <ForEach list="{items}">
    <Container padding="5" color="{Colors.green}">
      <Text value="{item.name}" />
      <Button onPressed="{onItemPress(item.index)}" text="Click Me" />
    </Container>
  </ForEach>
</Container>
  ''';

  final parser = XmlWidgetParser(context: {
    'isLoggedIn': true,
    'userName': 'John Doe',
    onItemPress: (index) => print('Item with the index of $index clicked')
    'user': {'name': 'John Doe'},
    'items': [
      {'name': 'Item 1', id: 1 },
      {'name': 'Item 2', id: 2 },
      {'name': 'Item 3',  id: 3},
    ]
  });

  runApp(
    MaterialApp(
      home: Scaffold(
        body: parser.parseXml(xml),
      ),
    ),
  );
}
```

## Widget Registration

In your project, widgets are registered with the WidgetRegistry so that the XmlWidgetParser can recognize and build them. Each widget is registered with a unique name and a builder function. The builder function takes the context, attributes, and children as parameters.

Here is an example of how to register widgets:

```dart
  WWidgetRegistry.register(
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
      type: double,
    ),
  },
);
```

Breakdown

- tag: The tag name used in the XML to identify this widget. In this case, it is 'Text'.
- builder: A function that builds the widget. It takes the following parameters:

  - props: A map of properties passed to the widget.
  - children: A list of child widgets.
  - context: A map of additional context information.
  - rawChildren: A list of raw XML nodes representing the children.
    The builder function returns a Text widget with the specified properties.

- propConfigs: A map of property configurations. Each property configuration is defined using the PropConfig class. In this example:
  - transformer: A function to transform the property value. Here, it converts the value to a double.
  - preTransformType: The type of the property before transformation. Here, it is String.
  - type: The type of the property after transformation. Here, it is double.

#### Properties (Attributes)

Props are the encoded XML attributes and are passed as a map of key-value pairs to the builder function. These attributes are extracted from the XML and can be used to configure the widget. For example, in the Container widget registration:

```dart
padding: EdgeInsets.all(double.parse(props['padding'] ?? '0')),
color: parseColor(props['color'], context),
```

#### Children

Children are passed as a list of widgets to the builder function. These children are the nested widgets within the XML. For example, in the Container widget registration:

```dart
child: children.isNotEmpty ? children.first : null,
```

#### rawChildren

rawChildren is a list of the raw xml nodes from the main source of xml that are initially parsed and are not yet processed into widgets. This is useful for scenarios where you need custom logic to process the children.

#### Context

The context is a map that provides dynamic values and expressions that can be used within the XML. This context is passed to the builder function and can be used to resolve dynamic properties. For example, in the ForEach widget registration:

```dart
final newContext = Map<String, dynamic>.from(context);
newContext['item'] = item;
```

### Auto Parse Child Configuration

The `autoParseChild` configuration allows you to control whether the children of a widget should be automatically parsed or not. When `parseChildren` is set to `false`, you can manually handle the raw XML children within the builder function. This is useful for scenarios where you need custom logic to process the children.

Here is an example of how to use the `parseChildren` configuration in combo with the `context`and `rawChildren`builder arguments in use in ForEach widget:

```dart
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
```
