#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters for summary
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# SDK override parameters
MSDK_IOS_ORG=""
MSDK_IOS_BRANCH=""
MSDK_ANDROID_ORG=""
MSDK_ANDROID_BRANCH=""
RN_FORCE_ORG=""
RN_FORCE_BRANCH=""

# Template and platform parameters
TEMPLATE_NAME=""
PLATFORM=""

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS")
            echo -e "${GREEN}✓ SUCCESS${NC}: $message"
            ((PASSED_TESTS++))
            ;;
        "FAILURE")
            echo -e "${RED}✗ FAILURE${NC}: $message"
            ((FAILED_TESTS++))
            ;;
        "INFO")
            echo -e "${YELLOW}ℹ INFO${NC}: $message"
            ;;
        "ERROR")
            echo -e "${RED}✗ ERROR${NC}: $message"
            ;;
    esac
}

# Function to override SDK dependencies in package.json
override_sdk_dependencies() {
    local package_json=$1

    if [ ! -f "$package_json" ]; then
        echo "Warning: package.json not found at $package_json"
        return 0
    fi

    local modified=false
    local temp_file="${package_json}.tmp"
    cp "$package_json" "$temp_file"

    # Override iOS SDK dependency
    if [ -n "$MSDK_IOS_ORG" ] || [ -n "$MSDK_IOS_BRANCH" ]; then
        local ios_org="${MSDK_IOS_ORG:-forcedotcom}"
        local ios_branch="${MSDK_IOS_BRANCH:-dev}"
        local new_ios_url="https://github.com/${ios_org}/SalesforceMobileSDK-iOS.git#${ios_branch}"

        if jq -e '.sdkDependencies."SalesforceMobileSDK-iOS"' "$temp_file" > /dev/null 2>&1; then
            echo "  Overriding SalesforceMobileSDK-iOS to: $new_ios_url"
            jq --arg url "$new_ios_url" '.sdkDependencies."SalesforceMobileSDK-iOS" = $url' "$temp_file" > "${temp_file}.new"
            mv "${temp_file}.new" "$temp_file"
            modified=true
        fi
    fi

    # Override Android SDK dependency
    if [ -n "$MSDK_ANDROID_ORG" ] || [ -n "$MSDK_ANDROID_BRANCH" ]; then
        local android_org="${MSDK_ANDROID_ORG:-forcedotcom}"
        local android_branch="${MSDK_ANDROID_BRANCH:-dev}"
        local new_android_url="https://github.com/${android_org}/SalesforceMobileSDK-Android.git#${android_branch}"

        if jq -e '.sdkDependencies."SalesforceMobileSDK-Android"' "$temp_file" > /dev/null 2>&1; then
            echo "  Overriding SalesforceMobileSDK-Android to: $new_android_url"
            jq --arg url "$new_android_url" '.sdkDependencies."SalesforceMobileSDK-Android" = $url' "$temp_file" > "${temp_file}.new"
            mv "${temp_file}.new" "$temp_file"
            modified=true
        fi
    fi

    # Override React Native Force dependency
    if [ -n "$RN_FORCE_ORG" ] || [ -n "$RN_FORCE_BRANCH" ]; then
        local rn_org="${RN_FORCE_ORG:-forcedotcom}"
        local rn_branch="${RN_FORCE_BRANCH:-dev}"
        local new_rn_url="git+https://github.com/${rn_org}/SalesforceMobileSDK-ReactNative.git#${rn_branch}"

        if jq -e '.dependencies."react-native-force"' "$temp_file" > /dev/null 2>&1; then
            echo "  Overriding react-native-force to: $new_rn_url"
            jq --arg url "$new_rn_url" '.dependencies."react-native-force" = $url' "$temp_file" > "${temp_file}.new"
            mv "${temp_file}.new" "$temp_file"
            modified=true
        fi
    fi

    # Apply changes if any modifications were made
    if [ "$modified" = true ]; then
        mv "$temp_file" "$package_json"
        echo "  SDK dependencies updated in package.json"
    else
        rm "$temp_file"
    fi
}

