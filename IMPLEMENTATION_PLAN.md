# Photo AI App - Implementation Master Plan

**Status:** 🔴 Not Started
**Target Stack:** Flutter, Firebase (Auth, Storage, Firestore, Functions)
**External API:** Google Gemini / NanoBanana Image Gen
**Design Goal:** Apple Design Award Style (Clean, Minimalist)

---

## 🤖 Context for AI Agent
You are an expert Flutter & Firebase engineer. You are tasked with building a "Photo AI Test Project" based on strict requirements.
**CRITICAL RULES:**
1.  **Security First:** NEVER expose API keys in the Flutter client. [cite_start]All AI generation MUST go through Firebase Cloud Functions[cite: 52, 53].
2.  [cite_start]**Tech Stack:** Use **only** Flutter, Firebase Anonymous Auth, Firebase Storage, Firebase Firestore, and Firebase Cloud Functions[cite: 16].
3.  [cite_start]**UI/UX:** Create a single-screen app with a high-quality, modern "Apple-style" feel[cite: 6, 62].
4.  [cite_start]**Flow:** Upload Image -> Trigger Cloud Function -> AI Generates Variant -> Save to Storage/Firestore -> Display in App[cite: 3, 93].

---

##  Phase 1: Environment & Backend Setup
*Focus: Setting up the foundation and securing the API connection.*

### ✅ Task 1.1: Project Initialization
- [ ] Create a new Flutter project: `flutter create photo_ai_app`.
- [ ] Initialize Firebase: Run `flutterfire configure` (ensure specific project selection).
- [ ] Add Dependencies (`pubspec.yaml`):
    - `firebase_core`, `firebase_auth` (Anonymous).
    - `cloud_firestore`, `firebase_storage`.
    - `cloud_functions`.
    - `image_picker` (for camera/gallery).
    - `provider` or `flutter_riverpod` (for state management).
    - `uuid` (for unique naming).

### ✅ Task 1.2: Firebase Services Configuration
- [ ] [cite_start]**Auth:** Enable **Anonymous Authentication** in Firebase Console[cite: 19].
- [ ] **Storage:** Enable Storage. [cite_start]Set basic rules (allow read/write for authenticated users)[cite: 20].
- [ ] [cite_start]**Firestore:** Create database in production mode[cite: 21].

### ✅ Task 1.3: Cloud Functions & Secrets (Crucial)
- [ ] [cite_start]Initialize Functions: `firebase init functions` (Select TypeScript/JavaScript)[cite: 22].
- [ ] **Secret Management:**
    - Store the Gemini/NanoBanana API Key securely using Firebase Secrets.
    - Command: `firebase functions:secrets:set GEN_AI_API_KEY`.
- [ ] **Create Function `generateImage`:**
    - [cite_start]Type: HTTPS Callable Function (allows direct call from Flutter)[cite: 27, 34].
    - **Logic:**
        1. Receive `imagePath` (from Storage) and `prompt` from client.
        2. Download image within Cloud Function.
        3. [cite_start]Call External API (Gemini/NanoBanana) using the Secret Key[cite: 25].
        4. Receive generated image buffer/URL.
        5. [cite_start]Save result back to Firebase Storage (`generated/` folder)[cite: 43].
        6. [cite_start]Write metadata to Firestore (link original + generated URLs)[cite: 44].
        7. Return success response to client.

---

## Phase 2: Security Rules Implementation
*Focus: Preventing data leaks and unauthorized access.*

### [cite_start]✅ Task 2.1: Firestore Rules [cite: 55]
- [ ] Implement rules ensuring users can only read/write their own data.
    - Match `request.auth.uid` with the document's `userId` field.

### [cite_start]✅ Task 2.2: Storage Rules [cite: 56]
- [ ] Restrict access to `users/{userId}/*` paths.
- [ ] Ensure only the owner can upload or view their raw images.

---

## Phase 3: Flutter Frontend Development
*Focus: Building the Single Screen UI with high-end design.*

### ✅ Task 3.1: State Management & Auth
- [ ] Implement `AuthService`:
    - Auto-login anonymously on app launch (`FirebaseAuth.instance.signInAnonymously()`).
    - Store `uid` for file paths.

### [cite_start]✅ Task 3.2: Main Screen UI (Layout) [cite: 30]
- [ ] **Header:** Clean title, modern typography.
- [ ] **Upload Area:**
    - Large, elegant touch target.
    - [cite_start]Handle `image_picker` (Gallery & Camera)[cite: 32].
    - Show preview of selected image (rounded corners, subtle shadow).
- [ ] **Generate Action:**
    - "Generate Magic" button.
    - [cite_start]Show `CircularProgressIndicator` or a custom skeleton loader during loading[cite: 47].

### ✅ Task 3.3: Connecting to Cloud Function
- [ ] **Logic:**
    1. [cite_start]User picks image -> Upload to Firebase Storage `users/{uid}/original/{id}.jpg`[cite: 42].
    2. Get `fullPath` or `downloadUrl`.
    3. Call `HttpsCallable('generateImage')` passing the image path.
    4. Await result.
- [ ] **Error Handling:**
    - Wrap in `try-catch`.
    - [cite_start]Show user-friendly Snackbars on failure (e.g., "AI is busy, try again")[cite: 58].

### [cite_start]✅ Task 3.4: Results Display [cite: 45]
- [ ] Create a "Result Section" below the original image.
- [ ] Use a Grid or Horizontal ScrollView for generated images.
- [ ] Implement "CachedNetworkImage" (or similar) for smooth loading.
- [ ] [cite_start]**Design:** "Apple Design Award" feel - use whitespace, consistent padding (16/24px), and system fonts[cite: 62].

---

## Phase 4: Final Polish & Deliverables

### ✅ Task 4.1: Code Quality & Architecture
- [ ] Refactor logic out of UI into ViewModels/Providers.
- [ ] Ensure strictly typed models for Firestore data.

### [cite_start]✅ Task 4.2: Documentation (README.md) [cite: 86]
- [ ] Write Setup Instructions.
- [ ] Explain Architecture (Flutter -> Cloud Function -> AI API).
- [ ] [cite_start]Explain Security approach (Secrets + Rules)[cite: 89].

### ✅ Task 4.3: Testing
- [ ] Verify: Can user A see User B's images? (Should be NO).
- [ ] Verify: Does the API key appear in `flutter build`? (Should be NO).