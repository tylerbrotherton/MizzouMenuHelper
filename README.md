# Mizzou Dining Menu Fetcher

A native GNOME application for viewing University of Missouri dining hall menus.

## Features

- **Three Dining Locations**: The MARK on 5th Street, The Restaurants at Southwest, and Plaza 900 Dining
- **Smart Caching**: Automatically caches menus to reduce network usage and improve performance
- **Automatic Cleanup**: Old cache entries (>7 days) are automatically deleted
- **Clean Interface**: Native GTK+ interface that follows GNOME design guidelines
- **Offline Support**: View previously cached menus when offline

## Screenshots

The application features a clean two-pane interface:
- Left sidebar: List of dining locations
- Right panel: Weekly menu for the selected location, organized by day and meal

## Dependencies

### Runtime Dependencies
- GTK+ 3.0
- libsoup 2.4
- json-glib 1.0
- libgee 0.8

### Build Dependencies
- Vala compiler (valac)
- Meson build system
- Ninja build tool
- pkg-config

## Installation

### Arch Linux / Manjaro
```bash
sudo pacman -S vala meson gtk3 libsoup json-glib libgee
```

### Ubuntu / Debian
```bash
sudo apt install valac meson ninja-build libgtk-3-dev libsoup2.4-dev libjson-glib-dev libgee-0.8-dev
```

### Fedora
```bash
sudo dnf install vala meson gtk3-devel libsoup-devel json-glib-devel libgee-devel
```

## Building

```bash
# Navigate to the project directory
cd /path/to/mizzou-dining

# Set up build directory
meson setup build

# Compile the application
meson compile -C build

# (Optional) Install system-wide
sudo meson install -C build
```

## Running

### Without Installing
```bash
./build/mizzou-dining
```

### After Installing
```bash
mizzou-dining
```

Or launch from your application menu.

## Usage

1. **Select a Location**: Click on a dining hall name in the left sidebar
2. **View Menu**: The current week's menu will display on the right
3. **Refresh Menus**: Click the refresh button in the header to update all menus
4. **Browse Days**: Scroll through different days of the week for each location

## Cache Management

The application automatically:
- Caches menus in `~/.cache/mizzou-dining/`
- Stores menus for up to 24 hours before requesting fresh data
- Deletes cache files older than 7 days
- Uses JSON format for easy inspection

## Menu Data Structure

The application parses HTML from dining.missouri.edu and extracts:
- Day of the week
- Meal times (Breakfast, Lunch, Dinner)
- Menu items for each meal
- Stations (HOMEFARE, GRILL, DESSERT, etc.)

## Architecture

### Components

1. **Main Application** (`MizzouDining`)
   - GTK application shell
   - UI management
   - Network requests

2. **Menu Parser**
   - HTML parsing using string operations
   - Extracts structured menu data from dining website

3. **Cache Manager** (`MenuCache`)
   - Saves menus as JSON files
   - Validates cache freshness (24 hours)
   - Cleans up old entries (>7 days)

4. **Data Models**
   - `MenuData`: Complete menu with timestamp
   - `DayMenu`: Single day's meals
   - `Meal`: Single meal period with items

## Technical Details

### Language: Vala
Vala was chosen because it:
- Compiles to C for maximum performance
- Provides modern language features (classes, properties, signals)
- Has excellent GTK+ integration
- Generates small, fast binaries
- Is the preferred language for GNOME applications

### HTML Parsing
The app uses basic string parsing rather than a full HTML parser to:
- Minimize dependencies
- Reduce binary size
- Improve startup time
- Work with the specific, consistent structure of the dining website

### Caching Strategy
- **Storage**: JSON files in XDG cache directory
- **Key**: MD5 hash of URL
- **Validation**: 24-hour freshness window
- **Cleanup**: 7-day retention period

## Troubleshooting

### Build Errors

**"Package 'gtk+-3.0' not found"**
```bash
# Install GTK+ development files (see Installation section)
```

**"valac: command not found"**
```bash
# Install Vala compiler (see Installation section)
```

### Runtime Issues

**Application doesn't start**
```bash
# Run from terminal to see error messages
./build/mizzou-dining
```

**Menus not loading**
- Check internet connection
- Verify dining website URLs are accessible
- Clear cache: `rm -rf ~/.cache/mizzou-dining/`

**Old menus showing**
- Click the refresh button
- Cache may be stale but within 24-hour window
- Delete specific cache files if needed

## File Structure

```
mizzou-dining/
├── mizzou-dining.vala           # Main application source
├── meson.build                   # Build configuration
├── edu.missouri.dining.desktop.in # Desktop entry template
├── edu.missouri.dining.appdata.xml # AppStream metadata
├── mizzou-dining.gresource.xml   # Resource bundle definition
├── mizzou-dining.css             # Application styles
├── mizzou-dining.svg             # Application icon
└── README.md                     # This file
```

## Future Enhancements

Potential features for future versions:
- Notifications for favorite meals
- Dietary restriction filtering
- Nutrition information display
- Export menus to calendar
- Mobile-responsive version
- Dark mode support
- Multiple language support

## License

GPL-3.0+

## Credits

- University of Missouri Campus Dining Services for menu data
- GNOME Project for the GTK+ toolkit
- Vala development team

## Disclaimer

This is an unofficial application. It is not affiliated with or endorsed by the University of Missouri. Menu data is sourced from the official dining website and remains property of MU Campus Dining Services.

## Support

For issues or questions:
- Check the dining website: https://dining.missouri.edu/
- Review cached data in `~/.cache/mizzou-dining/`
- Rebuild with fresh source code

---

**Note**: This application was created as a convenience tool for Mizzou students and staff. Always verify menu information with official dining hall signage, as menus may change without notice.
