#!/bin/bash

# Configuration
PROJECT_FILE="Unity-iPhone.xcodeproj/project.pbxproj"
TEMP_FILE="${PROJECT_FILE}.temp"

# List of frameworks to process
declare -a FRAMEWORKS=(
    "AgoraAiEchoCancellationExtension"
    "AgoraAiNoiseSuppressionExtension"
    "AgoraAudioBeautyExtension"
    "AgoraCore"
    "AgoraDrmLoaderExtension"
    "Agorafdkaac"
    "Agoraffmpeg"
    "AgoraRtcKit"
    "AgoraRtcWrapper"
    "AgoraSoundTouch"
    "AgoraSpatialAudioExtension"
)

# Function to check if file exists
check_file() {
    if [ ! -f "$PROJECT_FILE" ]; then
        echo "Error: $PROJECT_FILE not found!"
        exit 1
    fi
}

# Main processing function
process_file() {
    echo "Processing $PROJECT_FILE..."
    
    # Create temporary file
    cp "$PROJECT_FILE" "$TEMP_FILE"
    
    while IFS= read -r line; do
        # Write the current line to output
        echo "$line"
        
        # Check if line contains framework reference
        for framework in "${FRAMEWORKS[@]}"; do
            if [[ $line =~ [[:space:]]*[A-F0-9]{24}[[:space:]]*\*[[:space:]]*\/${framework}\.framework[[:space:]]*in[[:space:]]*Frameworks ]]; then
                # Extract UUID and fileRef from the original line
                uuid=$(echo "$line" | grep -o '^[[:space:]]*[A-F0-9]\{24\}')
                fileRef=$(echo "$line" | grep -o 'fileRef = [A-F0-9]\{24\}')
                
                # Create the Embed Frameworks entry
                embed_line="$uuid /* $framework.framework in Embed Frameworks */ = {isa = PBXBuildFile; $fileRef; settings = {ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }; };"
                echo "$embed_line"
            fi
        done
    done < "$PROJECT_FILE" > "$TEMP_FILE"
    
    # Replace original file with modified version
    mv "$TEMP_FILE" "$PROJECT_FILE"
}

# Main execution
echo "Starting Xcode project modification..."

# Check if project file exists
check_file

# Process file
process_file

echo "Modification completed successfully!"