# Function to build iOS project (shared by native and React Native)
build_ios() {
    local template_name=$1
    local cd_back_count=$2  # Number of times to run "cd -"

    echo "Running xcodebuild..."
    
    # Check if workspace exists, otherwise use project
    WORKSPACE=$(ls -d *.xcworkspace 2>/dev/null | head -n 1)
    PROJECT=$(ls -d *.xcodeproj 2>/dev/null | head -n 1)
    
    if [ -n "$WORKSPACE" ]; then
        SCHEME="${WORKSPACE%.xcworkspace}"
        BUILD_TARGET="-workspace $WORKSPACE -scheme $SCHEME"
        echo "Building workspace: $WORKSPACE with scheme: $SCHEME"
    elif [ -n "$PROJECT" ]; then
        SCHEME="${PROJECT%.xcodeproj}"
        BUILD_TARGET="-project $PROJECT -scheme $SCHEME"
        echo "Building project: $PROJECT with scheme: $SCHEME"
    else
        print_status "FAILURE" "$template_name (iOS): No workspace or project found"
        for ((i=0; i<cd_back_count; i++)); do
            cd - > /dev/null
        done
        return 1
    fi
    
    if xcodebuild $BUILD_TARGET -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build CODE_SIGNING_ALLOWED=NO; then
        print_status "SUCCESS" "$template_name (iOS): Build successful"
        for ((i=0; i<cd_back_count; i++)); do
            cd - > /dev/null
        done
        return 0
    else
        print_status "FAILURE" "$template_name (iOS): xcodebuild failed"
        for ((i=0; i<cd_back_count; i++)); do
            cd - > /dev/null
        done
        return 1
    fi
}

# Function to build Android project (shared by native and React Native)
build_android() {
    local template_name=$1
    local cd_back_count=$2  # Number of times to run "cd -"

    echo "Running gradle assembleDebug..."
    if ./gradlew assembleDebug; then
        print_status "SUCCESS" "$template_name (Android): Build successful"
        for ((i=0; i<cd_back_count; i++)); do
            cd - > /dev/null
        done
        return 0
    else
        print_status "FAILURE" "$template_name (Android): gradle assembleDebug failed"
        for ((i=0; i<cd_back_count; i++)); do
            cd - > /dev/null
        done
        return 1
    fi
}

# Function to test iOS native template
test_ios_native() {
    local template_path=$1
    local template_name=$2

    ((TOTAL_TESTS++))
    echo ""
    echo "========================================"
    echo "Testing iOS Native: $template_name"
    echo "========================================"

    cd "$template_path" || {
        print_status "FAILURE" "$template_name (iOS): Failed to cd to template directory"
        return 1
    }

    # Remove mobile_sdk if it exists
    if [ -d "mobile_sdk" ]; then
        echo "Removing existing mobile_sdk..."
        rm -rf mobile_sdk
    fi

    # Override SDK dependencies if needed
    override_sdk_dependencies "package.json"

    # Run install.js
    echo "Running install.js..."
    if ! node install.js; then
        print_status "FAILURE" "$template_name (iOS): install.js failed"
        cd - > /dev/null
        return 1
    fi

    # Build using shared function (cd back once)
    build_ios "$template_name" 1
}

# Function to test Android native template
test_android_native() {
    local template_path=$1
    local template_name=$2

    ((TOTAL_TESTS++))
    echo ""
    echo "========================================"
    echo "Testing Android Native: $template_name"
    echo "========================================"

    cd "$template_path" || {
        print_status "FAILURE" "$template_name (Android): Failed to cd to template directory"
        return 1
    }

    # Remove mobile_sdk if it exists
    if [ -d "mobile_sdk" ]; then
        echo "Removing existing mobile_sdk..."
        rm -rf mobile_sdk
    fi

    # Override SDK dependencies if needed
    override_sdk_dependencies "package.json"

    # Run install.js
    echo "Running install.js..."
    if ! node install.js; then
        print_status "FAILURE" "$template_name (Android): install.js failed"
        cd - > /dev/null
        return 1
    fi

    # Build using shared function (cd back once)
    build_android "$template_name" 1
}

