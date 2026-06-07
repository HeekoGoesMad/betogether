# BeTogether — Development & Troubleshooting History

This log documents the major build, compilation, and database setup issues encountered during the development of BeTogether Phase 1, along with their solutions.

---

## 1. Kotlin Incremental Compilation (Cross-Drive Windows Bug)
* **Symptom**: Android APK builds failed with a Kotlin compiler exception (`RelocatableFileToPathConverter` crash).
* **Cause**: The project was located on the `D:` drive (`D:\Job Related\...`), while the Flutter/Pub Cache resided on the `C:` drive (`C:\Users\...`). The Kotlin compiler tried to calculate a relative path between drives, which is mathematically impossible on Windows.
* **Resolution**: Added `kotlin.incremental=false` to [gradle.properties](file:///d:/Job%20Related/Portfolio/BeTogether/code/BeTogether%20App%20Code/betogether/android/gradle.properties). This bypasses the relative path computation bug.

---

## 2. Space-in-Path Script Breakdown
* **Symptom**: Native asset builds failed (e.g. for `objective_c`) with the error `'D:\Job' is not recognized as an internal or external command`.
* **Cause**: The SDK path configured in `local.properties` was `D:\Job Related\Portfolio\BeTogether\code\flutter`. The space character in `Job Related` caused Windows command processors to break the path into two separate arguments when calling the Dart compiler.
* **Resolution**: Updated `flutter.sdk` in [local.properties](file:///d:/Job%20Related/Portfolio/BeTogether/code/BeTogether%20App%20Code/betogether/android/local.properties) to `C:\flutter` (an identical Flutter version installation on the `C:` drive that contains no spaces).

---

## 3. Windows Desktop Symlink Check Failure
* **Symptom**: `flutter pub get` failed with `Building with plugins requires symlink support. Please enable Developer Mode...`
* **Cause**: Flutter had Windows desktop target support enabled by default. Because Windows Developer Mode was disabled on the host machine, Flutter could not create the required symlinks.
* **Resolution**: Ran `flutter config --no-enable-windows-desktop --no-enable-linux-desktop --no-enable-macos-desktop` to globally disable unused desktop targets, since BeTogether is a mobile-only application.

---

## 4. Google Sign-In Client & SHA Certificate Mismatch
* **Symptom**: Google Sign-In failed or terminated the app session.
* **Cause**:
  1. The app's local debug keystore SHA-1 and SHA-256 fingerprints were not registered in the Firebase console app settings.
  2. The local `google-services.json` inside the `android/app/` folder was outdated and did not contain the corresponding OAuth client mapping configurations.
* **Resolution**:
  1. Ran `signingReport` to extract local hashes and registered both fingerprints in the Firebase Console via the Firebase API.
  2. Overwrote [android/app/google-services.json](file:///d:/Job%20Related/Portfolio/BeTogether/code/BeTogether%20App%20Code/betogether/android/app/google-services.json) with the updated version from the console.
  3. Rebuilt the application cleanly to compile the new resource configs.

---

## 5. Circular Gradle Build Directory Reference
* **Symptom**: Gradle compilation failed with a `Circular evaluation detected` error on `id: 'dev.flutter.flutter-gradle-plugin'`.
* **Cause**: The build redirection rules in `build.gradle.kts` recursively evaluated `rootProject.layout.buildDirectory` against itself.
* **Resolution**: Changed the build directory redirection configuration in [build.gradle.kts](file:///d:/Job%20Related/Portfolio/BeTogether/code/BeTogether%20App%20Code/betogether/android/build.gradle.kts) to use `projectDirectory.dir("../build")` which statically resolves the path.

---

## 6. Firestore & Storage Permission/Configuration Blocks
* **Symptom**:
  * Write failures to `/users` with `PERMISSION_DENIED`.
  * Upload photo failures with `StorageException: Object does not exist (404)`.
* **Cause**:
  1. The `(default)` Firestore Database and Firebase Storage buckets were not initialized in the Firebase Console.
  2. Firestore rules defaulted to blocking writes.
  3. Firebase's updated Spark (Free) plan blocks new Storage bucket creation without a credit card upgrade to the Blaze plan.
* **Resolution**:
  1. Initialized the Firestore Database in the console.
  2. Updated Firestore security rules to allow reading and writing user profile directories.
  3. Migrated profile photo storage to **Base64 encoding** stored directly inside the user's Firestore document. This bypasses the need for Firebase Storage entirely, ensuring it is 100% free with no paywalls.
