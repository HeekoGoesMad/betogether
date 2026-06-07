<div align="center">

# 📍 BeTogether

**Real-time social map app — See where your friends are, right now.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20FCM-FFCA28?logo=firebase)](https://firebase.google.com)
[![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://github.com/HeekoGoesMad/betogether/releases)
[![Release](https://img.shields.io/github/v/release/HeekoGoesMad/betogether)](https://github.com/HeekoGoesMad/betogether/releases/latest)

[**⬇️ Download Latest APK**](https://github.com/HeekoGoesMad/betogether/releases/download/v1.0.0/BeTogether-v1.0.0.apk)

</div>

---

## 🌟 What is BeTogether?

BeTogether is a real-time social location-sharing app built for Android using **Flutter** and **Firebase**. It lets you see your friends' live locations on an interactive map, receive push notifications when they're nearby, and share moments through Stories — all within a sleek, premium UI.

---

## ✅ Current Features (v1.0.0)

### 🔐 Authentication
- **Email / Password** sign-up and sign-in via Firebase Auth
- **Google Sign-In** one-tap OAuth flow
- Persistent session management with automatic redirect to onboarding or home

### 🧑 Profile Setup & Management
- Multi-step onboarding wizard: **Name → Birthday → Profile Photo**
- Profile photo picker — picks from gallery, compresses and uploads to **Cloudinary**
- Tap-to-change profile photo from the Profile screen with instant UI reload
- Displays friend count, birthday, email, and user ID on the profile card

### 🗺️ Live Map & Location Sharing
- Interactive map powered by **flutter_map** (OpenStreetMap tiles)
- Live GPS tracking with automatic location sync to **Firebase Realtime Database**
- Background GPS service continues tracking when app is minimized
- **Last online** indicator on friend map markers (e.g. "2m ago", "Online")

### 👥 Friends System
- Search users by username with case-insensitive prefix matching
- Send, accept, and reject friend requests
- Friend list with live presence status and location distance
- **Clickable location pin** on each friend row — taps auto-switch to the Map tab and fly the camera to that friend's position

### 📍 Map Collision Detection (Hang Out Together)
- **Greedy 25-meter clustering** groups users at the same location into **face piles** (stacked avatar bubbles with +N badge)
- **🔥 Friends Hanging Out**: When 2+ friends are in the same spot, a looping pulsing fire-glow animation with a "🔥 Hanging Out" badge appears
- **Strangers Nearby**: Non-friend collisions show a clean grey group pin
- **Interactive bottom sheet**: Tap any cluster to see who's there and jump to their Story

### 📸 Stories
- Upload photos or short videos as 24-hour Stories
- Story feed shows your friends' Stories with avatar rings
- Story viewer with tap-to-advance and swipe-to-dismiss

### 🔔 Push Notifications
- Firebase Cloud Messaging (FCM) integration
- Push alerts for new friend requests
- FCM HTTP v1 API dispatched via Google Service Account credentials

### 🛡️ Permission Onboarding
- Dedicated full-screen onboarding screens for **Location** and **Notification** permissions
- Sequential flow — users agree before being granted access, improving permission grant rate
- Silent permission re-check on every app start

### 🎨 UI & Design
- Premium dark-gradient design with brand cyan/pink palette
- **Lexend Deca** typography throughout
- Smooth micro-animations, hover states, and modal transitions
- Glassmorphism cards, pulsing online indicators, and custom bottom sheets

---

## 🗺️ Upcoming Features (Roadmap)

### 🔜 Coming Soon
| Feature | Description |
|---|---|
| 🏠 **Geofence Zones** | Set virtual zones (home, work, school) and get notified when friends enter or leave |
| 💬 **Direct Messaging** | In-app 1:1 chat with read receipts and typing indicators |
| 🧭 **Navigation to Friend** | One-tap navigation from the map to a friend's location |
| 📊 **Hangout History** | Weekly summary of where you and your friends hung out |
| 🎭 **Mood / Status** | Set a short emoji status visible on your map pin |
| 🔒 **Ghost Mode** | Hide your location from specific friends or go fully invisible |

### 🔮 Future Vision
| Feature | Description |
|---|---|
| 🍎 **iOS Release** | Full Apple App Store distribution |
| 🌐 **Web Companion** | View your friend map from a browser |
| 🤝 **Group Hangouts** | Create named group events with shared meeting points |
| 🏆 **Streaks & Achievements** | Gamification — consecutive hang-out streaks with friends |
| 🔗 **Deep Links** | Share your location as a link that opens directly in the app |

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x (Dart) |
| **Auth** | Firebase Authentication (Email + Google OAuth) |
| **Database** | Cloud Firestore (profiles, friends, stories) |
| **Realtime** | Firebase Realtime Database (live location coordinates) |
| **Storage** | Cloudinary (photo and video CDN) |
| **Notifications** | Firebase Cloud Messaging (FCM HTTP v1) |
| **Maps** | flutter_map + OpenStreetMap |
| **State** | Riverpod 2.x |
| **Navigation** | go_router |
| **Location** | geolocator + flutter_background_service |

---

## 📦 Installation

### Download APK (Android)
1. Download [**BeTogether-v1.0.0.apk**](https://github.com/HeekoGoesMad/betogether/releases/download/v1.0.0/BeTogether-v1.0.0.apk) from the Releases page
2. On your Android device, enable **Install from unknown sources** in Settings
3. Open the downloaded APK file and install
4. Launch **BeTogether** and sign up!

### Build from Source
```bash
# Clone the repository
git clone https://github.com/HeekoGoesMad/betogether.git
cd betogether

# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
```

> **Note**: You will need to supply your own `google-services.json`, Firebase credentials, and Cloudinary configuration to run the app from source. See `lib/core/constants/cloudinary_config.dart` and `lib/firebase_options.dart`.

---

## 📁 Project Structure

```
lib/
 ├── core/
 │    ├── constants/       # Colors, strings, Cloudinary config
 │    ├── routes/          # GoRouter path definitions
 │    ├── services/        # Firebase, Cloudinary, Location, Notification services
 │    └── theme/           # Material 3 app theme
 ├── features/
 │    ├── auth/            # Login & sign-up screens
 │    ├── friends/         # Friend list, requests, add friend
 │    ├── home/            # Tab navigation shell
 │    ├── map/             # Live map screen + location providers
 │    ├── permissions/     # Location & notification permission flows
 │    ├── profile/         # Profile view + photo editor
 │    ├── profile_setup/   # Onboarding wizard (name, birthday, photo)
 │    ├── splash/          # Launch screen + auth state check
 │    └── stories/         # Story feed, upload, viewer
 └── shared/
      ├── models/          # UserModel, StoryModel, FriendRequestModel
      └── widgets/         # Reusable UI components
```

---

## 🧪 Testing

```bash
# Run all unit tests (98 tests)
flutter test

# Run static analysis
flutter analyze
```

**Current status**: ✅ 98/98 tests passing | ✅ No analysis issues

---

<div align="center">
Made with ❤️ by <a href="https://github.com/HeekoGoesMad">HeekoGoesMad</a>
</div>
