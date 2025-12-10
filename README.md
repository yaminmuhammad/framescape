# FrameScape 📸✨

**AI-Powered Photo Transformation for Social Media**

FrameScape is a Flutter mobile application that transforms single portrait photos into multiple AI-generated travel and lifestyle scenes perfect for Instagram, TikTok, and other social media platforms. Built with Firebase integration and Google Gemini AI for seamless image generation.


[![FrameScape Demo](https://img.youtube.com/vi/iQHDiPrrND4/maxresdefault.jpg)](https://youtu.be/iQHDiPrrND4)
---

## 🎯 Features

- **Single Upload, Multiple Outputs**: Upload one portrait and get 18 AI-generated variations (3 per category)
- **6 Stunning Categories**: Beach, City, Road Trip, Mountain, Cafe, and Sunset themes
- **Firebase Integration**: Secure authentication, storage, and real-time data
- **Modern UI/UX**: Apple Design Award-style interface with smooth animations
- **Full-Screen Gallery**: View, save, and share generated images
- **Cross-Platform**: Runs on Android, iOS, and Web

---

## 🏗️ Tech Stack

### Frontend
- **Flutter 3.10.1** - Cross-platform UI framework
- **Dart 3** - Programming language
- **BLoC Pattern** - State management
- **Material 3** - UI design system

### Backend & Services
- **Firebase Anonymous Authentication** - User authentication
- **Firebase Firestore** - Metadata and user data
- **Firebase Storage** - Image storage (original + generated)
- **Firebase Cloud Functions** - AI generation API proxy
- **Google Gemini 2.5 Flash Image** - AI image generation

### Key Dependencies
```yaml
firebase_core: ^3.8.1
firebase_auth: ^5.3.4
cloud_firestore: ^5.6.0
firebase_storage: ^12.4.0
cloud_functions: ^5.2.0
flutter_bloc: ^9.0.0
image_picker: ^1.1.2
cached_network_image: ^3.4.1
gal: ^2.3.0
share_plus: ^10.1.3
```

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (3.10.1 or higher)
   ```bash
   flutter --version
   ```

2. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase --version
   ```

3. **Firebase Project**
   - Create a new project at [Firebase Console](https://console.firebase.google.com/)
   - Enable: Authentication, Firestore, Storage, Cloud Functions

4. **Google AI API Key**
   - Get API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Enable Gemini API access

---

## ⚙️ Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/framescape.git
cd framescape
```

### 2. Install Dependencies
```bash
# Flutter dependencies
flutter pub get

# Cloud Functions dependencies
cd functions
npm install
cd ..
```

### 3. Firebase Configuration

#### 3.1 Login to Firebase
```bash
firebase login
```

#### 3.2 Link to Your Firebase Project
```bash
firebase use framescape-5f124
```
*Replace with your project ID*

#### 3.3 Configure Firebase in Flutter
If you haven't already:
```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```

This will:
- Update `firebase.json` with your project config
- Generate `lib/firebase_options.dart`
- Update platform-specific configuration files

#### 3.4 Enable Authentication
In Firebase Console:
1. Go to **Authentication** > **Sign-in method**
2. Enable **Anonymous** authentication
3. Save changes

#### 3.5 Create Firestore Database
1. Go to **Firestore Database** > **Create database**
2. Choose **Start in test mode** (we'll add security rules)
3. Select a location (e.g., `us-central`)
4. Click **Done**

#### 3.6 Create Storage Bucket
1. Go to **Storage** > **Get started**
2. Choose **Start in test mode**
3. Select the same location as Firestore
4. Click **Done**

### 4. Configure Security Rules

Deploy the security rules:
```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

### 5. Set Up Cloud Functions API Key

Add your Gemini API key to Firebase Secrets:
```bash
firebase functions:secrets:set GEMINI_API_KEY
```
Enter your API key when prompted.

Verify secrets:
```bash
firebase functions:secrets:access:GEMINI_API_KEY
```

### 6. Deploy Cloud Functions
```bash
firebase deploy --only functions
```

### 7. Run the App

#### Development Mode
```bash
# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d chrome  # Web
flutter run -d android # Android
flutter run -d ios     # iOS (requires Xcode)
```

#### Production Build
```bash
# Android APK
flutter build apk --release

# iOS (requires macOS and Xcode)
flutter build ios --release

# Web
flutter build web --release
```

---

## 🏛️ Architecture

### Project Structure
```
framescape/
├── lib/                          # Flutter app code
│   ├── bloc/                     # BLoC state management
│   │   ├── auth/                 # Authentication logic
│   │   └── image/                # Image generation logic
│   ├── services/                 # Service layer
│   │   ├── auth_service.dart     # Firebase Auth integration
│   │   └── image_service.dart    # Image upload/retrieval
│   ├── screens/
│   │   └── home_screen.dart      # Main UI (1,726 lines)
│   ├── main.dart                 # App entry point
│   └── firebase_options.dart     # Firebase config
├── functions/                    # Firebase Cloud Functions
│   ├── src/
│   │   └── index.ts              # generateImage function
│   ├── package.json              # Dependencies
│   └── tsconfig.json             # TypeScript config
├── firestore.rules               # Firestore security rules
├── storage.rules                 # Storage security rules
├── firebase.json                 # Firebase configuration
└── pubspec.yaml                  # Flutter dependencies
```

### Architecture Pattern: Clean Architecture + BLoC

#### 1. **Presentation Layer** (UI)
- `HomeScreen` - Main UI with Material 3 design
- Handles user interactions
- Subscribes to BLoC states
- Displays loading, error, and success states

#### 2. **State Management Layer** (BLoC)
- `AuthBloc` - Manages authentication state
- `ImageBloc` - Manages image generation state
- Event-driven architecture
- Immutable state transitions

#### 3. **Domain Layer** (Services)
- `AuthService` - Authentication operations
- `ImageService` - Image upload/download/management
- Business logic abstraction
- Error handling and validation

#### 4. **Data Layer** (Firebase)
- Firestore - Metadata storage
- Storage - Image files (original + generated)
- Cloud Functions - AI generation API

### Data Flow

```
┌─────────────┐
│   User      │  Upload Photo
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  HomeScreen │  UI Interaction
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  ImageBloc  │  State Management
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ImageService │  Upload to Storage
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Cloud       │
│ Function    │  AI Generation
│ (Gemini)    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Firestore   │  Save Metadata
│ + Storage   │  Save Images
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  HomeScreen │  Display Results
└─────────────┘
```

### State Management Details

#### AuthBloc
- **States**: `AuthInitial`, `AuthLoading`, `Authenticated`, `Unauthenticated`
- **Events**: `AuthStarted`, `AuthSignedIn`, `AuthSignedOut`
- Auto-sign-in on app launch
- Stream-based auth state monitoring

#### ImageBloc
- **States**: `ImageInitial`, `ImageLoading`, `ImageSuccess`, `ImageError`
- **Events**: `SelectImage`, `GenerateImages`, `SaveImages`, `ShareImages`
- Manages entire generation workflow
- Handles loading states and error recovery

---

## 🔒 Security Implementation

### 1. API Key Security

**❌ What We Don't Do:**
- Never store API keys in Flutter client code
- Never expose Gemini API key in source code
- Never make direct AI API calls from client

**✅ What We Do:**
- Store API keys in Firebase Secrets
- Use Cloud Functions as secure proxy
- Access secrets server-side only via Admin SDK

```typescript
// Cloud Function (server-side only)
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
```

### 2. Firebase Security Rules

#### Firestore Rules
```javascript
// User data isolation
match /users/{userId}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

// Images collection - user-scoped access
match /images/{imageId} {
  allow read: if request.auth != null && resource.data.userId == request.auth.uid;
  allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
}
```

#### Storage Rules
```javascript
// User folders - isolated access
match /users/{userId}/{allPaths=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

// Generated images - public read, Cloud Functions write
match /generated/{userId}/{allPaths=**} {
  allow read: if true;  // Public for sharing
}
```

### 3. Data Sensitivity

- **User Isolation**: Each user can only access their own data
- **Authentication Required**: All operations require valid Firebase Auth session
- **API Rate Limiting**: Cloud Functions include timeout and memory limits
- **Input Validation**: Server-side validation of all inputs
- **Secure Communication**: All data encrypted in transit (HTTPS/TLS)

### 4. Access Control Flow

```
User Action
    ↓
Firebase Auth (verify token)
    ↓
Cloud Function (validate user)
    ↓
Security Rules (check permissions)
    ↓
Firestore/Storage (enforce rules)
```

---

## 🚀 How to Use

### Quick Start
1. **Open the app** - Automatically signs in anonymously
2. **Upload a photo** - Tap "Select Photo" (gallery or camera)
3. **Choose a category** - Select from Beach, City, Road Trip, Mountain, Cafe, Sunset
4. **Generate** - Tap "Generate Magic ✨"
5. **View results** - Browse generated images in grid view
6. **Save/Share** - Tap any image to view full-screen, save, or share

### Main Features

#### Image Selection
- Support for JPG, PNG formats
- Auto-optimization (max 1920x1920, 85% quality)
- Gallery picker or camera capture
- Preview before upload

#### AI Generation
- 3 variations per category
- Category-specific prompts:
  - **Beach**: Tropical paradise, sunset beach, resort vibes
  - **City**: Urban cityscape, metropolitan lifestyle, street exploration
  - **Road Trip**: Scenic highway, van life, classic American road trip
  - **Mountain**: Alpine adventure, hiking trails, mountain retreat
  - **Cafe**: Urban coffee culture, Parisian cafe, hygge cozy vibes
  - **Sunset**: Golden hour silhouette, beach sunset, romantic twilight

#### Results Display
- 2-column responsive grid
- Cached network images for performance
- Smooth loading animations
- Hero transitions to full-screen view
- Individual save/share buttons per image

#### Full-Screen Viewer
- Tap any image to view in full-screen
- Zoom and pan support
- Save to device gallery
- Share via native share sheet
- Smooth slide transitions

---

## 📦 Deployment

### Firebase Deployment

#### 1. Deploy Security Rules
```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

#### 2. Deploy Cloud Functions
```bash
firebase deploy --only functions
```

#### 3. Deploy Hosting (if using Firebase Hosting)
```bash
firebase deploy --only hosting
```

### Mobile App Store Deployment

#### Android (Google Play)
```bash
# Build release APK
flutter build apk --release

# Build App Bundle (recommended)
flutter build appbundle --release

# Sign the app
# Follow: https://docs.flutter.dev/deployment/android#signing-the-app
```

#### iOS (Apple App Store)
```bash
# Build iOS release
flutter build ios --release

# Archive in Xcode
# Upload via Xcode or Transporter
```

### Web Deployment

#### Using Firebase Hosting
```bash
# Build web version
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

---

## 🧪 Testing

FrameScape includes comprehensive test coverage across unit tests, widget tests, and integration tests.

### Test Structure
```
test/
├── unit/                      # Unit tests
│   └── bloc/                 # BLoC state management tests
│       ├── auth/
│       │   └── auth_bloc_test.dart
│       └── image/
│           └── image_bloc_test.dart
├── widget/                   # Widget tests
│   └── home_screen_test.dart
├── integration/              # Integration tests
│   └── app_flow_test.dart
├── test_driver/              # Integration test driver
│   └── app.dart
└── widget_test.dart          # Basic widget test
```

### Running Tests

#### ✅ Recommended: Unit Tests Only
```bash
# Run unit tests with coverage (RECOMMENDED)
flutter test test/unit/bloc/ --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

#### ⚠️ All Tests (may have issues)
```bash
# Run all tests - WARNING: Widget & Integration tests may fail
flutter test --coverage
```

#### Unit Tests
```bash
# Run BLoC unit tests
flutter test test/unit/bloc/

# Run specific BLoC test
flutter test test/unit/bloc/auth/auth_bloc_test.dart
flutter test test/unit/bloc/image/image_bloc_test.dart
```

#### Widget Tests
```bash
# Run widget tests (requires Firebase mock setup)
flutter test test/widget/home_screen_test.dart

# Run basic widget test
flutter test test/widget_test.dart
```

**Note**: Widget tests require mock services to avoid Firebase initialization.
For full testing, use integration tests with Firebase emulator instead.

#### Integration Tests
```bash
# Run integration tests
flutter drive --target=test_driver/app.dart

# Run specific integration test
flutter drive --target=test_driver/app.dart --dart-define=testName=app_flow_test
```

### Cloud Functions Testing
```bash
cd functions

# Install dependencies
npm install

# Run locally with emulator
npm run serve

# Run unit tests
npm test

# View logs
npm run logs
```

### Test Coverage Status
- **✅ Unit Tests**: 18/18 tests passing (>80% coverage for BLoCs and Services)
- **⚠️ Widget Tests**: Requires mock Firebase setup (not fully automated)
- **⚠️ Integration Tests**: Requires Firebase emulator and `flutter drive`

**Note**: Unit tests are fully functional and recommended for development.
Widget and integration tests need additional setup for CI/CD environments.

### Writing Tests

#### Adding a New BLoC Test
```dart
// test/unit/bloc/your_feature/your_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:your_package/your_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([YourService])
import 'your_bloc_test.mocks.dart';

void main() {
  group('YourBloc', () {
    late YourBloc yourBloc;
    late MockYourService mockService;

    setUp(() {
      mockService = MockYourService();
      // Stub required methods
      when(mockService.requiredMethod()).thenAnswer((_) async {});
      yourBloc = YourBloc(service: mockService);
    });

    test('initial state is correct', () {
      expect(yourBloc.state, equals(YourInitial()));
    });

    blocTest<YourBloc, YourState>(
      'emits [Loading, Success] when Event is added',
      build: () {
        when(mockService.someMethod()).thenAnswer((_) async => 'result');
        return yourBloc;
      },
      act: (bloc) => bloc.add(YourEvent()),
      expect: () => [
        predicate<YourState>((state) => state.status == YourStatus.loading),
        predicate<YourState>((state) => state.status == YourStatus.success),
      ],
      verify: (_) {
        verify(mockService.someMethod()).called(1);
      },
    );
  });
}
```

**Best Practices**:
- ✅ Use `predicate` for state matching instead of direct equality
- ✅ Stub all required mock methods in `setUp()`
- ✅ Use `anyNamed` only in `when()` and `verify()`, not in `expect()`
- ✅ Generate mocks with `@GenerateMocks` annotation

#### Adding a Widget Test
```dart
// test/widget/your_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_package/your_screen.dart';

void main() {
  testWidgets('YourScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: YourScreen(),
      ),
    );

    expect(find.text('Expected Text'), findsOneWidget);
  });
}
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Firebase Configuration Error
**Error**: `FirebaseOptions cannot be null`
**Solution**:
```bash
flutterfire configure
flutter pub get
```

#### 2. Cloud Functions Deployment Fails
**Error**: `Functions deploy failed`
**Solutions**:
- Check Firebase CLI version: `firebase --version` (use latest)
- Verify API key is set: `firebase functions:secrets:access:GEMINI_API_KEY`
- Check billing is enabled for your Firebase project

#### 3. Authentication Not Working
**Error**: User not signed in automatically
**Solution**:
- Ensure Anonymous auth is enabled in Firebase Console
- Check `firebase.json` has correct project ID
- Restart app: `flutter clean && flutter pub get && flutter run`

#### 4. Images Not Loading
**Error**: Generated images show error placeholder
**Solutions**:
- Check Storage rules are deployed: `firebase deploy --only storage`
- Verify Cloud Functions deployed: `firebase functions:log`
- Check Firestore rules: `firebase deploy --only firestore:rules`
- Review logs: `firebase functions:log --only generateImage`

#### 5. Build Errors
**Error**: iOS build fails with CocoaPods
**Solution**:
```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
flutter build ios
```

#### 6. API Key Issues
**Error**: Gemini API returns 401/403
**Solutions**:
- Verify API key in Firebase Secrets
- Check API key has Gemini API access enabled
- Ensure billing is enabled for Google Cloud project
- Review API key permissions

#### 7. Test Errors
**Error**: `MissingStubError` or `anyNamed` in wrong context
**Solutions**:
- Run mock generation: `flutter packages pub run build_runner build`
- Use `predicate` for state matching instead of direct equality
- Stub all required methods in `setUp()`:
```dart
setUp(() {
  mockService = MockService();
  when(mockService.method()).thenAnswer((_) async {});
  bloc = Bloc(service: mockService);
});
```

**Error**: Widget tests fail with Firebase initialization
**Solution**:
- Use unit tests instead: `flutter test test/unit/bloc/`
- Or set up Firebase emulator for integration tests

**Error**: Integration tests fail
**Solution**:
- Use `flutter drive` not `flutter test`
- Start emulator first: `firebase emulators:start`

### Debug Mode

#### Enable Debug Logging
```dart
// In main.dart
FirebaseFirestore.setLoggingEnabled(true);
FirebaseAuth.instance.useAuthEmulator("localhost", 9099);
```

#### View Cloud Function Logs
```bash
# Real-time logs
firebase functions:log

# Specific function logs
firebase functions:log --only generateImage

# Last 100 lines
firebase functions:log --lines 100
```

#### Local Emulator
```bash
# Start emulators
firebase emulators:start

# Emulator UI (web)
# Visit: http://localhost:4000
```

---

## 📊 Performance

### Optimization Features
- **Image Caching**: `cached_network_image` for efficient loading
- **Image Optimization**: Auto-resize to 1920x1920, 85% quality
- **Lazy Loading**: Images load on-demand in grid view
- **Memory Management**: Proper disposal of image resources
- **Network Efficiency**: Single upload, multiple downloads

### Metrics
- **App Size**: ~25MB (Android APK)
- **Cold Start**: ~2-3 seconds
- **Image Generation**: 15-30 seconds (varies by category)
- **Image Upload**: 1-3 seconds (depends on file size)
- **Unit Tests**: ~1-2 seconds (18 tests)
- **Test Coverage**: >80% for BLoCs and Services

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Code Style
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter format .` before committing
- Run `flutter analyze` to check for issues
- Write tests for new features

### Testing Requirements
- **Unit Tests**: Write tests for all BLoCs and services
- **Run Tests**: `flutter test test/unit/bloc/ --coverage`
- **Mock Generation**: Run `flutter packages pub run build_runner build` after creating test files
- **Best Practices**:
  - Use `predicate` for state matching
  - Stub all required mock methods in `setUp()`
  - Keep Firebase out of unit tests (use mocks)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Google Gemini AI** - Image generation capabilities
- **Firebase** - Backend infrastructure
- **Flutter Team** - Amazing cross-platform framework
- **BLoC Library** - State management pattern

---

## 📞 Support

If you have questions or need help:

- **GitHub Issues**: [Create an issue](https://github.com/your-username/framescape/issues)
- **Documentation**: Check this README
- **Logs**: Use `firebase functions:log` for Cloud Function issues

---

## 🎨 Design Philosophy

FrameScape follows the **Apple Design Award** principles:

- **Clarity**: Clear hierarchy, readable typography (SF Pro Display)
- **Deference**: Content-focused design, minimal chrome
- **Depth**: Smooth animations, realistic physics, contextual transitions

UI Features:
- Material 3 design system
- Dynamic color schemes (light/dark mode)
- Consistent 20px spacing grid
- Smooth 200-300ms transitions
- Skeleton loading animations
- Hero animations for navigation

---

**Built with ❤️ using Flutter and Firebase**
