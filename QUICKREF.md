# Mizzou Dining - Quick Reference

## Installation (One Command)

### Ubuntu/Debian
```bash
sudo apt install valac meson libgtk-3-dev libsoup2.4-dev libjson-glib-dev libgee-0.8-dev && ./build.sh
```

### Fedora
```bash
sudo dnf install vala meson gtk3-devel libsoup-devel json-glib-devel libgee-devel && ./build.sh
```

### Arch Linux
```bash
sudo pacman -S vala meson gtk3 libsoup json-glib libgee && ./build.sh
```

## Run
```bash
./build/mizzou-dining
```

## Features at a Glance

| Feature | Description |
|---------|-------------|
| **Locations** | The MARK, Southwest, Plaza 900 |
| **Cache** | 24-hour validity, 7-day retention |
| **Updates** | Manual refresh or automatic on selection |
| **Offline** | Works with cached data |
| **Storage** | `~/.cache/mizzou-dining/` |

## Keyboard Shortcuts

- **↑/↓**: Navigate locations
- **Enter**: Select location
- **Ctrl+R**: Refresh menus
- **Ctrl+Q**: Quit

## Cache Management

### View cache location
```bash
ls ~/.cache/mizzou-dining/
```

### Clear cache
```bash
rm -rf ~/.cache/mizzou-dining/
```

### Check cache age
```bash
stat ~/.cache/mizzou-dining/*.json
```

## Data Flow

```
User Action → Check Cache → (Cache Valid) → Display Menu
                ↓
         (Cache Invalid/Missing)
                ↓
         Fetch from Web → Parse HTML → Save to Cache → Display Menu
```

## File Structure

```
~/.cache/mizzou-dining/
  ├── a1b2c3d4e5f6g7h8.json  (The MARK)
  ├── i9j0k1l2m3n4o5p6.json  (Southwest)
  └── q7r8s9t0u1v2w3x4.json  (Plaza 900)
```

## Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| Won't start | Run from terminal to see errors |
| No menus | Check internet, clear cache |
| Old menus | Click refresh button |
| Build error | Check all dependencies installed |

## URLs Monitored

1. https://dining.missouri.edu/locations/the-mark-on-5th-street/
2. https://dining.missouri.edu/locations/the-restaurants-at-southwest/
3. https://dining.missouri.edu/locations/plaza-900-dining/

## Menu Structure Parsed

```
Week
 ├── Day (e.g., "Monday, Feb 16")
 │   ├── Meal (e.g., "Breakfast: 7:00 AM - 10:00 AM")
 │   │   ├── Item 1
 │   │   ├── Item 2
 │   │   └── ...
 │   ├── Meal (e.g., "Lunch: 11:00 AM - 2:15 PM")
 │   └── Meal (e.g., "Dinner: 4:30 PM - 8:00 PM")
 └── ...
```

## Tech Stack

- **Language**: Vala (compiles to C)
- **GUI**: GTK+ 3.0
- **HTTP**: libsoup 2.4
- **JSON**: json-glib 1.0
- **Collections**: libgee 0.8
- **Build**: Meson + Ninja

## Performance

- **Binary size**: ~50-100 KB
- **Memory usage**: ~20-30 MB
- **Startup time**: <1 second
- **Network request**: ~2-5 seconds per location
- **Cache size**: ~10-50 KB per location

## Development

### Build for debugging
```bash
meson setup build --buildtype=debug
meson compile -C build
```

### Run with debugging
```bash
G_MESSAGES_DEBUG=all ./build/mizzou-dining
```

### Rebuild after changes
```bash
meson compile -C build
```

## Version Info

- **Version**: 1.0.0
- **License**: GPL-3.0+
- **App ID**: edu.missouri.dining
- **Binary**: mizzou-dining

## Support

- Check cache: `~/.cache/mizzou-dining/`
- Logs: Run from terminal
- Official menus: https://dining.missouri.edu/
