#!/bin/sh

UFW_TARGET=${PROJECT}
UFW_BUILD_DIR="../build"

if [ -z ${SDK_NAME} ]; then
# Use the latest iphoneos SDK available
UFW_GREP_RESULT=$(xcodebuild -showsdks | grep -o "iphoneos.*$")
while read -r line; do
UFW_SDK_VERSION="${line}"
done <<< "${UFW_GREP_RESULT}"
else
# Use the SDK specified by XCode
UFW_SDK_VERSION="${SDK_NAME}"
fi

UFW_SDK_VERSION=$(echo "${UFW_SDK_VERSION}" | grep -o "[0-9].*$")
UFW_IPHONE_DIR="${UFW_BUILD_DIR}/Release-iphoneos"
UFW_SIMULATOR_DIR="${UFW_BUILD_DIR}/Release-iphonesimulator"
UFW_UNIVERSAL_DIR="${UFW_BUILD_DIR}/Release-universal"
UFW_EXE_PATH="lib${PROJECT}.a"

# Build Framework

rm -rf "${UFW_UNIVERSAL_DIR}"

xcodebuild -target "${UFW_TARGET}" -project CorePlot-CocoaTouch.xcodeproj -configuration Release -sdk iphoneos${UFW_SDK_VERSION} clean build
if [ "$?" != "0" ]; then echo >&2 "Error: xcodebuild failed"; exit 1; fi
xcodebuild -target "${UFW_TARGET}" -project CorePlot-CocoaTouch.xcodeproj -configuration Release -sdk iphonesimulator${UFW_SDK_VERSION} clean build
if [ "$?" != "0" ]; then echo >&2 "Error: xcodebuild failed"; exit 1; fi

mkdir -p "${UFW_UNIVERSAL_DIR}"
if [ "$?" != "0" ]; then echo >&2 "Error: mkdir failed"; exit 1; fi

lipo -create -output "${UFW_UNIVERSAL_DIR}/${UFW_EXE_PATH}" "${UFW_IPHONE_DIR}/${UFW_EXE_PATH}" "${UFW_SIMULATOR_DIR}/${UFW_EXE_PATH}"
if [ "$?" != "0" ]; then echo >&2 "Error: lipo failed"; exit 1; fi

