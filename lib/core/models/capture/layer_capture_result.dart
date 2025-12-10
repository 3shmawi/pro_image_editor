import 'dart:typed_data';

import '../layers/layer.dart';

/// Represents the result of capturing a layer as an image.
///
/// This model associates a layer with its rendered image bytes,
/// keeping the concerns of layer data and rendering separate.
class LayerCaptureResult {
  /// Creates a new layer capture result.
  const LayerCaptureResult({
    required this.layer,
    required this.imageBytes,
    this.timestamp,
  });

  /// The layer that was captured.
  final Layer layer;

  /// The rendered image bytes of the layer.
  final Uint8List imageBytes;

  /// Optional timestamp when the capture was made (for timed layers).
  /// In milliseconds.
  final int? timestamp;

  /// Creates a copy of this result with the given fields replaced.
  LayerCaptureResult copyWith({
    Layer? layer,
    Uint8List? imageBytes,
    int? timestamp,
  }) {
    return LayerCaptureResult(
      layer: layer ?? this.layer,
      imageBytes: imageBytes ?? this.imageBytes,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LayerCaptureResult &&
        other.layer.id == layer.id &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => layer.id.hashCode ^ timestamp.hashCode;
}

/// Represents a collection of layer capture results.
///
/// This is useful for batch operations where multiple layers
/// are captured at once.
class LayerCaptureCollection {
  /// Creates a new layer capture collection.
  const LayerCaptureCollection({
    required this.results,
    this.backgroundImage,
  });

  /// The list of captured layer results.
  final List<LayerCaptureResult> results;

  /// Optional background image bytes.
  final Uint8List? backgroundImage;

  /// Gets a capture result by layer ID.
  LayerCaptureResult? getByLayerId(String layerId) {
    try {
      return results.firstWhere((result) => result.layer.id == layerId);
    } catch (e) {
      return null;
    }
  }

  /// Gets all capture results for a specific timestamp.
  /// Useful for timed layers.
  List<LayerCaptureResult> getByTimestamp(int timestamp) {
    return results.where((result) => result.timestamp == timestamp).toList();
  }

  /// Converts the collection to a map of layer ID to image bytes.
  Map<String, Uint8List> toMap() {
    final map = <String, Uint8List>{};

    if (backgroundImage != null) {
      map['background'] = backgroundImage!;
    }

    for (final result in results) {
      map[result.layer.id] = result.imageBytes;
    }

    return map;
  }

  /// Creates a collection from a map of layer ID to image bytes.
  factory LayerCaptureCollection.fromMap(
    Map<String, Uint8List> map,
    List<Layer> layers,
  ) {
    final results = <LayerCaptureResult>[];
    Uint8List? background;

    for (final entry in map.entries) {
      if (entry.key == 'background') {
        background = entry.value;
        continue;
      }

      final layer = layers.firstWhere(
        (l) => l.id == entry.key,
        orElse: () => throw Exception('Layer not found: ${entry.key}'),
      );

      results.add(LayerCaptureResult(
        layer: layer,
        imageBytes: entry.value,
      ));
    }

    return LayerCaptureCollection(
      results: results,
      backgroundImage: background,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LayerCaptureCollection &&
        other.results.length == results.length;
  }

  @override
  int get hashCode => results.length.hashCode;
}
