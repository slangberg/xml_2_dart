import 'package:flutter/material.dart';
import './flutter_xml_widgets/flutter_xml_widgets.dart';

void main() {
  registerDefaultWidgets();

  const xml = '''
<Container padding="16.0" color="Colors.blue">
  <If condition="{isLoggedIn}">
    <Text value="{userName}" fontSize="{60}" color="{Colors.white}" />
  </If>
</Container>
  ''';

  final parser = XmlWidgetParser(context: {
    'isLoggedIn': true,
    'userName': 'John Doe',
  });

  runApp(
    MaterialApp(
      home: Scaffold(
        body: parser.parseXml(xml),
      ),
    ),
  );
}
