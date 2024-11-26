import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml_to_dart/flutter_xml_widgets/v2/color_resolver.dart';
import 'package:xml_to_dart/flutter_xml_widgets/v2/xml_v2.dart';

void main() {
  group('XmlWidgetParser Tests', () {
    late XmlWidgetParser parser;
    late Map<String, dynamic> context;

    setUp(() {
      // Define the context for testing
      context = {
        'isLoggedIn': true,
        'user': {'name': 'John Doe'},
        'rawReturn': () => 12,
        'arg': (dynamic args) => args,
        'Colors': ColorsResolver(),
      };
      parser = XmlWidgetParser(context: context);
    });

    test('Parses raw return attributes', () {
      const xmlString = '<Container padding="{rawReturn()}" />';
      final result = parser.parseXml(xmlString, debug: true);
      expect(result['attributes']['padding'], 12);
    });

    test('Parses raw return attributes', () {
      const xmlString = '<Container show="{arg(isLoggedIn)}" />';
      final result = parser.parseXml(xmlString, debug: true);
      expect(result['attributes']['show'], true);
    });

    test('Parses static attributes', () {
      const xmlString = '<Container padding="40" />';
      final result = parser.parseXml(xmlString, debug: true);
      expect(result['attributes']['padding'], '40');
    });

    test('Evaluates color attributes with ternary expressions', () {
      const xmlString =
          '<Container color="{isLoggedIn ? Colors.blue : Colors.red}" />';
      final result = parser.parseXml(xmlString, debug: true);
      expect(result['attributes']['color'], Colors.blue);

      // Update the context to change the ternary result
      context['isLoggedIn'] = false;
      final resultFalse = parser.parseXml(xmlString, debug: true);
      expect(resultFalse['attributes']['color'], Colors.red);
    });

    test('Resolves string interpolation', () {
      const xmlString = '<Text value="Welcome {user.name}!" />';
      final result = parser.parseXml(xmlString, debug: true);
      expect(result['attributes']['value'], 'Welcome John Doe!');
    });

    test('Parses numeric attributes', () {
      const xmlString = '<Text fontSize="{60}" />';
      final result = parser.parseXml(xmlString, debug: true);
      expect(result['attributes']['fontSize'], 60);
    });

    test('Handles Color.fromRGBO', () {
      const xmlString =
          '<Container color="{Colors.fromRGBO(0, 0, 255, 0.5)}" />';
      final result = parser.parseXml(xmlString, debug: true);
      expect(result['attributes']['color'], const Color(0x7f0000ff));
    });

    test('Parses nested elements', () {
      const xmlString = '''
      <Container padding="40">
        <Text value="Welcome {user.name}" />
      </Container>
      ''';

      final result = parser.parseXml(xmlString, debug: true);
      expect(result['tag'], 'Container');
      expect(result['attributes']['padding'], '40');
      expect(result['children'].length, 1);

      final textChild = result['children'][0];
      expect(textChild['tag'], 'Text');
      expect(textChild['attributes']['value'], 'Welcome John Doe');
    });

    test('Handles unsupported member expressions gracefully', () {
      const xmlString = '<Container unsupported="{some.unknown.value}" />';
      expect(
        () => parser.parseXml(xmlString, debug: true),
        throwsA(isA<Exception>()),
      );
    });

    test('Throws error for invalid color methods', () {
      const xmlString = '<Container color="{Color.invalidMethod()}" />';
      expect(
        () => parser.parseXml(xmlString, debug: true),
        throwsA(isA<Exception>()),
      );
    });

    test('Handles interpolated strings with mixed dynamic values', () {
      const xmlString =
          '<Text value="User: {user.name}, Status: {isLoggedIn ? \'Online\' : \'Offline\'}" />';
      final result = parser.parseXml(xmlString, debug: true);
      expect(result['attributes']['value'], 'User: John Doe, Status: Online');

      // Update the context to change the ternary result
      context['isLoggedIn'] = false;
      final resultOffline = parser.parseXml(xmlString, debug: true);
      expect(
        resultOffline['attributes']['value'],
        'User: John Doe, Status: Offline',
      );
    });
  });
}
