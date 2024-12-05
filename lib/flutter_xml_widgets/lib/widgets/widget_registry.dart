import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

typedef WidgetBuilderFunction = Widget Function({
  required Map<String, dynamic> props,
  required Map<String, dynamic> context,
  required List<XmlElement> rawChildren,
  required List<Widget> children,
});

class _WidgetDefinition {
  final WidgetBuilderFunction builder;
  final Map<String, PropConfig> propConfigs;

  _WidgetDefinition(this.builder, this.propConfigs);
}

class PropConfig {
  final PropTransformer? transformer;
  final Type? type;
  final Type? preTransformType;

  PropConfig({this.transformer, this.type, this.preTransformType});
}

typedef PropTransformer = dynamic Function(dynamic value);

class WidgetRegistry {
  static final Map<String, _WidgetDefinition> _registry = {};

  static void register({
    required String tag,
    required WidgetBuilderFunction builder,
    Map<String, PropConfig>? propConfigs,
  }) {
    _registry[tag] = _WidgetDefinition(builder, propConfigs ?? {});
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
