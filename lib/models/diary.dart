class Diary {
  const Diary({
    required this.id,
    required this.content,
    this.moodWeather,
    this.images = const [],
    required this.createdAt,
    this.aiKeywords = const [],
    this.aiSummary = '',
    this.isFavorite = false,
    this.inDriftBottle = false,
    this.latitude,
    this.longitude,
    this.placeLabel,
  });

  final String id;
  final String content;
  final String? moodWeather;
  final List<String> images;
  final DateTime createdAt;
  final List<String> aiKeywords;
  final String aiSummary;
  final bool isFavorite;
  final bool inDriftBottle;
  final double? latitude;
  final double? longitude;
  final String? placeLabel;

  bool get hasImages => images.isNotEmpty;
  bool get hasAiInsight => aiSummary.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;

  String get previewLine {
    final line = content.replaceAll('\n', ' ').trim();
    if (line.length <= 80) return line;
    return '${line.substring(0, 80)}…';
  }

  Diary copyWith({
    String? content,
    String? moodWeather,
    List<String>? images,
    DateTime? createdAt,
    List<String>? aiKeywords,
    String? aiSummary,
    bool? isFavorite,
    bool? inDriftBottle,
    double? latitude,
    double? longitude,
    String? placeLabel,
    bool clearLocation = false,
  }) {
    return Diary(
      id: id,
      content: content ?? this.content,
      moodWeather: moodWeather ?? this.moodWeather,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      aiKeywords: aiKeywords ?? this.aiKeywords,
      aiSummary: aiSummary ?? this.aiSummary,
      isFavorite: isFavorite ?? this.isFavorite,
      inDriftBottle: inDriftBottle ?? this.inDriftBottle,
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      placeLabel: clearLocation ? null : (placeLabel ?? this.placeLabel),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'moodWeather': moodWeather,
        'images': images,
        'createdAt': createdAt.toIso8601String(),
        'aiKeywords': aiKeywords,
        'aiSummary': aiSummary,
        'isFavorite': isFavorite,
        'inDriftBottle': inDriftBottle,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (placeLabel != null) 'placeLabel': placeLabel,
      };

  factory Diary.fromMap(Map<dynamic, dynamic> map) {
    return Diary(
      id: map['id'] as String,
      content: map['content'] as String? ?? '',
      moodWeather: map['moodWeather'] as String?,
      images: (map['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: DateTime.parse(map['createdAt'] as String),
      aiKeywords: (map['aiKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      aiSummary: map['aiSummary'] as String? ?? '',
      isFavorite: map['isFavorite'] as bool? ?? false,
      inDriftBottle: map['inDriftBottle'] as bool? ?? false,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      placeLabel: map['placeLabel'] as String?,
    );
  }
}
