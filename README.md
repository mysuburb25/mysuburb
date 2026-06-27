# My Suburb — Flutter App

> **Your neighbourhood, connected.**

A suburb-based social network for Australian communities. Residents connect with neighbours, share updates, discover local events, buy and sell items, and stay informed.

---

## 📱 Screens Included

| # | Screen | Description |
|---|--------|-------------|
| 1 | Splash | Animated logo, auto-routes based on auth state |
| 2 | Login | Email/password + Google + Apple sign-in |
| 3 | Sign Up | Email registration with display name |
| 4 | Select Suburb | State + suburb search and selection |
| 5 | Home Feed | Suburb-scoped posts with category filters + infinite scroll |
| 6 | Create Post | Text/photo posts with marketplace & event extras |
| 7 | Post Detail | Full post with nested comments and replies |
| 8 | Notifications | Real-time notification stream |
| 9 | Marketplace | Grid view of local buy/sell/free listings |
| 10 | Events | Upcoming local events with calendar-style date cards |
| 11 | Lost & Found | Lost pets, property, found items |
| 12 | Profile | User profile, photo upload, post history |
| 13 | Settings | Account, notifications, suburb change, sign out |
| 14 | Admin Dashboard | Reports, user management (suspend/ban), platform stats |

---

## 🚀 Getting Started

### Prerequisites

- Flutter 3.16+ with Dart 3.0+
- Firebase project (free Spark plan works for launch)
- Xcode 15+ (iOS)
- Android Studio / Android SDK 34+

### 1. Clone / Download

```bash
cd your-projects-folder
# Place this project folder here
cd mysuburb
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

#### Create a Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → name it `mysuburb-prod`
3. Enable Google Analytics (optional)

#### Install the Firebase CLI + FlutterFire CLI

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

#### Configure Firebase for Flutter

```bash
flutterfire configure --project=your-project-id
```

This generates `lib/firebase_options.dart` automatically for iOS, Android, and web.

#### Update main.dart

Replace the `Firebase.initializeApp()` call with:

```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 4. Enable Firebase Services

In Firebase Console → your project:

| Service | Steps |
|---------|-------|
| **Authentication** | Authentication → Sign-in method → Enable: Email/Password, Google, Apple |
| **Firestore** | Firestore Database → Create database → Start in production mode |
| **Storage** | Storage → Get started → Choose a region close to Australia (australia-southeast1) |
| **Cloud Messaging** | Automatically enabled — add APNs certificate for iOS |

### 5. Firestore Security Rules

