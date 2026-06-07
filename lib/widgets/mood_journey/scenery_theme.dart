import 'dart:ui';

import '../../models/mood_journey.dart';

/// 一段沿途风景的配色与氛围参数（用于绘制与段间过渡）。
class SceneryTheme {
  const SceneryTheme({
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.hill,
    required this.ground,
    required this.roadDryTop,
    required this.roadDryBottom,
    required this.roadWetTop,
    required this.roadWetBottom,
    required this.wet,
    required this.flooded,
    required this.sunAlpha,
    required this.cloudDensity,
    required this.rainIntensity,
    required this.rainbowStrength,
    required this.flowerWarmth,
    required this.fog,
  });

  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;
  final Color hill;
  final Color ground;
  final Color roadDryTop;
  final Color roadDryBottom;
  final Color roadWetTop;
  final Color roadWetBottom;
  final double wet;
  final double flooded;
  final double sunAlpha;
  final double cloudDensity;
  final double rainIntensity;
  final double rainbowStrength;
  final double flowerWarmth;
  final double fog;

  static SceneryTheme forKind(MoodSceneryKind kind) => switch (kind) {
        MoodSceneryKind.sunny => const SceneryTheme(
              skyTop: Color(0xFF5B9BD5),
              skyMid: Color(0xFF8EC5EF),
              skyBottom: Color(0xFFD4E8F7),
              hill: Color(0xFF7BAE6A),
              ground: Color(0xFFE8D4A8),
              roadDryTop: Color(0xFF9A8B72),
              roadDryBottom: Color(0xFF6B5D48),
              roadWetTop: Color(0xFF8A7D68),
              roadWetBottom: Color(0xFF5E5240),
              wet: 0,
              flooded: 0,
              sunAlpha: 1,
              cloudDensity: 0.08,
              rainIntensity: 0,
              rainbowStrength: 0,
              flowerWarmth: 1,
              fog: 0,
            ),
        MoodSceneryKind.cloudy => const SceneryTheme(
              skyTop: Color(0xFF8FA4B8),
              skyMid: Color(0xFFB8C8D4),
              skyBottom: Color(0xFFDCE4EA),
              hill: Color(0xFF6F9468),
              ground: Color(0xFFAAC89A),
              roadDryTop: Color(0xFF8E8478),
              roadDryBottom: Color(0xFF635A50),
              roadWetTop: Color(0xFF7A7268),
              roadWetBottom: Color(0xFF564E46),
              wet: 0.15,
              flooded: 0,
              sunAlpha: 0.42,
              cloudDensity: 0.72,
              rainIntensity: 0,
              rainbowStrength: 0,
              flowerWarmth: 0.35,
              fog: 0.08,
            ),
        MoodSceneryKind.lightRain => const SceneryTheme(
              skyTop: Color(0xFF6E8494),
              skyMid: Color(0xFF94A8B6),
              skyBottom: Color(0xFFBECBD4),
              hill: Color(0xFF4F6B62),
              ground: Color(0xFF7A9488),
              roadDryTop: Color(0xFF706860),
              roadDryBottom: Color(0xFF4A443E),
              roadWetTop: Color(0xFF625C56),
              roadWetBottom: Color(0xFF403C38),
              wet: 0.82,
              flooded: 0,
              sunAlpha: 0.08,
              cloudDensity: 0.88,
              rainIntensity: 0.55,
              rainbowStrength: 0,
              flowerWarmth: 0,
              fog: 0.18,
            ),
        MoodSceneryKind.heavyRain => const SceneryTheme(
              skyTop: Color(0xFF3A4852),
              skyMid: Color(0xFF4E5E6A),
              skyBottom: Color(0xFF687580),
              hill: Color(0xFF354248),
              ground: Color(0xFF4A5A62),
              roadDryTop: Color(0xFF524E4A),
              roadDryBottom: Color(0xFF2E2C28),
              roadWetTop: Color(0xFF454240),
              roadWetBottom: Color(0xFF282624),
              wet: 1,
              flooded: 0.75,
              sunAlpha: 0,
              cloudDensity: 1,
              rainIntensity: 1,
              rainbowStrength: 0,
              flowerWarmth: 0,
              fog: 0.32,
            ),
        MoodSceneryKind.rainbow => const SceneryTheme(
              skyTop: Color(0xFF4A9FD4),
              skyMid: Color(0xFF8FD0F0),
              skyBottom: Color(0xFFE8F4FA),
              hill: Color(0xFF5FA868),
              ground: Color(0xFF8FD49A),
              roadDryTop: Color(0xFF7A7268),
              roadDryBottom: Color(0xFF524A42),
              roadWetTop: Color(0xFF6A645C),
              roadWetBottom: Color(0xFF48423C),
              wet: 0.55,
              flooded: 0,
              sunAlpha: 0.78,
              cloudDensity: 0.35,
              rainIntensity: 0,
              rainbowStrength: 1,
              flowerWarmth: 0.65,
              fog: 0,
            ),
        MoodSceneryKind.empty => const SceneryTheme(
              skyTop: Color(0xFFC8C4BC),
              skyMid: Color(0xFFD8D4CC),
              skyBottom: Color(0xFFE8E4DC),
              hill: Color(0xFFAEAAA4),
              ground: Color(0xFFC0BCB4),
              roadDryTop: Color(0xFF9E9994),
              roadDryBottom: Color(0xFF787470),
              roadWetTop: Color(0xFF9E9994),
              roadWetBottom: Color(0xFF787470),
              wet: 0,
              flooded: 0,
              sunAlpha: 0,
              cloudDensity: 0,
              rainIntensity: 0,
              rainbowStrength: 0,
              flowerWarmth: 0,
              fog: 0,
            ),
      };

  static SceneryTheme lerp(SceneryTheme a, SceneryTheme b, double t) {
    final u = t.clamp(0.0, 1.0);
    return SceneryTheme(
      skyTop: Color.lerp(a.skyTop, b.skyTop, u)!,
      skyMid: Color.lerp(a.skyMid, b.skyMid, u)!,
      skyBottom: Color.lerp(a.skyBottom, b.skyBottom, u)!,
      hill: Color.lerp(a.hill, b.hill, u)!,
      ground: Color.lerp(a.ground, b.ground, u)!,
      roadDryTop: Color.lerp(a.roadDryTop, b.roadDryTop, u)!,
      roadDryBottom: Color.lerp(a.roadDryBottom, b.roadDryBottom, u)!,
      roadWetTop: Color.lerp(a.roadWetTop, b.roadWetTop, u)!,
      roadWetBottom: Color.lerp(a.roadWetBottom, b.roadWetBottom, u)!,
      wet: _lerpD(a.wet, b.wet, u),
      flooded: _lerpD(a.flooded, b.flooded, u),
      sunAlpha: _lerpD(a.sunAlpha, b.sunAlpha, u),
      cloudDensity: _lerpD(a.cloudDensity, b.cloudDensity, u),
      rainIntensity: _lerpD(a.rainIntensity, b.rainIntensity, u),
      rainbowStrength: _lerpD(a.rainbowStrength, b.rainbowStrength, u),
      flowerWarmth: _lerpD(a.flowerWarmth, b.flowerWarmth, u),
      fog: _lerpD(a.fog, b.fog, u),
    );
  }

  static double _lerpD(double a, double b, double t) => a + (b - a) * t;
}
