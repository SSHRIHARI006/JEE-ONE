# jivan_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running On A Physical Phone

When running on a real Android phone, set the backend URL to your laptop's LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://<YOUR_LAPTOP_LAN_IP>:8000
```

Example:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

Notes:

- Keep phone and laptop on the same Wi-Fi network.
- Start Django backend on `0.0.0.0:8000` so phone can reach it.
- Android cleartext HTTP is enabled for development in `AndroidManifest.xml`.