# Function to test iOS React Native template
test_ios_react_native() {
    local template_path=$1
    local template_name=$2

    ((TOTAL_TESTS++))
    echo ""
    echo "========================================"
    echo "Testing iOS React Native: $template_name"
    echo "========================================"

    cd "$template_path" || {
        print_status "FAILURE" "$template_name (iOS): Failed to cd to template directory"
        return 1
    }

    # Remove mobile_sdk if it exists
    if [ -d "mobile_sdk" ]; then
        echo "Removing existing mobile_sdk..."
        rm -rf mobile_sdk
    fi

    # Override SDK dependencies if needed
    override_sdk_dependencies "package.json"

    # Run installios.js
    echo "Running installios.js..."
    if ! node installios.js; then
        print_status "FAILURE" "$template_name (iOS): installios.js failed"
        cd - > /dev/null
        return 1
    fi

    # Navigate to ios directory
    cd ios || {
        print_status "FAILURE" "$template_name (iOS): Failed to cd to ios directory"
        cd - > /dev/null
        return 1
    }

    # Build using shared function (cd back twice - ios/ and template/)
    build_ios "$template_name" 2
}

# Function to test Android React Native template
test_android_react_native() {
    local template_path=$1
    local template_name=$2

    ((TOTAL_TESTS++))
    echo ""
    echo "========================================"
    echo "Testing Android React Native: $template_name"
    echo "========================================"

    cd "$template_path" || {
        print_status "FAILURE" "$template_name (Android): Failed to cd to template directory"
        return 1
    }

    # Remove mobile_sdk if it exists
    if [ -d "mobile_sdk" ]; then
        echo "Removing existing mobile_sdk..."
        rm -rf mobile_sdk
    fi

    # Override SDK dependencies if needed
    override_sdk_dependencies "package.json"

    # Run installandroid.js
    echo "Running installandroid.js..."
    if ! node installandroid.js; then
        print_status "FAILURE" "$template_name (Android): installandroid.js failed"
        cd - > /dev/null
        return 1
    fi

    # Navigate to android directory
    cd android || {
        print_status "FAILURE" "$template_name (Android): Failed to cd to android directory"
        cd - > /dev/null
        return 1
    }

    # Build using shared function (cd back twice - android/ and template/)
    build_android "$template_name" 2
}

# Function to test a single template
test_template() {
    local template_name=$1
    local platform=$2
    local script_dir=$3

    # Read templates.json
    local template_info=$(jq -r ".[] | select(.path == \"$template_name\")" "$script_dir/templates.json")

    if [ -z "$template_info" ]; then
        print_status "ERROR" "Template '$template_name' not found in templates.json"
        return 1
    fi

    local app_type=$(echo "$template_info" | jq -r '.appType')
    local platforms=$(echo "$template_info" | jq -r '.platforms[]')
    local template_path="$script_dir/$template_name"

    # Check if template is hybrid
    if [[ "$app_type" == hybrid* ]]; then
        print_status "INFO" "$template_name: Hybrid templates are not supported"
        return 0
    fi

    # Determine which platforms to test
    local platforms_to_test=()
    if [ -n "$platform" ]; then
        # Check if requested platform is supported
        if echo "$platforms" | grep -q "^$platform$"; then
            platforms_to_test=("$platform")
        fi
    else
        # Test all supported platforms
        while IFS= read -r p; do
            platforms_to_test+=("$p")
        done <<< "$platforms"
    fi

    # Test each platform
    for plat in "${platforms_to_test[@]}"; do
        if [ "$app_type" == "react_native" ]; then
            if [ "$plat" == "ios" ]; then
                test_ios_react_native "$template_path" "$template_name"
            elif [ "$plat" == "android" ]; then
                test_android_react_native "$template_path" "$template_name"
            fi
        elif [[ "$app_type" == native* ]]; then
            if [ "$plat" == "ios" ]; then
                test_ios_native "$template_path" "$template_name"
            elif [ "$plat" == "android" ]; then
                test_android_native "$template_path" "$template_name"
            fi
        fi
    done
}

# Function to parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --template)
                TEMPLATE_NAME="$2"
                shift 2
                ;;
            --platform)
                PLATFORM="$2"
                shift 2
                ;;
            --msdk-ios-org)
                MSDK_IOS_ORG="$2"
                shift 2
                ;;
            --msdk-ios-branch)
                MSDK_IOS_BRANCH="$2"
                shift 2
                ;;
            --msdk-android-org)
                MSDK_ANDROID_ORG="$2"
                shift 2
                ;;
            --msdk-android-branch)
                MSDK_ANDROID_BRANCH="$2"
                shift 2
                ;;
            --rn-force-org)
                RN_FORCE_ORG="$2"
                shift 2
                ;;
            --rn-force-branch)
                RN_FORCE_BRANCH="$2"
                shift 2
                ;;
            --help|-h)
                print_help
                exit 0
                ;;
            *)
                echo "Error: Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Function to print help
