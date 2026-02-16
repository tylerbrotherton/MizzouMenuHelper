# Mizzou Dining - Installation Guide

## Quick Start

### 1. Install Dependencies

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install valac meson ninja-build libgtk-3-dev libsoup2.4-dev libjson-glib-dev libgee-0.8-dev
```

**Fedora:**
```bash
sudo dnf install vala meson gtk3-devel libsoup-devel json-glib-devel libgee-devel
```

**Arch Linux:**
```bash
sudo pacman -S vala meson gtk3 libsoup json-glib libgee
```

### 2. Build the Application

```bash
# Use the automated build script
./build.sh

# Or build manually
meson setup build
meson compile -C build
```

### 3. Run the Application

```bash
./build/mizzou-dining
```

### 4. (Optional) Install System-Wide

```bash
sudo meson install -C build
```

After installation, the app will be available in your application menu under "Utilities" or by running `mizzou-dining` from the terminal.

## Detailed Installation Steps

### Step 1: Install System Dependencies

The application requires several libraries and build tools:

#### Runtime Dependencies
- **GTK+ 3.0**: GUI toolkit
- **libsoup 2.4**: HTTP client library
- **json-glib 1.0**: JSON parsing library
- **libgee 0.8**: Collection library

#### Build Tools
- **Vala compiler** (valac): Compiles Vala to C
- **Meson**: Build system
- **Ninja**: Build tool (usually installed with Meson)
- **pkg-config**: Helps find libraries

### Step 2: Download or Extract Source Code

If you received this as an archive:
```bash
tar -xzvf mizzou-dining.tar.gz
cd mizzou-dining
```

If you're cloning from a repository:
```bash
git clone <repository-url>
cd mizzou-dining
```

### Step 3: Build the Application

#### Option A: Automated Build (Recommended)
```bash
./build.sh
```

This script will:
- Check for all required dependencies
- Clean any previous builds
- Configure the build
- Compile the application
- Show you how to run it

#### Option B: Manual Build
```bash
# Configure
meson setup build

# Compile
meson compile -C build

# (Optional) Run tests
meson test -C build
```

### Step 4: Run the Application

#### Without Installing
```bash
./build/mizzou-dining
```

#### Install and Run
```bash
# Install
sudo meson install -C build

# Run from anywhere
mizzou-dining
```

The application will also appear in your desktop environment's application menu.

### Step 5: (Optional) Create Desktop Launcher

If you prefer not to install system-wide but want a desktop launcher:

```bash
mkdir -p ~/.local/share/applications
cp edu.missouri.dining.desktop ~/.local/share/applications/
sed -i "s|@bindir@|$(pwd)/build|g" ~/.local/share/applications/edu.missouri.dining.desktop
```

## Uninstallation

If installed system-wide:
```bash
cd /path/to/mizzou-dining
sudo ninja uninstall -C build
```

If using local desktop launcher:
```bash
rm ~/.local/share/applications/edu.missouri.dining.desktop
```

Remove cache files:
```bash
rm -rf ~/.cache/mizzou-dining
```

## Troubleshooting Installation

### "command not found: valac"
You need to install the Vala compiler:
```bash
sudo apt install valac  # Ubuntu/Debian
sudo dnf install vala   # Fedora
sudo pacman -S vala     # Arch
```

### "Package 'gtk+-3.0' not found"
Install GTK+ development files:
```bash
sudo apt install libgtk-3-dev  # Ubuntu/Debian
sudo dnf install gtk3-devel    # Fedora
sudo pacman -S gtk3            # Arch
```

### "Package 'libsoup-2.4' not found"
Install libsoup development files:
```bash
sudo apt install libsoup2.4-dev  # Ubuntu/Debian
sudo dnf install libsoup-devel   # Fedora
sudo pacman -S libsoup           # Arch
```

### "Package 'json-glib-1.0' not found"
Install json-glib development files:
```bash
sudo apt install libjson-glib-dev  # Ubuntu/Debian
sudo dnf install json-glib-devel   # Fedora
sudo pacman -S json-glib           # Arch
```

### "Package 'gee-0.8' not found"
Install libgee development files:
```bash
sudo apt install libgee-0.8-dev  # Ubuntu/Debian
sudo dnf install libgee-devel    # Fedora
sudo pacman -S libgee            # Arch
```

### Build Fails with Vala Errors
Make sure you have a recent version of Vala:
```bash
valac --version  # Should be 0.48 or newer
```

### Permission Denied on build.sh
Make the script executable:
```bash
chmod +x build.sh
```

## Distribution-Specific Notes

### Ubuntu 20.04 LTS
All dependencies are available in the default repositories. No special steps needed.

### Ubuntu 18.04 LTS
You may need to enable universe repository:
```bash
sudo add-apt-repository universe
sudo apt update
```

### Fedora
All dependencies are in the default repositories.

### Arch Linux
All dependencies are in the official repositories.

### Pop!_OS
Same as Ubuntu, all dependencies available.

### Linux Mint
Same as Ubuntu, all dependencies available.

## Building a Package

### Debian/Ubuntu Package

Create a simple package:
```bash
# Install packaging tools
sudo apt install devscripts

# Build
meson setup build --prefix=/usr
DESTDIR=$(pwd)/debian/mizzou-dining meson install -C build

# Create package structure
mkdir -p debian/mizzou-dining/DEBIAN
cat > debian/mizzou-dining/DEBIAN/control << EOF
Package: mizzou-dining
Version: 1.0.0
Architecture: amd64
Maintainer: Your Name <your.email@example.com>
Depends: libgtk-3-0, libsoup2.4-1, libjson-glib-1.0-0, libgee-2
Description: Mizzou dining hall menu viewer
 A GNOME application for viewing University of Missouri dining menus.
EOF

# Build package
dpkg-deb --build debian/mizzou-dining
```

### Flatpak (Universal)

For distribution across all Linux systems, consider building a Flatpak (not included in this quick guide).

## Verifying Installation

After installation, verify it works:

```bash
# Check if binary exists
which mizzou-dining

# Check desktop file
ls /usr/share/applications/edu.missouri.dining.desktop

# Check icon
ls /usr/share/icons/hicolor/scalable/apps/edu.missouri.dining.svg

# Run the application
mizzou-dining
```

## Next Steps

After installation:
1. Launch the application
2. Select a dining location
3. View the current week's menu
4. Click refresh to update menus

See README.md for usage instructions and features.
