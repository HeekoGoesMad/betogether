# BeTogether — Phase 1 Progress Tracker & Portfolio Guide

This file tracks the implementation milestones completed during Phase 1, outlines the codebase structure, and details the roadmap for Phase 2.

---

## 🚀 Phase 1 Milestones (Completed & Verified)

- **[x] Google & Email Authentication**
  - Fully integrated Firebase Auth supporting Email/Password sign-up/sign-in.
  - Active Google Sign-In verification completed.
  - Custom brand-styled login buttons.
- **[x] Profile Setup Flow**
  - **Step 1 (Name Input)**: Lexend Deca input screen with name validator.
  - **Step 2 (Birthday Input)**: Automated MM/DD/YYYY transition fields.
  - **Step 3 (Profile Picture)**: Gallery photo picker. Converts photo to compressed Base64 string data URI.
- **[x] Database Integration**
  - Save profile datasets (UID, name, birthday, photoBase64) to Firestore `users` collection.
- **[x] UI Polish & Accessibility**
  - Fixed white-on-white text readability issues inside inputs.
  - Styled next/finish buttons with high-contrast readable brand colors.
- **[x] Security Hardening**
  - Applied user-specific collection rules on Firestore to prevent global data leaks.
- **[x] Verification**
  - Verified full onboarding flow on Android `Pixel_10_Pro` (API 37) Emulator.

---

## 📁 Codebase Directory Walkthrough

Below are the key files built during Phase 1:

```
lib/
 ├── core/
 │    ├── constants/
 │    │    ├── app_colors.dart         # Hex codes for brand colors (cyan/pink)
 │    │    └── app_strings.dart        # Static user-facing copy
 │    ├── theme/
 │    │    └── app_theme.dart          # M3 Lexend Deca theme
 │    └── routes/
 │         └── app_router.dart         # GoRouter path definitions
 ├── shared/
 │    └── widgets/
 │         ├── gradient_button.dart    # Custom action buttons
 │         ├── gradient_background.dart# Splash/Auth background layouts
 │         └── social_sign_in_button.dart # Google/Facebook OAuth buttons
 ├── features/
 │    ├── splash/
 │    │    └── splash_screen.dart      # Logo intro with auth state check
 │    ├── auth/
 │    │    ├── auth_screen.dart        # Email & OAuth auth hub
 │    │    └── auth_controller.dart    # Auth state handlers
 │    ├── profile_setup/
 │    │    ├── setup_name_screen.dart  # Onboarding Step 1
 │    │    ├── setup_birthday_screen.dart # Onboarding Step 2
 │    │    ├── setup_photo_screen.dart # Onboarding Step 3 (Base64)
 │    │    └── profile_setup_controller.dart # Base64 encoder & Firestore saver
 │    └── home/
 │         └── home_screen.dart        # Phase 2 map placeholder
 └── main.dart                         # Initializer (Portrait lock, Firebase boot)
```

---

## 🗺️ Next Steps (Phase 2 Roadmap)

When you are ready to expand the app for your tour, here is the technical roadmap for Phase 2:

1. **Google Maps Integration**
   * Integrate the `google_maps_flutter` package.
   * Configure Android & iOS Google Maps SDK API Keys.
   * Render custom-styled maps (Zenly-style dark or colorful styling).
2. **Real-time Location Tracking**
   * Integrate `geolocator` to track live user coordinates.
   * Sync coordinates automatically to Firestore `users/${uid}/location` using background workers.
3. **Social Connections (Friends System)**
   * Add a searchable database for adding friends by username.
   * Implement Firestore-triggered Friend Requests (`pending`/`accepted` relations).
   * Render friends as custom avatar markers directly on the map.
4. **Push Notifications**
   * Integrate Firebase Cloud Messaging (FCM) to trigger alerts when friends ping you or arrive nearby.
