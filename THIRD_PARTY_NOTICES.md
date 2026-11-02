# Third-Party Notices

邻传 / LANBridge  
Copyright 2026 纷染雪落  
Project license: [Apache License 2.0](LICENSE)

This file records the origin of protocol compatibility and the primary third-party components used by this project. It is an attribution summary, not a replacement for the complete license texts shipped with each component.

## LocalSend protocol compatibility

Protocol behavior used for interoperability includes:

- UDP multicast group `224.0.0.167` and default port `53317`
- HTTP(S) endpoints under `/api/localsend/v2/`
- Device registration and discovery JSON fields
- File preparation, upload, and cancellation flow

Reference project:

- LocalSend: <https://github.com/localsend/localsend>
- Website: <https://localsend.org/>
- License: Apache License 2.0

The LocalSend name is used descriptively to identify protocol compatibility. 邻传 is not affiliated with, endorsed by, or sponsored by the LocalSend project or its maintainers. No LocalSend logo or branded artwork is included.

If LocalSend source code is incorporated in the future, the corresponding Apache-2.0 license and attribution notices must be preserved, and this file must be updated.

## Flutter and Dart packages

This project is built with Flutter. Flutter and the Flutter engine are distributed under the BSD 3-Clause License; copyright belongs to the Flutter Authors.

Primary direct dependencies:

| Component | Version | License | Copyright / upstream |
| --- | --- | --- | --- |
| Flutter SDK | 3.35.x | BSD-3-Clause | The Flutter Authors |
| file_picker | 11.0.3 | MIT | Miguel Ruivo |
| desktop_drop | 0.6.1 | Apache-2.0 | desktop_drop contributors |
| path_provider | 2.1.5 | BSD-3-Clause | The Flutter Authors |
| crypto | 3.0.8 | BSD-3-Clause | Dart project authors |
| basic_utils | 5.7.0 | MIT | Ephenodrom |
| mime | 2.1.0 | BSD-3-Clause | Dart project authors |
| uuid | 4.6.0 | MIT | Yulian Kuncheff |
| path | 1.9.1 | BSD-3-Clause | Dart project authors |
| cupertino_icons | 1.0.9 | MIT | Vladimir Kharlampidi |
| flutter_lints | 5.0.0 | BSD-3-Clause | The Flutter Authors |

`flutter_lints` is a development dependency and is not part of the application runtime.

Transitive Dart and Flutter dependencies are listed in `pubspec.lock`. Their license texts are included in the Flutter dependency cache and in the generated `NOTICES.Z` asset of the Flutter application.

## HarmonyOS components

The OpenHarmony Flutter runtime used by the HarmonyOS build is distributed under the Apache License 2.0, including:

| Component | License | Notes |
| --- | --- | --- |
| `@ohos/flutter_ohos` | Apache-2.0 | OpenHarmony Flutter embedding |
| `flutter_native_arm64_v8a` | Apache-2.0 | Flutter native libraries for OHOS |
| `flutter_native_x86_64` | Apache-2.0 | Flutter native libraries for OHOS |
| `@ohos/hypium` | Apache-2.0 | HarmonyOS test framework, test-only |

The complete license texts are included with the HarmonyOS packages in the Flutter SDK and OHOS package cache.

## Full license texts

- Apache License 2.0: [LICENSE](LICENSE)
- Flutter's complete dependency notices: the generated `NOTICES.Z` asset included with the Flutter build
- Third-party Dart/Flutter packages: each package's `LICENSE` file in the Flutter pub cache
- HarmonyOS packages: each package's license file in the OHOS package cache

If you redistribute a built application, retain the applicable license texts and notices with the distribution.
