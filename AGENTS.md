# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains the Flutter app. Most features live under `lib/pages/<feature>/` with paired `view.dart` and `controller.dart` files using GetX. Shared UI sits in `lib/common/`, API clients in `lib/http/`, app services in `lib/services/`, helpers in `lib/utils/`, and data models in `lib/models/` plus `lib/models_new/`. Media player code lives in `lib/plugin/pl_player/`. Generated protobuf files are under `lib/grpc/`; treat them as generated code.

Assets live in `assets/images/`, `assets/fonts/`, and `assets/shaders/`. Platform runners are in `android/`, `ios/`, `linux/`, `macos/`, `web/`, and `windows/`. CI release workflows are in `.github/workflows/`. Tests currently live in `test/`.

## Build, Test, and Development Commands
- `flutter pub get` installs dependencies.
- `flutter run -d windows` starts a local desktop build; swap the device target as needed.
- `flutter analyze` runs the Dart analyzer with the repo lint set.
- `dart format lib test` applies standard formatting before review.
- `flutter test` runs the current widget/unit test suite.
- `dart run build_runner build --delete-conflicting-outputs` regenerates Hive adapters after changing `@HiveType` models.
- `dart lib/scripts/build.dart` refreshes `lib/build_config.dart`; CI runs this before release builds.

Use the Flutter version pinned in `pubspec.yaml` (`3.41.5`) when possible.

## Coding Style & Naming Conventions
Follow standard Dart style: 2-space indentation, trailing commas where formatting benefits, and small focused files. Prefer `package:PiliPlus/...` imports; `analysis_options.yaml` explicitly disallows relative imports and requires declared return types. Use `UpperCamelCase` for types, `lowerCamelCase` for members, and `snake_case.dart` for filenames.

Keep new feature code alongside its page folder, and add local `widgets/` subfolders instead of growing shared directories prematurely. Do not hand-edit generated `lib/grpc/**`, `*.g.dart`, or `lib/build_config.dart` outputs.

## Testing Guidelines
Place tests in `test/` and name them `*_test.dart`. Add regression tests for new controllers, widgets, or startup behavior. The repo currently only has a basic Flutter smoke test, so new feature work should improve coverage in the touched area rather than rely on the existing baseline.

## Commit & Pull Request Guidelines
Recent commits use short, imperative subjects with lightweight prefixes such as `feat:`, `fix`, `docs:`, `opt`, and `refa:`. Follow that pattern and keep each commit scoped to one change.

PRs should explain the user-visible impact, list platforms affected, and include the commands you ran (for example, `flutter analyze` and `flutter test`). Add screenshots or recordings for UI changes and link related issues or upstream references when relevant.

## Progress Logging
每次修改完代码后，在 `progress.md` 中进行记录，至少包含：起因、操作、结果。
