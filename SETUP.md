# Setup Instructions

## Firebase Configuration

This project uses Firebase for authentication and backend services. You'll need to set up your own Firebase project.

### Steps:

1. **Create a Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project" and follow the setup wizard
   - Enable the following services:
     - Authentication (Google Sign-In, Sign in with Apple)
     - Firestore Database
     - Analytics (optional)

2. **Download Configuration File**
   - In Firebase Console, go to Project Settings
   - Under "Your apps", select iOS app (or add one)
   - Download `GoogleService-Info.plist`
   - Place it in the `starving/` directory (same level as `Info.plist`)

3. **Configure Authentication Providers**
   - **Google Sign-In:**
     - In Firebase Console > Authentication > Sign-in method
     - Enable Google provider
     - Add your app's Bundle ID
   
   - **Sign in with Apple:**
     - Enable Apple provider in Firebase Console
     - Configure Apple Developer account with Sign in with Apple capability
     - Add the capability in Xcode

4. **Security Note**
   - **NEVER commit `GoogleService-Info.plist` to git**
   - This file is already in `.gitignore`
   - Keep your API keys secure and private

## CocoaPods Dependencies

Install project dependencies:

```bash
cd /path/to/starving
pod install
```

Always open `starving.xcworkspace` (not `.xcodeproj`) after installing pods.

## Build and Run

1. Open `starving.xcworkspace` in Xcode
2. Select a simulator or connected device
3. Build and run (⌘R)

## Troubleshooting

- **Build errors**: Clean build folder (⌘⇧K) and rebuild
- **Pod issues**: Run `pod deintegrate && pod install`
- **Firebase issues**: Verify `GoogleService-Info.plist` is in the correct location
