flutter build apk --release --flavor admin -t lib/admin_main.dart

Copy-Item `
  -LiteralPath "build\app\outputs\flutter-apk\app-admin-release.apk" `
  -Destination "build\app\outputs\flutter-apk\zyromart-admin.apk" `
  -Force
