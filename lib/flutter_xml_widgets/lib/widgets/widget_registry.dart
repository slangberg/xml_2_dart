import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

// typedef WidgetBuilderFunction = Widget Function(
//     Map<String, dynamic> props,
//     List<Widget> children,
//     Map<String, dynamic> context,
//     List<XmlElement> rawChildren);

typedef WidgetBuilderFunction = Widget Function(
    {required Map<String, dynamic> props,
    required Map<String, dynamic> context,
    required List<Widget> children,
    required List<XmlElement> rawChildren});

// typedef RawWidgetBuilderFunction = Widget Function(Map<String, dynamic> props,
//     List<XmlElement> children, Map<String, dynamic> context);

class WidgetRegistry {
  static final Map<String, _WidgetDefinition> _registry = {};

  /// Registers a widget with an optional map of property transformers
  static void register(
    String tag,
    WidgetBuilderFunction builder, [
    Map<String, PropTransformer>? propTransformers,
  ]) {
    _registry[tag] = _WidgetDefinition(builder, propTransformers ?? {});
  }

  /// Retrieves the builder and applies transformations
  static WidgetBuilderFunction? getBuilder(String tag) {
    return _registry[tag]?.builder;
  }

  /// Retrieves the prop transformers
  static Map<String, PropTransformer>? getTransformers(String tag) {
    return _registry[tag]?.propTransformers;
  }
}

class _WidgetDefinition {
  final WidgetBuilderFunction builder;
  final Map<String, PropTransformer> propTransformers;

  _WidgetDefinition(this.builder, this.propTransformers);
}

typedef PropTransformer = dynamic Function(dynamic value);
