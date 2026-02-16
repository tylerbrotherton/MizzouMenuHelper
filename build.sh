#!/bin/bash

# Mizzou Dining - Build Script
# This script automates the build process

set -e  # Exit on error

echo "═══════════════════════════════════════════"
echo "  Mizzou Dining Menu Fetcher - Build Script"
echo "═══════════════════════════════════════════"
echo ""

# Check for required tools
echo "Checking dependencies..."

command -v valac >/dev/null 2>&1 || {
    echo "ERROR: Vala compiler (valac) not found!"
    echo "Install with: sudo apt install valac"
    exit 1
}

command -v meson >/dev/null 2>&1 || {
    echo "ERROR: Meson build system not found!"
    echo "Install with: sudo apt install meson"
    exit 1
}

echo "✓ All build tools found"
echo ""

# Check for development libraries
echo "Checking development libraries..."

pkg-config --exists gtk+-3.0 || {
    echo "ERROR: GTK+ 3.0 development files not found!"
    echo "Install with: sudo apt install libgtk-3-dev"
    exit 1
}

pkg-config --exists libsoup-2.4 || {
    echo "ERROR: libsoup development files not found!"
    echo "Install with: sudo apt install libsoup2.4-dev"
    exit 1
}

pkg-config --exists json-glib-1.0 || {
    echo "ERROR: json-glib development files not found!"
    echo "Install with: sudo apt install libjson-glib-dev"
    exit 1
}

pkg-config --exists gee-0.8 || {
    echo "ERROR: libgee development files not found!"
    echo "Install with: sudo apt install libgee-0.8-dev"
    exit 1
}

echo "✓ All libraries found"
echo ""

# Clean previous build
if [ -d "build" ]; then
    echo "Cleaning previous build..."
    rm -rf build
    echo "✓ Clean complete"
    echo ""
fi

# Setup build directory
echo "Setting up build directory..."
meson setup build
echo "✓ Setup complete"
echo ""

# Compile
echo "Compiling application..."
meson compile -C build
echo "✓ Compilation complete"
echo ""

echo "═══════════════════════════════════════════"
echo "  Build successful!"
echo "═══════════════════════════════════════════"
echo ""
echo "To run the application:"
echo "  ./build/mizzou-dining"
echo ""
echo "To install system-wide:"
echo "  sudo meson install -C build"
echo ""
