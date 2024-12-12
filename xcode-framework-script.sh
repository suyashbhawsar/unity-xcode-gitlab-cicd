#!/bin/bash

# Configuration
PROJECT_FILE="Unity-iPhone.xcodeproj/project.pbxproj"

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
    
    # Read and modify the file in-place
    awk -v frameworks="$(IFS=','; echo "${FRAMEWORKS[*]}")" '
    BEGIN {
        split(frameworks, fwArray, ",");
    }
    {
        print $0;  # Print the current line as is

        # Check if the line matches any framework reference
        for (fw in fwArray) {
            framework = fwArray[fw];
            if ($0 ~ "[[:space:]]*[A-F0-9]{24}[[:space:]]*\\*[[:space:]]*/" framework "\\.framework[[:space:]]*in[[:space:]]*Frameworks") {
                match($0, /^[[:space:]]*[A-F0-9]{24}/, uuid);
                match($0, /fileRef = [A-F0-9]{24}/, fileRef);
                if (uuid[0] && fileRef[0]) {
                    embed_line = uuid[0] " /* " framework ".framework in Embed Frameworks */ = {isa = PBXBuildFile; " fileRef[0] "; settings = {ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }; };";
                    print embed_line;  # Add the Embed Framework entry
                }
            }
        }
    }' "$PROJECT_FILE" > "$PROJECT_FILE.modified" && mv "$PROJECT_FILE.modified" "$PROJECT_FILE"
}

# Main execution
echo "Starting Xcode project modification..."

# Check if project file exists
check_file

# Process file
process_file

echo "Modification completed successfully!"
