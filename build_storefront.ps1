flutter build apk --release --flavor storefront -t lib/main.dart

Copy-Item `
  -LiteralPath "build\app\outputs\flutter-apk\app-storefront-release.apk" `
  -Destination "build\app\outputs\flutter-apk\zyromart-storefront.apk" `
  -Force
