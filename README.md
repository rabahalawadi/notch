# NotchIsland for iPhone 11 (Unsigned IPA via GitHub Actions)

An interactive Dynamic Island-style notch utility built specifically for the **iPhone 11** (`414×896 pt` viewport, `209×30 pt` physical notch) that works on the **latest iOS update (iOS 26.2+ / iOS 27)** without jailbreak or patched `MobileGestalt` exploits.

## Features
1. **Interactive Notch Wrapper (In-App / Standby Desk Mode)**:
   - Wraps around the physical iPhone 11 notch at `y = 0` with compact status wings on the left and right of the speaker/Face ID housing.
   - Tap or swipe down on the notch to expand into a full Dynamic Island card with **Music / Apple Music Controls**, **Live Countdown Timer**, **Battery & Storage HUD**, and **Clipboard Shelf**.
2. **Floating Home Screen Island (`AVPictureInPictureController`)**:
   - Because Apple patched `MobileGestalt` / `BookRestore` in iOS 26.2+ and iOS 27, standard apps are sandboxed. `NotchIsland` uses a live `AVSampleBufferDisplayLayer` Picture-in-Picture feed to pop out a floating black Dynamic Island pill that stays visible over your iOS Home Screen and other apps.

## How to Build the `.ipa` Without a Mac (Free via GitHub Actions)
1. Create a free account at [GitHub](https://github.com) and create a **New Repository** (public makes GitHub Actions minutes completely free and unlimited).
2. Upload all files from this folder (making sure the `.github/workflows/build-ipa.yml` folder is included).
3. Click the **Actions** tab in your GitHub repository.
4. Select **Build Unsigned iOS IPA (No Mac Required)** and click **Run workflow** (it also runs automatically on every upload/push).
5. Wait ~2 minutes for GitHub's cloud `macos-latest` server to compile the Swift project using [XcodeGen](https://github.com/yonaskolb/xcodegen) and `xcodebuild`.
6. Scroll to the bottom of the completed workflow run and download **`NotchIsland-Unsigned-IPA`** (unzip it to get `NotchIsland-Unsigned.ipa`).

## How to Sideload the `.ipa` on Your iPhone 11
- **With [Sideloadly](https://sideloadly.io/) (Windows / Linux / Web)**:
  1. Open Sideloadly, connect your iPhone 11, and drag `NotchIsland-Unsigned.ipa` into the window.
  2. Enter your Apple ID and click **Start**.
  3. On your iPhone 11, go to **Settings → General → VPN & Device Management** to trust your developer certificate, and enable **Developer Mode** under **Settings → Privacy & Security → Developer Mode**.
- **With [SideStore](https://sidestore.io/)**:
  1. Open the SideStore app on your iPhone 11, tap `+`, and select `NotchIsland-Unsigned.ipa` to install and refresh directly on-device.
