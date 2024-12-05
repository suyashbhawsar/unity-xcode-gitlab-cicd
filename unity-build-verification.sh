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

verify_target_membership() {
    echo "Verifying Data folder target membership..."
    
    # Use xcodebuild to list targets and check UnityFramework
    TARGET_INFO=$(xcrun xcodebuild -project "$UNITY_BUILD_DIR/$XCODE_PROJECT" -list)
    if echo "$TARGET_INFO" | grep -q "UnityFramework"; then
        # Check if Unity-iPhone is unchecked and UnityFramework is checked
        PBXPROJ_PATH="$UNITY_BUILD_DIR/$XCODE_PROJECT/project.pbxproj"
        if grep -q "Unity-iPhone.*= {.*};" "$PBXPROJ_PATH" && grep -q "UnityFramework.*= {.*enabled = 1" "$PBXPROJ_PATH"; then
            check_status "Target membership verification"
        else
            echo -e "${RED}✗ Incorrect target membership settings${NC}"
            exit 1
        fi
    else
        echo -e "${RED}✗ UnityFramework target not found${NC}"
        exit 1
    fi
}

verify_native_proxy() {
    echo "Verifying NativeCallProxy.h..."
    
    NATIVE_PROXY_PATH="$UNITY_BUILD_DIR/Unity-iPhone/Libraries/Plugins/iOS/NativeCallProxy.h"
    if [ ! -f "$NATIVE_PROXY_PATH" ]; then
        echo -e "${RED}✗ NativeCallProxy.h not found${NC}"
        exit 1
    fi
    
    # Check if file is included in public headers
    TARGET_INFO=$(xcrun xcodebuild -project "$UNITY_BUILD_DIR/$XCODE_PROJECT" -target UnityFramework -showBuildSettings | grep "PUBLIC_HEADERS_FOLDER_PATH")
    if echo "$TARGET_INFO" | grep -q "NativeCallProxy.h"; then
        check_status "NativeCallProxy.h visibility verification"
    else
        echo -e "${RED}✗ NativeCallProxy.h not set as public${NC}"
        exit 1
    fi
}

verify_framework_settings() {
    echo "Verifying framework embedding..."
    PBXPROJ_PATH="$UNITY_BUILD_DIR/$XCODE_PROJECT/project.pbxproj"
    
    # Check signing settings for both targets
    SIGNING_CHECK=$(xcrun xcodebuild -project "$UNITY_BUILD_DIR/$XCODE_PROJECT" -list | grep -E "Unity-iPhone|UnityFramework")
    if [ -z "$SIGNING_CHECK" ]; then
        echo -e "${RED}✗ Signing verification failed${NC}"
        exit 1
    fi
    
    # Check framework embedding settings
    if grep -q "FrameworksBuildPhase" "$PBXPROJ_PATH" && grep -q "Embed Frameworks" "$PBXPROJ_PATH"; then
        check_status "Framework embedding verification"
    else
        echo -e "${RED}✗ Framework embedding not properly configured${NC}"
        exit 1
    fi
}

verify_framework_copy() {
    echo "Verifying framework copy..."
    
    # Check if UnityFramework is copied
    if [ ! -d "$MOBILE_APP_DIR/unity/builds/ios/UnityFramework.framework" ]; then
        echo -e "${RED}✗ UnityFramework not copied to mobile app${NC}"
        exit 1
    fi
    
    # Verify Frameworks folder move
    if [ ! -d "$MOBILE_APP_DIR/ios/Frameworks" ]; then
        echo -e "${RED}✗ Frameworks folder not moved to iOS directory${NC}"
        exit 1
    fi
    
    check_status "Framework copy verification"
}

verify_pods() {
    echo "Verifying pods installation..."
    
    # Check if Pods are properly installed
    if [ ! -d "$MOBILE_APP_DIR/ios/Pods" ]; then
        echo -e "${RED}✗ Pods not installed${NC}"
        exit 1
    fi
    
    # Verify Podfile.lock
    if [ ! -f "$MOBILE_APP_DIR/ios/Podfile.lock" ]; then
        echo -e "${RED}✗ Podfile.lock not found${NC}"
        exit 1
    fi
    
    check_status "Pods verification"
}

perform_pod_install() {
    echo "Performing pod install..."
    
    # Remove existing Pods and Podfile.lock
    rm -rf "$MOBILE_APP_DIR/ios/Pods"
    rm -f "$MOBILE_APP_DIR/ios/Podfile.lock"
    
    # Run pod install using npx
    cd "$MOBILE_APP_DIR" && npx pod-install
    check_status "Pod installation"
}

main() {
    echo "Starting build verification..."
    verify_unity_build
    verify_target_membership
    verify_native_proxy
    verify_framework_settings
    verify_framework_copy
    verify_pods
    perform_pod_install
    echo -e "${GREEN}All verifications passed successfully!${NC}"
}

# Execute main function
main