print_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Test Mobile SDK templates by building them on specified platforms.

Options:
  --template TEMPLATE_NAME        Name of template to test (optional, tests all if not specified)
  --platform PLATFORM             Platform to test: ios or android (optional, tests all supported if not specified)
  --msdk-ios-org ORG              Override iOS SDK GitHub organization (default: forcedotcom)
  --msdk-ios-branch BRANCH        Override iOS SDK branch (default: dev)
  --msdk-android-org ORG          Override Android SDK GitHub organization (default: forcedotcom)
  --msdk-android-branch BRANCH    Override Android SDK branch (default: dev)
  --rn-force-org ORG              Override React Native SDK GitHub organization (default: forcedotcom)
  --rn-force-branch BRANCH        Override React Native SDK branch (default: dev)
  -h, --help                      Show this help message

Examples:
  # Test a specific template on all platforms
  $0 --template iOSNativeSwiftTemplate

  # Test a specific template on iOS only
  $0 --template iOSNativeSwiftTemplate --platform ios

  # Test all templates on a specific platform
  $0 --platform android

  # Test with custom iOS SDK branch
  $0 --msdk-ios-org wmathurin --msdk-ios-branch feature_branch --template iOSNativeSwiftTemplate --platform ios

  # Test React Native with custom branches for all SDKs
  $0 --msdk-ios-branch v13.0 --msdk-android-branch v13.0 --rn-force-branch v13.0 --template ReactNativeTemplate

  # Test all templates
  $0
EOF
}

# Main script
main() {
    # Parse command line arguments
    parse_args "$@"

    # Get the script directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Check if templates.json exists
    if [ ! -f "$script_dir/templates.json" ]; then
        print_status "ERROR" "templates.json not found in script directory"
        exit 1
    fi

    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_status "ERROR" "jq is required but not installed. Please install jq."
        exit 1
    fi

    echo "========================================"
    echo "Template Build Test"
    echo "========================================"

    # Print SDK override information if any are set
    if [ -n "$MSDK_IOS_ORG" ] || [ -n "$MSDK_IOS_BRANCH" ] || \
       [ -n "$MSDK_ANDROID_ORG" ] || [ -n "$MSDK_ANDROID_BRANCH" ] || \
       [ -n "$RN_FORCE_ORG" ] || [ -n "$RN_FORCE_BRANCH" ]; then
        echo "SDK Dependency Overrides:"
        [ -n "$MSDK_IOS_ORG" ] && echo "  iOS SDK Org: $MSDK_IOS_ORG"
        [ -n "$MSDK_IOS_BRANCH" ] && echo "  iOS SDK Branch: $MSDK_IOS_BRANCH"
        [ -n "$MSDK_ANDROID_ORG" ] && echo "  Android SDK Org: $MSDK_ANDROID_ORG"
        [ -n "$MSDK_ANDROID_BRANCH" ] && echo "  Android SDK Branch: $MSDK_ANDROID_BRANCH"
        [ -n "$RN_FORCE_ORG" ] && echo "  React Native SDK Org: $RN_FORCE_ORG"
        [ -n "$RN_FORCE_BRANCH" ] && echo "  React Native SDK Branch: $RN_FORCE_BRANCH"
        echo "========================================"
    fi

    if [ -z "$TEMPLATE_NAME" ]; then
        # Test all templates
        print_status "INFO" "No template specified, testing all templates..."
        local templates=$(jq -r '.[].path' "$script_dir/templates.json")
        while IFS= read -r tmpl; do
            test_template "$tmpl" "$PLATFORM" "$script_dir"
        done <<< "$templates"
    else
        # Test specific template
        test_template "$TEMPLATE_NAME" "$PLATFORM" "$script_dir"
    fi

    # Print summary
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    echo "========================================"

    # Exit with failure if any tests failed
    if [ $FAILED_TESTS -gt 0 ]; then
        exit 1
    fi
}

# Run main function
main "$@"
