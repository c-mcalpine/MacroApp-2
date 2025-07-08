# CodeMagic iOS Build Setup Guide

## Required Environment Variables

Set these in your CodeMagic project settings:

### App Configuration
- `API_BASE_URL`: Your API base URL (e.g., https://macro-app-2.vercel.app)
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key

### Code Signing (Required for App Store)
- `CM_CERTIFICATE`: Base64 encoded .p12 certificate
- `CM_CERTIFICATE_PASSWORD`: Certificate password
- `CM_PROVISIONING_PROFILE`: Base64 encoded .mobileprovision file
- `CM_PROVISIONING_PROFILE_UUID`: Provisioning profile UUID
- `CM_DEVELOPMENT_TEAM`: Your Apple Developer Team ID

### App Store Connect (Optional - for TestFlight uploads)
- `APP_STORE_CONNECT_PRIVATE_KEY`: App Store Connect API private key
- `APP_STORE_CONNECT_KEY_IDENTIFIER`: App Store Connect API key ID
- `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect issuer ID

## Setup Steps

### 1. Code Signing Setup
1. Export your iOS Distribution Certificate as .p12 file
2. Base64 encode it: `base64 -i certificate.p12 | pbcopy`
3. Add to CodeMagic as `CM_CERTIFICATE`

### 2. Provisioning Profile Setup
1. Download your App Store provisioning profile
2. Base64 encode it: `base64 -i profile.mobileprovision | pbcopy`
3. Add to CodeMagic as `CM_PROVISIONING_PROFILE`

### 3. App Store Connect API (Optional)
1. Create API key in App Store Connect
2. Download the .p8 file and add its contents to CodeMagic
3. Add the key ID and issuer ID

## Build Process

The `codemagic.yaml` file handles:
- ✅ Flutter dependency installation
- ✅ iOS CocoaPods installation
- ✅ Code signing setup
- ✅ iOS build and archive
- ✅ IPA export
- ✅ TestFlight upload (if configured)

## Troubleshooting

### Common Issues:
1. **Code Signing Errors**: Ensure certificates and provisioning profiles are correctly encoded
2. **Environment Variables**: Verify all required variables are set in CodeMagic
3. **Build Failures**: Check the build logs for specific error messages

### Build Commands Used:
```bash
# Install dependencies
flutter pub get
cd ios && pod install

# Build iOS app
flutter build ios --release --dart-define=API_BASE_URL=$API_BASE_URL --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY --no-codesign

# Archive and export
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive clean archive
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath build/ios -exportOptionsPlist exportOptions.plist
```

## Security Notes

- ✅ Removed `.env` from assets (security best practice)
- ✅ Using `--dart-define` for environment variables
- ✅ Added encryption exemption declaration
- ✅ Proper App Transport Security configuration 