#!/bin/bash

# Exit on error
set -e

echo "----------------------------------------------------------------"
echo "  Starting Flutter Web Build for Vercel"
echo "----------------------------------------------------------------"

# Check if Flutter is already available (cached)
if [ -d "_flutter" ]; then
    echo "Flutter SDK found in cache."
    export PATH="$PATH:`pwd`/_flutter/bin"
else
    echo "Downloading Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 _flutter
    export PATH="$PATH:`pwd`/_flutter/bin"
fi

echo "Flutter Version:"
flutter --version

echo "----------------------------------------------------------------"
echo "  Building Project"
echo "----------------------------------------------------------------"

# Enable web support
flutter config --enable-web

# Clean previous builds
flutter clean

# Install dependencies
flutter pub get

# Build the web application
# --release: Optimized build
# --no-tree-shake-icons: Prevents icon font issues in some deployments
flutter build web --release --no-tree-shake-icons

echo "----------------------------------------------------------------"
echo "  Build Complete! Output: build/web"
echo "----------------------------------------------------------------"
