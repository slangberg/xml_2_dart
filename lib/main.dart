import 'package:chalkdart/chalk.dart';
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

  // print(parser.parseXml(xml, debug: true));

  // print(chalk.yellow.onBlue('Hello world!'));

  runApp(
    MaterialApp(
      home: Scaffold(
        body: parser.parseXml(xml),
      ),
    ),
  );
}
