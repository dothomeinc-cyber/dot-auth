# Changelog

All notable changes to the `riverpod_offline_sync` package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.15] - 2024-01-15

### 🔄 Updated Dependencies
- Updated `firebase_auth` to `^6.5.1`
- Updated `firebase_core` to `^4.9.0`
- Updated `go_router` to `^17.2.3`
- Updated `flutter_riverpod` to `^3.3.1`
- Updated `phone_form_field` to `^10.0.17`
- Updated `pinput` to `^6.0.2`
- Updated `google_fonts` to `^8.1.0`

### 🐛 Bug Fixes
- Fixed `StateNotifier` import issues
- Improved compatibility with latest Flutter version

### ✨ Enhancements
- Added Timer support for better sync scheduling
- Updated README.md with comprehensive documentation

---

## [1.0.12] - 2024-01-14

### 🔄 Updated Dependencies
- Updated `firebase_auth` to `^6.5.1`
- Updated `firebase_core` to `^4.9.0`
- Updated `go_router` to `^17.2.3`
- Updated `flutter_riverpod` to `^3.3.1`
- Updated `phone_form_field` to `^10.0.17`
- Updated `pinput` to `^6.0.2`
- Updated `google_fonts` to `^8.1.0`

### 🐛 Bug Fixes
- Fixed `StateNotifier` import path
- Improved compatibility with latest Riverpod

### ✨ Enhancements
- Added Timer-based auto-sync functionality
- Improved sync scheduling

---

## [1.0.11] - 2024-01-13

### 🔄 Updated Dependencies
- Updated `firebase_auth` to `^6.5.1`
- Updated `firebase_core` to `^4.9.0`
- Updated `go_router` to `^17.2.3`
- Updated `flutter_riverpod` to `^3.3.1`
- Updated `phone_form_field` to `^10.0.17`
- Updated `pinput` to `^6.0.2`
- Updated `google_fonts` to `^8.1.0`

### 🐛 Bug Fixes
- Fixed `StateNotifier` import in riverpod providers
- Improved overall compatibility

---

## [1.0.10] - 2024-01-12

### 🐛 Bug Fixes
- Fixed missing `StateNotifier` import
- Added `state_notifier` as explicit dependency
- Fixed `RouterNotifier` type casting in go_router integration

### ✨ Enhancements
- All Riverpod providers now work correctly
- Improved type safety in navigation handling

---

## [1.0.9] - 2024-01-11

### 🐛 Bug Fixes
- Fixed type casting error in `RouterNotifier`
- Removed unnecessary type arguments
- Improved null safety handling

---

## [1.0.8] - 2024-01-10

### ✨ New Features
- Added `RouterNotifier` for reactive routing
- Improved authentication state redirection
- Better navigation handling on login/logout events

### 🔧 Improvements
- Enhanced auth state stream handling
- Smoother route transitions

---

## [1.0.7] - 2024-01-09

### ✨ New Features
- Added `RouterNotifier` for reactive routing
- Improved authentication state redirection
- Better navigation handling on login/logout

### 🐛 Bug Fixes
- Fixed route redirection issues

---

## [1.0.6] - 2024-01-08

### ✨ New Features
- Added `RouterNotifier` for reactive routing
- Improved authentication state redirection
- Better navigation handling on login/logout

### 📚 Documentation
- Updated API documentation for routing

---

## [1.0.5] - 2024-01-07

### 📚 Documentation
- Complete README overhaul
- Added role-based access control (RBAC) examples
- Improved Firestore integration documentation
- Fixed typos and formatting issues

---

## [1.0.4] - 2024-01-06

### 📚 Documentation
- Updated README with complete API documentation
- Added role-based access control examples
- Improved documentation for Firestore integration
- Fixed typos and formatting issues

---

## [1.0.3] - 2024-01-05

### 📚 Documentation
- Updated README with complete API documentation
- Added role-based access control examples
- Improved documentation for Firestore integration
- Fixed typos and formatting

---

## [1.0.2] - 2024-01-04

### 🔧 Improvements
- Performance optimizations
- Reduced widget rebuilds
- Improved memory management

---

## [1.0.1] - 2024-01-03

### 🐛 Bug Fixes
- Fixed null-aware operator warnings
- Improved null safety handling

### 📚 Documentation
- Improved documentation with more examples
- Added troubleshooting section
- Updated dependency list

### ✨ Enhancements
- Added more usage examples
- Updated all dependencies to latest versions

---

## [1.0.0] - 2024-01-01

### 🎉 Initial Release
- Phone number authentication with OTP verification
- Riverpod state management integration
- GoRouter navigation integration
- Offline queue management
- Connectivity monitoring
- Smart retry with exponential backoff
- Idempotency key support
- Persistent queue storage (Hive)
- Firebase integration (Firestore, Storage, Auth)
- Conflict resolution strategies
- Sync metrics and analytics
- Built-in UI components (Banner, Toast, Progress Bar, Debug Panel)
- SyncAwareMixin for easy integration
- Comprehensive Riverpod providers
- Debug and QA tooling

### ✨ Features
- ✅ Bi-directional sync (push + pull)
- ✅ Priority-based queue (critical, high, normal, low, background)
- ✅ Automatic sync on reconnect
- ✅ WiFi-only sync mode
- ✅ Concurrent queue processing
- ✅ Exponential backoff retry
- ✅ Deep merge conflict resolution
- ✅ Upload pause/resume/cancel
- ✅ Real-time sync progress streams
- ✅ Mutex-protected synchronization

---

## [0.9.0] - 2023-12-15

### 🧪 Beta Release
- Initial beta version for testing
- Core offline sync functionality
- Basic queue management
- Connectivity monitoring

---

## [0.5.0] - 2023-11-01

### ⚠️ Alpha Release
- Early alpha version for internal testing
- Experimental features
- API subject to change

---

## Release Notes

### Upgrade Guide

#### From 1.0.12 to 1.0.13
- Update your `pubspec.yaml` dependencies to match the latest versions
- No breaking changes

#### From 1.0.9 to 1.0.10
- Add `state_notifier: ^1.0.0` to your dependencies if not already present
- Update Riverpod to version 2.5.0 or higher

#### From 1.0.0 to 1.0.1
- Update all Riverpod providers to use `.valueOrNull` extension
- Ensure `OfflineSyncInitializer.initialize()` is called before `runApp()`

---

### Version Compatibility

| Package Version | Flutter SDK | Riverpod | Firebase |
|----------------|-------------|----------|----------|
| 1.0.13 | 3.16.0+ | 3.3.1+ | 6.5.1+ |
| 1.0.12 | 3.16.0+ | 3.3.1+ | 6.5.1+ |
| 1.0.11 | 3.16.0+ | 3.3.1+ | 6.5.1+ |
| 1.0.10 | 3.16.0+ | 2.5.0+ | 5.0.0+ |
| 1.0.0 | 3.0.0+ | 2.4.0+ | 5.0.0+ |

---

**Note:** For complete changelog history, please visit the [GitHub releases page](https://github.com/yourusername/riverpod_offline_sync/releases). 🚀