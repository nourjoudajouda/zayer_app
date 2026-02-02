# Android release APK build

## JDK 17 required

The Android build **does not work with JDK 25**. Kotlin/Gradle 8.14 fail with:

```text
java.lang.IllegalArgumentException: 25.0.1
  at org.jetbrains.kotlin.com.intellij.util.lang.JavaVersion.parse
```

You must use **JDK 17** to run the build.

### Option A: Use JDK 17 for this project only (recommended)

1. **Install JDK 17** (Temurin 17 LTS):  
   https://adoptium.net/temurin/releases/?version=17  
   Choose Windows x64, JDK 17, and install (e.g. to `C:\Program Files\Eclipse Adoptium\jdk-17.x.x.x-hotspot`).

2. **Point Gradle to JDK 17**  
   Edit `android/gradle.properties` and add (fix the path to match your install):

   ```properties
   org.gradle.java.home=C:\\Program Files\\Eclipse Adoptium\\jdk-17.0.13.11-hotspot
   ```

   Use your actual folder name (e.g. `jdk-17.0.12.7-hotspot`).

3. **Build:**

   ```bash
   cd D:\flutter_projects\zayer_app
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

### Option B: Use JAVA_HOME

1. Install JDK 17 as above.
2. Before building, set `JAVA_HOME` to the JDK 17 folder, then run the same `flutter build apk --release` from a new terminal.

---

## NDK (if build fails with "Failed to install NDK" or "NDK Clang could not be found")

The project uses NDK **27.0.12077973** (required by Flutter plugins; set in `android/app/build.gradle.kts`). If the build fails with an NDK install error or "Android NDK Clang could not be found":

**If you see "There is not enough space on the disk":**  
NDK is large (~1 GB+). Free at least **2 GB** on the drive where the Android SDK is installed (e.g. `D:\Android`), then install NDK again.

**Install NDK 27 manually:**

1. Open **Android Studio** → **Settings** → **Languages & Frameworks** → **Android SDK** → **SDK Tools**.
2. Check **Show Package Details**.
3. Under **NDK (Side by side)**, check **27.0.12077973**.
4. Click **Apply** to install, then run `flutter build apk --release` again.

**Or from command line** (after freeing disk space):

```bash
D:\Android\cmdline-tools\latest\bin\sdkmanager.bat --install "ndk;27.0.12077973"
```

**If you see "Android NDK Clang could not be found":**  
Install NDK 27 as above (plugins require 27, not 26). If NDK was partially downloaded, delete the folder `D:\Android\ndk\27.0.12077973` and reinstall.

---

## Output

On success, the APK is at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Install on phone

1. Copy `app-release.apk` to the phone (USB, cloud, etc.).
2. Enable **Install unknown apps** for the app you use to open the file (e.g. Files, Chrome).
3. Open the APK and tap **Install**.
