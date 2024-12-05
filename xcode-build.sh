#!/bin/bash

# Variables (replace these with your actual values)
PROJECT_PATH="/path/to/your/Unity-iPhone.xcodeproj"
WORKSPACE_PATH="/path/to/your/Unity-iPhone.xcworkspace"
SCHEME_NAME="Unity-iPhone"
CODE_SIGN_IDENTITY="Apple Development: YOUR_NAME (YOUR_ID)"
PROVISIONING_PROFILE_SPECIFIER="YOUR_PROVISIONING_PROFILE"

# 1. Modify Target Memberships
# Note: Direct modification of target memberships via CLI is non-trivial and typically requires editing the project.pbxproj file.
# This step is usually performed manually in Xcode.

# 2. Adjust 'NativeCallProxy.h' Membership
# Note: Changing the visibility of headers is complex via CLI and is usually done within Xcode.

# 3. Update Code Signing for 'Unity-iPhone' and 'UnityFramework'
xcodebuild -workspace "$WORKSPACE_PATH" \
  -scheme "$SCHEME_NAME" \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" \
  PROVISIONING_PROFILE_SPECIFIER="$PROVISIONING_PROFILE_SPECIFIER" \
  CODE_SIGN_STYLE="Automatic" \
  clean build

# 4. Update Framework Embedding
# Note: Setting "Embed & Sign" for frameworks is typically managed within Xcode's UI.

# Build and Archive
xcodebuild -workspace "$WORKSPACE_PATH" \
  -scheme "$SCHEME_NAME" \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  CODE_SIGN_STYLE="Automatic" \
  archive -archivePath "$PWD/build/$SCHEME_NAME.xcarchive"

# Export the IPA
xcodebuild -exportArchive \
  -archivePath "$PWD/build/$SCHEME_NAME.xcarchive" \
  -exportPath "$PWD/build" \
  -exportOptionsPlist /path/to/ExportOptions.plist
