# Repository Guidelines

## Project Structure & Module Organization

Application code lives in `lib/`. Keep cross-cutting infrastructure under `lib/core/` (routing, themes, API clients, and authentication storage), JSON/domain objects under `lib/models/`, state in `lib/providers/`, backend integrations in `lib/services/`, and UI in `lib/screens/`. Role-specific screens belong in `screens/admin/`, `screens/merchant/`, or `screens/driver/`; shared components should go in `lib/widgets/`. Tests live in `test/`. Platform projects are under `android/`, `ios/`, `web/`, `windows/`, `macos/`, and `linux/`. Do not commit generated `build/` or `.dart_tool/` content.

## Build, Test, and Development Commands

- `flutter pub get` — install dependencies from `pubspec.yaml`.
- `flutter run` — launch on a selected emulator or connected device.
- `flutter run -d chrome` — run the web target locally.
- `dart format lib test` — apply standard Dart formatting.
- `flutter analyze` — run the configured `flutter_lints` checks.
- `flutter test` — execute all widget and unit tests.
- `flutter build apk` or `flutter build web` — produce release artifacts for Android or web.

Run formatting, analysis, and tests before opening a pull request.

## Coding Style & Naming Conventions

Use two-space indentation and let `dart format` control layout. Name files with `snake_case.dart`, classes and widgets with `UpperCamelCase`, and methods, fields, and providers with `lowerCamelCase`. Prefer `const` widgets where possible. Keep widgets focused; split large screens into feature-local widgets instead of extending dashboard files. Avoid new raw `Map<String, dynamic>` contracts when a typed model or DTO is appropriate.

## Testing Guidelines

Tests use `flutter_test`. Name files `<feature>_test.dart` and group cases by behavior, such as authentication redirects, provider state transitions, and API-response parsing. Replace network and storage dependencies with fakes; tests must not call the production GoDelivery API. Add regression coverage for bug fixes and role-based navigation changes.

## Commit & Pull Request Guidelines

Recent history favors short imperative subjects, commonly using `feat:`. Continue with prefixes such as `feat:`, `fix:`, `refactor:`, `test:`, or `docs:` and keep each commit focused. Pull requests should explain the user-visible change, list validation performed, link related issues, and include screenshots or recordings for UI changes. Call out API contract, route, token-storage, or platform-configuration changes explicitly.

## Security & Configuration

Never commit credentials or access/refresh tokens. Keep backend URLs and environment-specific values centralized. Treat client-side role checks as navigation controls only; authorization must also be enforced by the Express backend.
