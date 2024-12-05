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

# Configure Xcode project settings
configure_xcode_project() {
    echo "Configuring Xcode project settings..."
    
    # Uncheck Unity-iPhone and check UnityFramework in Data folder
    /usr/libexec/PlistBuddy -c "Set :objects:${DATA_FOLDER_ID}:target:Unity-iPhone 0" \
        "$UNITY_BUILD_DIR/$XCODE_PROJECT/project.pbxproj"
    /usr/libexec/PlistBuddy -c "Set :objects:${DATA_FOLDER_ID}:target:UnityFramework 1" \
        "$UNITY_BUILD_DIR/$XCODE_PROJECT/project.pbxproj"
    
    check_status "Xcode project configuration"
}

# Set NativeCallProxy.h to public
set_native_proxy_public() {
    echo "Setting NativeCallProxy.h to public..."
    
    # Find the file reference ID for NativeCallProxy.h
    NATIVE_PROXY_FILE_REF=$(grep -A 1 "NativeCallProxy.h" "$UNITY_BUILD_DIR/$XCODE_PROJECT/project.pbxproj" | \
        grep "isa = PBXFileReference" | cut -d '"' -f 2)
    
    # Set the file to public
    /usr/libexec/PlistBuddy -c "Add :objects:$NATIVE_PROXY_FILE_REF:attributes:Public bool true" \
        "$UNITY_BUILD_DIR/$XCODE_PROJECT/project.pbxproj"
    
    check_status "NativeCallProxy.h visibility setting"
}

# Configure framework embedding
configure_framework_embedding() {
    echo "Configuring framework embedding..."
    
    # Set UnityFramework to "Embed & Sign"
    xcodeproj="$UNITY_BUILD_DIR/$XCODE_PROJECT"
    ruby -e "
        require 'xcodeproj'
        project = Xcodeproj::Project.open('$xcodeproj')
        target = project.targets.find { |t| t.name == 'UnityFramework' }
        target.frameworks_build_phase.files.each do |file|
            file.settings ||= {}
            file.settings['ATTRIBUTES'] = ['CodeSignOnCopy', 'RemoveHeadersOnCopy']
        end
        project.save
    "
    
    check_status "Framework embedding configuration"
}

# Move frameworks to correct locations
move_frameworks() {
    echo "Moving frameworks to correct locations..."
    
    # Create directories if they don't exist
    mkdir -p "$MOBILE_APP_DIR/unity/builds/ios"
    mkdir -p "$MOBILE_APP_DIR/ios"
    
    # Move UnityFramework
    cp -R "$UNITY_BUILD_DIR/Products/UnityFramework" "$MOBILE_APP_DIR/unity/builds/ios/"
    
    # Move Frameworks folder
    mv "$MOBILE_APP_DIR/unity/builds/ios/UnityFramework/Frameworks" "$MOBILE_APP_DIR/ios/"
    
    check_status "Framework relocation"
}

# Install pods
install_pods() {
    echo "Installing pods..."
    
    cd "$MOBILE_APP_DIR/ios" || exit 1
    rm -rf Pods
    rm -f Podfile.lock
    npx pod-install
    
    check_status "Pod installation"
}

# Main execution flow
main() {
    echo "Starting build process..."
    
    verify_unity_build
    configure_xcode_project
    set_native_proxy_public
    configure_framework_embedding
    move_frameworks
    install_pods
    
    echo -e "${GREEN}Build process completed successfully!${NC}"
}

main
