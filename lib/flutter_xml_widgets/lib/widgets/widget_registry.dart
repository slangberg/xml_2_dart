import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:xml_to_dart/flutter_xml_widgets/lib/utils/exceptions.dart';

typedef WidgetBuilderFunction = Widget Function({
  required Map<String, dynamic> props,
  required Map<String, dynamic> context,
  required List<XmlElement> rawChildren,
  required List<Widget> children,
});

class WidgetDefinition {
  final WidgetBuilderFunction builder;
  final Map<String, PropConfig> propConfigs;
  final bool validateProps;
  final bool parseChildren;
  final String tag;

  WidgetDefinition(this.tag, this.builder, this.propConfigs, this.validateProps,
      this.parseChildren);
}

class PropConfig {
  final PropTransformer? transformer;
  final Type? type;
  final Type? preTransformType;
  final dynamic? defaultValue;
  final Map<String, dynamic>? metadata;

  PropConfig(
      {this.transformer,
      this.type,
      this.preTransformType,
      this.defaultValue,
      this.metadata});
}

typedef PropTransformer = dynamic Function(dynamic value);

class WidgetRegistry {
  static final Map<String, WidgetDefinition> _registry = {};

  static void register({
    required String tag,
    required WidgetBuilderFunction builder,
    Map<String, PropConfig>? propConfigs,
    bool validateProps = true,
    bool parseChildren = true,
  }) {
    _registry[tag] = WidgetDefinition(
        tag, builder, propConfigs ?? {}, validateProps, parseChildren);
  }

  static WidgetBuilderFunction? getBuilder(String tag) {
    return _registry[tag]?.builder;
  }

  static Map<String, PropTransformer>? getTransformers(String tag) {
    final propConfigs = _registry[tag]?.propConfigs;
    if (propConfigs == null) return null;

    final transformers = <String, PropTransformer>{};
    for (var entry in propConfigs.entries) {
      if (entry.value.transformer != null) {
        transformers[entry.key] = entry.value.transformer!;
      }
    }
    return transformers;
  }

  static WidgetDefinition getWidgetConfig(String tagName) {
    final definition = _registry[tagName];
    if (definition == null) {
      throw UnknownWidgetException(tagName);
    }
    return definition;
  }

  static void clearDirectory() {
    _registry.clear();
  }

  static bool validateProps(
      String tag, Map<String, dynamic> props, bool preCheck) {
    for (var key in props.keys) {
      final value = props[key];
      validateSingleProp(tag, key, value, preCheck);
    }
    return true;
  }

  static bool validateSingleProp(
      String tag, String key, dynamic value, bool preCheck) {
    final propConfigs = _registry[tag]?.propConfigs;
    if (propConfigs == null) return true;
    final config = propConfigs[key];
    final check = preCheck ? config?.preTransformType : config?.type;
    if (config != null && value.runtimeType != check) {
      throw Exception(
          'Invalid $tag prop: $key ${preCheck ? '(Raw)' : '(Transformed)'} -  ${value.runtimeType} not ${check}');
    }

    return true;
  }
}
