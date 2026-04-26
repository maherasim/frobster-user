// Resizes Persotel logo for Android notification small icon (all densities).
// Run after: dart pub get
// Usage: dart run tool/generate_notification_icons.dart

import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const source = 'assets/branding/persotel_app_icon.png';
  final file = File(source);
  if (!file.existsSync()) {
    stderr.writeln('Missing $source — copy branding asset first.');
    exit(1);
  }

  final decoded = img.decodeImage(file.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Could not decode $source');
    exit(1);
  }

  // dp-based notification icon sizes (baseline mdpi = 24px).
  final sizes = <String, int>{
    'android/app/src/main/res/drawable-mdpi': 24,
    'android/app/src/main/res/drawable-hdpi': 36,
    'android/app/src/main/res/drawable-xhdpi': 48,
    'android/app/src/main/res/drawable-xxhdpi': 72,
    'android/app/src/main/res/drawable-xxxhdpi': 96,
  };

  for (final e in sizes.entries) {
    final dir = Directory(e.key);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final resized = img.copyResize(
      decoded,
      width: e.value,
      height: e.value,
      interpolation: img.Interpolation.average,
    );
    final out = File('${e.key}/ic_stat_ic_notification.png');
    out.writeAsBytesSync(img.encodePng(resized));
    stdout.writeln('Wrote ${out.path}');
  }

  // In-app notification list icons (Flutter assets).
  for (final name in ['ic_notification.png', 'ic_notification_user.png']) {
    final target = File('assets/icons/$name');
    final listIcon = img.copyResize(
      decoded,
      width: 96,
      height: 96,
      interpolation: img.Interpolation.average,
    );
    target.writeAsBytesSync(img.encodePng(listIcon));
    stdout.writeln('Wrote ${target.path}');
  }

  stdout.writeln('Done.');
}
