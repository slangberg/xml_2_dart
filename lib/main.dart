import 'package:flutter/material.dart';
import './flutter_xml_widgets/flutter_xml_widgets.dart';

void main() {
  registerDefaultWidgets();

  const xml = '''
<Container padding="40" color="{isLoggedIn ? Colors.blue : Colors.red}">
  <If condition="{isLoggedIn}">
    <Text value="Welcome {user.name}" fontSize="{60}" color="{Colors.white}" />
  </If>
  <ForEach list="{items}">
    <Text value="{item.name}" />
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
