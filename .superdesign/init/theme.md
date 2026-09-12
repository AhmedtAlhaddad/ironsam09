# Theme

## Compact token summary

- Framework: Flutter Material
- Current seed color: `Colors.deepPurple`
- Current generated scheme: `ColorScheme.fromSeed(seedColor: Colors.deepPurple)`
- Typography: default Material typography; no custom fonts
- Spacing: no project token scale; use a restrained 8px base for the redesign
- Radius: default Material component radii
- Shadows: default Material elevation
- Breakpoints: none defined; use mobile-first responsive layout with desktop expansion
- Direction: not yet configured; redesign requires `Directionality` / localized RTL support

## Raw source

### `pubspec.yaml` theme-related configuration

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

flutter:
  uses-material-design: true
```

### `lib/main.dart`

```dart
ThemeData(
  colorScheme: .fromSeed(seedColor: Colors.deepPurple),
)
```
