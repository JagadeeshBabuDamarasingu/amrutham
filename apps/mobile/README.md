# amrutham

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

## Google Drive backup setup

Drive backup needs an OAuth client that only you can create:

1. In Google Cloud Console, create a project and enable the **Google Drive API**.
2. Configure the OAuth consent screen and add the scope `.../auth/drive.appdata`.
3. Create an **OAuth client ID** of type *Android* with the app's package name
   and the SHA-1 of the signing key (debug: `cd android && ./gradlew signingReport`;
   release: your upload and Play App Signing keys).
4. Create a second **Web application** client. Its ID is `_webClientId` in
   `lib/backup/drive_backup.dart`, passed to `GoogleSignIn` as `serverClientId`.
