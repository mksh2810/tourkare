#!/bin/bash

set -e

FLUTTER_VERSION="3.47.1"
FLUTTER_DIR="$HOME/flutter"

echo "Installing Flutter $FLUTTER_VERSION..."

if [ ! -d "$FLUTTER_DIR" ]; then
    git clone \
        --branch "$FLUTTER_VERSION" \
        --depth 1 \
        https://github.com/flutter/flutter.git \
        "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "Flutter version:"
flutter --version

echo "Getting Flutter dependencies..."
flutter pub get

echo "Building Flutter web..."
flutter build web --release

echo "Flutter web build completed."