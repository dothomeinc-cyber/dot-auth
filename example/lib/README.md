# Dot Auth Example Setup

## Prerequisites

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Phone Authentication in Firebase Console
3. Register your Android/iOS app in Firebase

## Setup Steps

### 1. Configure Firebase CLI

```bash
cd example
flutter pub add firebase_core firebase_auth
flutter pub add -d flutterfire_cli
flutterfire configure