#!/bin/bash

# Configuration
UNITY_BUILD_DIR="Builds/iOS"
XCODE_PROJECT="Unity-iPhone.xcodeproj"
MOBILE_APP_DIR="mobile-app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 successful${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Check Unity build output
verify_unity_build() {
    echo "Verifying Unity build..."
    
    if [ ! -d "$UNITY_BUILD_DIR" ]; then
        echo -e "${RED}✗ Unity build directory not found${NC}"
        exit 1
    fi
    
    if [ ! -d "$UNITY_BUILD_DIR/$XCODE_PROJECT" ]; then
        echo -e "${RED}✗ Xcode project not found${NC}"
        exit 1
    fi
    
    check_status "Unity build verification"
}

# Verify Data folder target membership
verify_target_membership() {
    echo "Verifying Data folder target membership..."
    
    # Use xcodebuild to list targets
    xcodebuild -project "$UNITY_BUILD_DIR/$XCODE_PROJECT" -list | grep "UnityFramework" > /dev/null
    check_status "Target membership verification"
}

# Verify NativeCallProxy.h settings
verify_native_proxy() {
    echo "Verifying NativeCallProxy.h..."
    
    NATIVE_PROXY_PATH="$UNITY_BUILD_DIR/Libraries/Plugins/iOS/NativeCallProxy.h"
    if [ ! -f "$NATIVE_PROXY_PATH" ]; then
        echo -e "${RED}✗ NativeCallProxy.h not found${NC}"
        exit 1
    fi
    
    # Check if file is public in project settings
    /usr/libexec/PlistBuddy -c "Print :objects:$NATIVE_PROXY_FILE_REF:attributes:Public" \
        "$UNITY_BUILD_DIR/$XCODE_PROJECT/project.pbxproj" > /dev/null
    check_status "NativeCallProxy.h visibility verification"
}

# Verify framework embedding settings
verify_framework_settings() {
    echo "Verifying framework embedding..."
    
    # Check Agora frameworks
    grep -r "Embed & Sign" "$UNITY_BUILD_DIR/$XCODE_PROJECT/project.pbxproj" | grep "Agora" > /dev/null
    check_status "Framework embedding verification"
}

# Verify framework integration
verify_integration() {
    echo "Verifying framework integration..."
    
    if [ ! -d "$MOBILE_APP_DIR/unity/builds/ios/UnityFramework.framework" ]; then
        echo -e "${RED}✗ UnityFramework not copied to mobile app${NC}"
        exit 1
    fi
    
    if [ ! -d "$MOBILE_APP_DIR/ios/Frameworks" ]; then
        echo -e "${RED}✗ Frameworks folder not in iOS directory${NC}"
        exit 1
    fi
    
    check_status "Framework integration verification"
}

# Verify pods installation
verify_pods() {
    echo "Verifying pods installation..."
    
    if [ ! -d "$MOBILE_APP_DIR/ios/Pods" ]; then
        echo -e "${RED}✗ Pods not installed${NC}"
        exit 1
    fi
    
    check_status "Pods verification"
}

# Main verification flow
main() {
    echo "Starting build verification..."
    verify_unity_build
    verify_target_membership
    verify_native_proxy
    verify_framework_settings
    verify_integration
    verify_pods
    echo -e "${GREEN}All verifications passed successfully!${NC}"
}

main
