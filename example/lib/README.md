# Dot Auth Example App

This is a complete working example of the dot_auth package.

## Setup Instructions

### 1. Create a Firebase Project
- Go to https://console.firebase.google.com
- Create a new project
- Enable Phone Authentication

### 2. Register Your App

**For Android:**
- Package name: `com.example.dot_auth_example`
- Download `google-services.json`
- Place in `android/app/`

**For iOS:**
- Bundle ID: `com.example.dotAuthExample`
- Download `GoogleService-Info.plist`
- Place in `ios/Runner/`

### 3. Generate Firebase Options

```bash
flutter pub add firebase_core firebase_auth
flutter pub add -d flutterfire_cli
flutterfire configure