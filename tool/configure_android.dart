import 'dart:io';

/// Configure the generated Android runner without editing dependency caches.
/// Run from any directory: dart tool/configure_android.dart
void main() {
  final root = File.fromUri(Platform.script).parent.parent;
  final android = Directory('${root.path}/android');
  final settings = File('${android.path}/settings.gradle.kts');
  final properties = File('${android.path}/gradle.properties');
  final app = File('${android.path}/app/build.gradle.kts');
  if (!settings.existsSync() || !properties.existsSync() || !app.existsSync()) {
    stderr.writeln('Generate Android first with flutter create --no-pub '
        '--platforms=android --org ca.youju --project-name youju_ai .');
    exitCode = 1;
    return;
  }

  final agp = RegExp(
    r'''id\s*\(\s*["']com\.android\.application["']\s*\)\s*version\s*["'](\d+)\.''',
  ).firstMatch(settings.readAsStringSync());
  if (agp == null) {
    stderr.writeln('Cannot determine Android Gradle Plugin version. '
        'No configuration changed; see docs/APP_TESTING.md.');
    exitCode = 1;
    return;
  }
  if (int.parse(agp.group(1)!) < 9) {
    stdout.writeln('AGP < 9: keeping legacy Kotlin configuration.');
    return;
  }

  // Applying legacy KGP together with AGP 9 built-in Kotlin is incompatible.
  // Refuse to rewrite an older/custom app file: the developer must review it.
  final legacyPlugin = RegExp(
    r'''^\s*id\s*\(\s*["'](?:org\.jetbrains\.kotlin\.android|kotlin-android)["']\s*\)''',
    multiLine: true,
  );
  if (legacyPlugin.hasMatch(app.readAsStringSync())) {
    stderr.writeln('The app applies legacy Kotlin. Review the plugins block '
        'before enabling built-in Kotlin; see docs/APP_TESTING.md. '
        'No configuration changed.');
    exitCode = 1;
    return;
  }

  final original = properties.readAsStringSync();
  final newline = original.contains('\r\n') ? '\r\n' : '\n';
  final flag = RegExp(
    r'^[ \t]*android\.builtInKotlin[ \t]*[=:][^\r\n]*',
    multiLine: true,
  );
  final updated = flag.hasMatch(original)
      ? original.replaceAll(flag, 'android.builtInKotlin=true')
      : '$original${original.isEmpty || original.endsWith('\n') ? '' : newline}'
          '# Youju: Mapbox 3.34.1 uses built-in Kotlin on AGP 9+.$newline'
          'android.builtInKotlin=true$newline';
  if (updated != original) properties.writeAsStringSync(updated);
  stdout.writeln('Android: built-in Kotlin enabled for AGP 9 / Mapbox. '
      'Other properties, including android.newDsl, were preserved.');
}
