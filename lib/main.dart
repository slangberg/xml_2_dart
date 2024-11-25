import 'package:flutter/material.dart';
import './flutter_xml_widgets/flutter_xml_widgets.dart';

void main() {
  registerDefaultWidgets();

  const xml = '''
<Container padding="40" color="Colors.blue">
  <If condition="{isLoggedIn}">
    <Text value="Welcome {user.name}" fontSize="{60}" color="Colors.white" />
  </If>
</Container>
  ''';

  final parser = XmlWidgetParser(context: {
    'isLoggedIn': true,
    'userName': 'John Doe',
    'user': {'name': 'John Doe'},
  });

  runApp(
    MaterialApp(
      home: Scaffold(
        body: parser.parseXml(xml),
      ),
    ),
  );
}