Paste these rules in **Firestore → Rules**:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can read any profile, only write their own
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId
        || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Posts: anyone logged in can read, authors can write, admins can update
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.authorId
        || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
      allow delete: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Comments
    match /comments/{commentId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.authorId;
      allow delete: if request.auth.uid == resource.data.authorId
        || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Notifications: users can only read their own
    match /notifications/{notifId} {
      allow read, update: if request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
    
    // Reports
    match /reports/{reportId} {
      allow create: if request.auth != null;
      allow read, update: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

### 6. Firebase Storage Rules

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /avatars/{userId}.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /posts/{postId}/{imageFile} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### 7. Firestore Indexes

Create these **composite indexes** in Firestore → Indexes:

| Collection | Fields | Order |
|------------|--------|-------|
| posts | suburb ASC, state ASC, isRemoved ASC, createdAt DESC |
| posts | suburb ASC, state ASC, category ASC, isRemoved ASC, createdAt DESC |
| posts | suburb ASC, state ASC, category ASC, isRemoved ASC, eventDate ASC |
| posts | authorId ASC, isRemoved ASC, createdAt DESC |
| comments | postId ASC, createdAt ASC |
| notifications | userId ASC, createdAt DESC |
| reports | isResolved ASC, createdAt DESC |

The app will also prompt you with direct links to create indexes when they're needed.

---

## 📱 iOS Setup

### Google Sign-In

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add to `ios/Runner/` in Xcode (drag and drop)
3. In `ios/Runner/Info.plist`, add your reversed client ID:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
    </array>
  </dict>
</array>
```

### Apple Sign-In

1. In Apple Developer Portal → Certificates, IDs → your App ID → enable Sign In with Apple
2. In Xcode → Signing & Capabilities → + Capability → Sign In with Apple

### Push Notifications

1. Apple Developer Portal → Keys → Create key → enable APNs
2. Firebase Console → Project Settings → Cloud Messaging → Upload APNs Auth Key

### App permissions in Info.plist

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>My Suburb needs access to your photos to add images to your posts.</string>
<key>NSCameraUsageDescription</key>
<string>My Suburb needs camera access to take photos for your posts.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>My Suburb uses your location to suggest nearby suburbs.</string>
```

---

## 🤖 Android Setup

### google-services.json

1. Download from Firebase Console → Project Settings → Android app
2. Place at `android/app/google-services.json`

### AndroidManifest.xml permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### Minimum SDK

In `android/app/build.gradle`:

```gradle
defaultConfig {
    minSdkVersion 21
    targetSdkVersion 34
}
```

---

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry, routing (GoRouter)
├── models/
│   └── models.dart              # AppUser, Post, Comment, Notification, Report
├── providers/
│   └── user_provider.dart       # Auth state + user profile (ChangeNotifier)
├── screens/
│   ├── splash_screen.dart       # Animated splash
│   ├── login_screen.dart        # Login (email + Google + Apple)
│   ├── auth_screens.dart        # SignUp + SelectSuburb
│   ├── home_feed_screen.dart    # Main feed with filters
│   ├── post_screens.dart        # PostDetail + CreatePost
│   ├── section_screens.dart     # Marketplace + Events + LostFound
│   ├── profile_screens.dart     # Profile + Notifications + Settings
│   └── admin_screen.dart        # Admin dashboard
├── services/
│   ├── auth_service.dart        # Firebase Auth wrapper
│   └── post_service.dart        # Firestore CRUD for posts/comments
├── utils/
│   └── app_theme.dart           # Theme, colours, constants
└── widgets/
    └── shared_widgets.dart      # PostCard, UserAvatar, EmptyState, etc.
```

---

## 🎨 Design System

| Token | Value | Usage |
|-------|-------|-------|
| `brandGreen` | `#2D6A4F` | Primary actions, nav, badges |
| `brandGreenLight` | `#52B788` | Accents, highlights |
| `brandGreenPale` | `#D8F3DC` | Backgrounds, chips |
| `terracotta` | `#BC4749` | Errors, alerts, safety posts |
| `sand` | `#F8F4EF` | App background |
| `charcoal` | `#1B1F23` | Body text |
| `midGrey` | `#6B7280` | Captions, metadata |

---

## 💰 Monetisation Roadmap

**Phase 1 (Launch):** Free for all users

**Phase 2 (3–6 months):**
- Local business profiles with featured placement
- Sponsored posts (clearly labelled)
- Event promotion ($19–$49/event)

**Phase 3 (6–12 months):**
- Premium business pages ($29/month)
- Featured listings in Marketplace
- Suburb-wide announcement tool for councils

---

## 🔄 Making Someone an Admin

Run this once in the Firebase Console → Firestore:

1. Find the user document in `users` collection
2. Edit the document and set `isAdmin: true`

Or use the Firebase Admin SDK:

```javascript
await db.collection('users').doc(uid).update({ isAdmin: true });
```

---

## 🚢 Publishing

### iOS (App Store)
```bash
flutter build ipa --release
```
Then use Xcode Organizer or Transporter to upload to App Store Connect.

### Android (Google Play)
```bash
flutter build appbundle --release
```
Upload the `.aab` file to Google Play Console.

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| firebase_core | ^2.24 | Firebase foundation |
| firebase_auth | ^4.16 | Authentication |
| cloud_firestore | ^4.14 | Database |
| firebase_storage | ^11.6 | Image storage |
| firebase_messaging | ^14.7 | Push notifications |
| google_sign_in | ^6.2 | Google auth |
| sign_in_with_apple | ^6.1 | Apple auth |
| provider | ^6.1 | State management |
| go_router | ^13.0 | Navigation |
| image_picker | ^1.0 | Photo picker |
| cached_network_image | ^3.3 | Image caching |
| shimmer | ^3.0 | Loading skeletons |
| timeago | ^3.6 | Relative timestamps |
| uuid | ^4.3 | Unique IDs |
| url_launcher | ^6.2 | Open URLs |

---

## 🐛 Common Issues

**"FirebaseApp not initialized"** → Make sure `firebase_options.dart` is generated via `flutterfire configure`

**Firestore permission denied** → Check Security Rules are deployed; ensure user is logged in

**Images not loading** → Check Storage rules; verify CORS on Storage bucket

**Google Sign-In fails on iOS** → Verify the reversed client ID URL scheme in `Info.plist`

**Build fails on Android** → Confirm `google-services.json` is at `android/app/google-services.json` and `minSdkVersion 21`

---

## 📞 Support

Built with ❤️ for Australian communities.
