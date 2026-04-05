flutter build apk --release -t lib/admin_main.dart

Copy-Item `
  -LiteralPath "build\app\outputs\flutter-apk\app-release.apk" `
  -Destination "build\app\outputs\flutter-apk\zyromart-admin.apk" `
  -Force
