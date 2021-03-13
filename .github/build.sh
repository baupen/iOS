#!/bin/bash

xcodebuild clean build \
	-sdk iphoneos \
	-project "Issue Manager/Issue Manager.xcodeproj" \
	-scheme "Issue Manager" \
	CODE_SIGN_IDENTITY="" \
	CODE_SIGNING_REQUIRED=NO \
	CODE_SIGNING_ALLOWED=NO
