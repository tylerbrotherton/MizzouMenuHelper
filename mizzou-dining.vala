/* Mizzou Dining Menu Fetcher
 * A GNOME application to fetch and display dining hall menus
 */

using Gtk;
using Soup;
using Json;

public class MizzouDining : Gtk.Application {
    private Gtk.ApplicationWindow window;
    private Gtk.Grid main_grid;
    private MenuCache cache;
    
    // Store grid column for each URL
    private Gee.HashMap<string, int> url_to_column;
    
    // Settings
    private double font_scale = 1.3;  // Default larger font
    private bool show_all_days = true;
    
    private const string[] DINING_LOCATIONS = {
        "The MARK on 5th Street|https://dining.missouri.edu/locations/the-mark-on-5th-street/",
        "The Restaurants at Southwest|https://dining.missouri.edu/locations/the-restaurants-at-southwest/",
        "Plaza 900 Dining|https://dining.missouri.edu/locations/plaza-900-dining/"
    };
    
    public MizzouDining() {
        GLib.Object(
            application_id: "edu.missouri.dining",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }
    
    protected override void activate() {
        if (window != null) {
            window.present();
            return;
        }
        
        cache = new MenuCache();
        build_ui();
        window.present();
        
        // Auto-fetch all menus on startup
        refresh_all_menus();
    }
    
    private void build_ui() {
        url_to_column = new Gee.HashMap<string, int>();
        
        // Load custom CSS
        var css_provider = new Gtk.CssProvider();
        try {
            css_provider.load_from_resource("/edu/missouri/dining/mizzou-dining.css");
            Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (Error e) {
            warning("Failed to load CSS: %s", e.message);
        }
        
        window = new Gtk.ApplicationWindow(this);
        window.title = "Mizzou Dining Menus";
        window.default_width = 1400;
        window.default_height = 900;
        
        var header_bar = new Gtk.HeaderBar();
        header_bar.show_close_button = true;
        header_bar.title = "Mizzou Dining Menus";
        
        var refresh_button = new Gtk.Button.from_icon_name("view-refresh-symbolic", Gtk.IconSize.BUTTON);
        refresh_button.tooltip_text = "Refresh all menus";
        refresh_button.clicked.connect(refresh_all_menus);
        header_bar.pack_start(refresh_button);
        
        var settings_button = new Gtk.Button.from_icon_name("preferences-system-symbolic", Gtk.IconSize.BUTTON);
        settings_button.tooltip_text = "Settings";
        settings_button.clicked.connect(show_settings_dialog);
        header_bar.pack_end(settings_button);
        
        window.set_titlebar(header_bar);
        
        // Main scrolled window - single scrollbar for all columns
        var main_scrolled = new Gtk.ScrolledWindow(null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        
        // Grid layout: 3 columns (locations) x rows (days/meals)
        main_grid = new Gtk.Grid();
        main_grid.column_spacing = 20;
        main_grid.row_spacing = 15;
        main_grid.margin = 20;
        main_grid.column_homogeneous = true;
        
        // Column headers (location names)
        var locations = new string[] {
            "The MARK on 5th Street",
            "The Restaurants at Southwest", 
            "Plaza 900 Dining"
        };
        
        for (int col = 0; col < 3; col++) {
            var header = new Gtk.Label(locations[col]);
            var attrs = new Pango.AttrList();
            attrs.insert(Pango.attr_weight_new(Pango.Weight.BOLD));
            attrs.insert(Pango.attr_scale_new(1.6 * font_scale));
            header.set_attributes(attrs);
            header.margin_bottom = 15;
            main_grid.attach(header, col, 0, 1, 1);
        }
        
        // Create placeholder boxes for each location's content
        for (int col = 0; col < 3; col++) {
            var parts = DINING_LOCATIONS[col].split("|");
            var url = parts[1];
            
            // Map URL to column
            url_to_column.set(url, col);
            
            var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
            var loading_label = new Gtk.Label("Loading menu...");
            content_box.pack_start(loading_label, false, false, 0);
            
            main_grid.attach(content_box, col, 1, 1, 1);
        }
        
        main_scrolled.add(main_grid);
        window.add(main_scrolled);
        window.show_all();
    }
    
    private void show_settings_dialog() {
        var dialog = new Gtk.Dialog.with_buttons(
            "Settings",
            window,
            Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
            "Close", Gtk.ResponseType.CLOSE
        );
        
        dialog.set_default_size(400, 250);
        
        var content = dialog.get_content_area();
        content.margin = 20;
        content.spacing = 15;
        
        // Font size setting
        var font_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        var font_label = new Gtk.Label("Font Size:");
        font_label.halign = Gtk.Align.START;
        font_label.width_chars = 15;
        
        var font_scale_adj = new Gtk.Adjustment(font_scale, 1.0, 2.5, 0.1, 0.5, 0);
        var font_scale_spin = new Gtk.SpinButton(font_scale_adj, 0.1, 1);
        
        font_box.pack_start(font_label, false, false, 0);
        font_box.pack_start(font_scale_spin, true, true, 0);
        content.pack_start(font_box, false, false, 0);
        
        // Show all days toggle
        var days_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        var days_label = new Gtk.Label("Show All Days:");
        days_label.halign = Gtk.Align.START;
        days_label.width_chars = 15;
        
        var days_switch = new Gtk.Switch();
        days_switch.active = show_all_days;
        days_switch.halign = Gtk.Align.START;
        
        days_box.pack_start(days_label, false, false, 0);
        days_box.pack_start(days_switch, false, false, 0);
        content.pack_start(days_box, false, false, 0);
        
        // Apply button
        var apply_button = new Gtk.Button.with_label("Apply Changes");
        apply_button.clicked.connect(() => {
            font_scale = font_scale_spin.get_value();
            show_all_days = days_switch.active;
            refresh_all_menus();
            dialog.response(Gtk.ResponseType.CLOSE);
        });
        content.pack_start(apply_button, false, false, 0);
        
        dialog.show_all();
        dialog.run();
        dialog.destroy();
    }
    
    private void refresh_all_menus() {
        foreach (var location in DINING_LOCATIONS) {
            var parts = location.split("|");
            fetch_menu_silent(parts[0], parts[1]);
        }
    }
    
    private void fetch_menu_silent(string name, string url) {
        var session = new Soup.Session();
        var message = new Soup.Message("GET", url);
        
        session.queue_message(message, (sess, msg) => {
            if (msg.status_code == 200) {
                var html = (string) msg.response_body.data;
                var menu_data = parse_menu_html(html);
                cache.save_menu(url, menu_data);
                
                // Always display the menu when it arrives
                display_menu(name, menu_data, url);
            }
        });
    }
    
    private MenuData parse_menu_html(string html) {
        var menu_data = new MenuData();
        
        // Extract menu items using basic string parsing
        // Looking for tab-pane sections with meal times and items
        
        var days = new Gee.ArrayList<DayMenu>();
        
        // Find all tab-pane sections
        int pos = 0;
        while ((pos = html.index_of("tab-pane", pos)) != -1) {
            int end_pos = html.index_of("</div>", pos + 200);
            if (end_pos == -1) break;
            
            var section = html.substring(pos, end_pos - pos);
            
            // Extract day name from tab
            var day_name = extract_between(section, "id=\"item", "-tab\"");
            if (day_name == null) {
                pos = end_pos;
                continue;
            }
            
            var day_menu = new DayMenu();
            day_menu.day_name = extract_day_label(html, day_name);
            
            // Extract meals for this day
            day_menu.meals = extract_meals(section);
            
            if (day_menu.meals.size > 0) {
                days.add(day_menu);
            }
            
            pos = end_pos;
        }
        
        menu_data.days = days;
        menu_data.timestamp = new DateTime.now_local();
        
        return menu_data;
    }
    
    private string? extract_day_label(string html, string item_id) {
        var pattern = "id=\"" + item_id + "-tab\"";
        int pos = html.index_of(pattern);
        if (pos == -1) return null;
        
        int start = html.index_of(">", pos);
        int end = html.index_of("</a>", start);
        if (start == -1 || end == -1) return null;
        
        return html.substring(start + 1, end - start - 1);
    }
    
    private Gee.ArrayList<Meal> extract_meals(string section) {
        var meals = new Gee.ArrayList<Meal>();
        
        // Look for accordion sections with meal times
        int pos = 0;
        while ((pos = section.index_of("accordion-section__question", pos)) != -1) {
            int button_start = section.index_of("<button", pos);
            int button_end = section.index_of("</button>", button_start);
            
            if (button_start == -1 || button_end == -1) break;
            
            var button_text = section.substring(button_start, button_end - button_start);
            
            // Extract meal name and time
            int text_start = button_text.index_of(">");
            int icon_pos = button_text.index_of("<i class=");
            if (text_start == -1 || icon_pos == -1) {
                pos = button_end;
                continue;
            }
            
            var meal_name = button_text.substring(text_start + 1, icon_pos - text_start - 1).strip();
            
            // Extract items list
            int collapse_start = section.index_of("<div id=\"collapse-", pos);
            int ul_start = section.index_of("<ul>", collapse_start);
            int ul_end = section.index_of("</ul>", ul_start);
            
            if (ul_start == -1 || ul_end == -1) {
                pos = button_end;
                continue;
            }
            
            var items = extract_list_items(section.substring(ul_start, ul_end - ul_start));
            
            if (items.size > 0) {
                var meal = new Meal();
                meal.name = meal_name;
                meal.items = items;
                meals.add(meal);
            }
            
            pos = ul_end;
        }
        
        return meals;
    }
    
    private Gee.ArrayList<string> extract_list_items(string ul_content) {
        var items = new Gee.ArrayList<string>();
        
        int pos = 0;
        while ((pos = ul_content.index_of("<li>", pos)) != -1) {
            int end = ul_content.index_of("</li>", pos);
            if (end == -1) break;
            
            var item_text = ul_content.substring(pos + 4, end - pos - 4).strip();
            // Remove HTML tags
            item_text = remove_html_tags(item_text);
            
            if (item_text.length > 0) {
                items.add(item_text);
            }
            
            pos = end;
        }
        
        return items;
    }
    
    private string remove_html_tags(string text) {
        var result = text;
        int start;
        while ((start = result.index_of("<")) != -1) {
            int end = result.index_of(">", start);
            if (end == -1) break;
            result = result.substring(0, start) + result.substring(end + 1);
        }
        return result.strip();
    }
    
    private string? extract_between(string text, string start_marker, string end_marker) {
        int start = text.index_of(start_marker);
        if (start == -1) return null;
        
        start += start_marker.length;
        int end = text.index_of(end_marker, start);
        if (end == -1) return null;
        
        return text.substring(start, end - start);
    }
    
    private void display_menu(string location_name, MenuData menu_data, string url) {
        // Get the column for this URL
        if (!url_to_column.has_key(url)) {
            return;
        }
        
        int col = url_to_column.get(url);
        
        // Remove old widget at this position
        var old_widget = main_grid.get_child_at(col, 1);
        if (old_widget != null) {
            main_grid.remove(old_widget);
        }
        
        // Create and attach new widget
        var new_widget = create_menu_column(menu_data);
        main_grid.attach(new_widget, col, 1, 1, 1);
        main_grid.show_all();
    }
    
    private Gtk.Widget create_menu_column(MenuData menu_data) {
        var column_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
        column_box.margin = 10;
        column_box.valign = Gtk.Align.START; // Force top alignment
        column_box.vexpand = false;
        
        if (menu_data.days.size == 0) {
            var no_menu = new Gtk.Label("No menu data available");
            var attrs = new Pango.AttrList();
            attrs.insert(Pango.attr_scale_new(font_scale));
            no_menu.set_attributes(attrs);
            no_menu.valign = Gtk.Align.START;
            column_box.pack_start(no_menu, false, false, 0);
            return column_box;
        }
        
        // Filter days if needed
        var days_to_show = menu_data.days;
        if (!show_all_days && menu_data.days.size > 0) {
            days_to_show = new Gee.ArrayList<DayMenu>();
            days_to_show.add(menu_data.days[0]); // Only show first day
        }
        
        // Display each day vertically from top
        foreach (var day in days_to_show) {
            // Day header
            var day_label = new Gtk.Label(day.day_name);
            var day_attrs = new Pango.AttrList();
            day_attrs.insert(Pango.attr_weight_new(Pango.Weight.BOLD));
            day_attrs.insert(Pango.attr_scale_new(1.35 * font_scale));
            day_label.set_attributes(day_attrs);
            day_label.halign = Gtk.Align.START;
            day_label.valign = Gtk.Align.START;
            day_label.margin_top = 5;
            day_label.margin_bottom = 10;
            column_box.pack_start(day_label, false, false, 0);
            
            // Display meals vertically UNDER this day
            foreach (var meal in day.meals) {
                // Meal time header
                var meal_label = new Gtk.Label(meal.name);
                var meal_attrs = new Pango.AttrList();
                meal_attrs.insert(Pango.attr_weight_new(Pango.Weight.BOLD));
                meal_attrs.insert(Pango.attr_scale_new(1.2 * font_scale));
                meal_attrs.insert(Pango.attr_foreground_new(61680, 47104, 11520)); // Mizzou Gold
                meal_label.set_attributes(meal_attrs);
                meal_label.halign = Gtk.Align.START;
                meal_label.valign = Gtk.Align.START;
                meal_label.margin_top = 8;
                meal_label.margin_start = 5;
                meal_label.margin_bottom = 4;
                column_box.pack_start(meal_label, false, false, 0);
                
                // Menu items - stacked vertically
                foreach (var item in meal.items) {
                    var item_label = new Gtk.Label("• " + item);
                    var item_attrs = new Pango.AttrList();
                    item_attrs.insert(Pango.attr_scale_new(1.05 * font_scale));
                    item_label.set_attributes(item_attrs);
                    item_label.halign = Gtk.Align.START;
                    item_label.valign = Gtk.Align.START;
                    item_label.margin_start = 20;
                    item_label.margin_top = 1;
                    item_label.margin_bottom = 1;
                    item_label.wrap = true;
                    item_label.xalign = 0;
                    item_label.max_width_chars = 45;
                    column_box.pack_start(item_label, false, false, 0);
                }
                
                // Space after each meal
                var spacer = new Gtk.Label("");
                spacer.margin_top = 6;
                column_box.pack_start(spacer, false, false, 0);
            }
            
            // Separator between days
            if (show_all_days && day != days_to_show[days_to_show.size - 1]) {
                var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
                separator.margin_top = 15;
                separator.margin_bottom = 15;
                column_box.pack_start(separator, false, false, 0);
            }
        }
        
        return column_box;
    }
    
    public static int main(string[] args) {
        var app = new MizzouDining();
        return app.run(args);
    }
}

// Data classes
public class MenuData {
    public Gee.ArrayList<DayMenu> days;
    public DateTime timestamp;
    
    public MenuData() {
        days = new Gee.ArrayList<DayMenu>();
        timestamp = new DateTime.now_local();
    }
}

public class DayMenu {
    public string day_name;
    public Gee.ArrayList<Meal> meals;
    
    public DayMenu() {
        meals = new Gee.ArrayList<Meal>();
    }
}

public class Meal {
    public string name;
    public Gee.ArrayList<string> items;
    
    public Meal() {
        items = new Gee.ArrayList<string>();
    }
}

// Menu cache manager
public class MenuCache {
    private string cache_dir;
    private const int MAX_CACHE_DAYS = 7;
    
    private DateTime? parse_timestamp(string timestamp_str) {
        // Try using from_iso8601 if available, otherwise parse manually
        try {
            return new DateTime.from_iso8601(timestamp_str, null);
        } catch {
            // Fallback: parse format "YYYY-MM-DDTHH:MM:SS+HH:MM"
            // For simplicity, just use current time if parsing fails
            return new DateTime.now_local();
        }
    }
    
    public MenuCache() {
        cache_dir = GLib.Path.build_filename(Environment.get_user_cache_dir(), "mizzou-dining");
        DirUtils.create_with_parents(cache_dir, 0755);
        cleanup_old_entries();
    }
    
    public MenuData? get_menu(string url) {
        var cache_file = get_cache_filename(url);
        
        if (!FileUtils.test(cache_file, FileTest.EXISTS)) {
            return null;
        }
        
        try {
            string content;
            FileUtils.get_contents(cache_file, out content);
            
            var parser = new Json.Parser();
            parser.load_from_data(content);
            
            var root = parser.get_root().get_object();
            var timestamp_str = root.get_string_member("timestamp");
            var timestamp = parse_timestamp(timestamp_str);
            
            if (timestamp == null) {
                return null;
            }
            
            // Check if cache is still valid (less than 24 hours old)
            var now = new DateTime.now_local();
            var diff = now.difference(timestamp) / TimeSpan.HOUR;
            
            if (diff > 24) {
                return null;
            }
            
            var menu_data = new MenuData();
            menu_data.timestamp = timestamp;
            
            var days_array = root.get_array_member("days");
            days_array.foreach_element((arr, idx, node) => {
                var day_obj = node.get_object();
                var day_menu = new DayMenu();
                day_menu.day_name = day_obj.get_string_member("day_name");
                
                var meals_array = day_obj.get_array_member("meals");
                meals_array.foreach_element((arr2, idx2, node2) => {
                    var meal_obj = node2.get_object();
                    var meal = new Meal();
                    meal.name = meal_obj.get_string_member("name");
                    
                    var items_array = meal_obj.get_array_member("items");
                    items_array.foreach_element((arr3, idx3, node3) => {
                        meal.items.add(node3.get_string());
                    });
                    
                    day_menu.meals.add(meal);
                });
                
                menu_data.days.add(day_menu);
            });
            
            return menu_data;
            
        } catch (Error e) {
            warning("Failed to load cache: %s", e.message);
            return null;
        }
    }
    
    public void save_menu(string url, MenuData menu_data) {
        var cache_file = get_cache_filename(url);
        
        var builder = new Json.Builder();
        builder.begin_object();
        
        builder.set_member_name("timestamp");
        builder.add_string_value(menu_data.timestamp.format_iso8601());
        
        builder.set_member_name("days");
        builder.begin_array();
        
        foreach (var day in menu_data.days) {
            builder.begin_object();
            
            builder.set_member_name("day_name");
            builder.add_string_value(day.day_name);
            
            builder.set_member_name("meals");
            builder.begin_array();
            
            foreach (var meal in day.meals) {
                builder.begin_object();
                
                builder.set_member_name("name");
                builder.add_string_value(meal.name);
                
                builder.set_member_name("items");
                builder.begin_array();
                
                foreach (var item in meal.items) {
                    builder.add_string_value(item);
                }
                
                builder.end_array();
                builder.end_object();
            }
            
            builder.end_array();
            builder.end_object();
        }
        
        builder.end_array();
        builder.end_object();
        
        var generator = new Json.Generator();
        generator.set_root(builder.get_root());
        generator.pretty = true;
        
        try {
            generator.to_file(cache_file);
        } catch (Error e) {
            warning("Failed to save cache: %s", e.message);
        }
    }
    
    private string get_cache_filename(string url) {
        var hash = Checksum.compute_for_string(ChecksumType.MD5, url);
        return GLib.Path.build_filename(cache_dir, hash + ".json");
    }
    
    private void cleanup_old_entries() {
        try {
            var dir = Dir.open(cache_dir);
            string? name;
            var now = new DateTime.now_local();
            
            while ((name = dir.read_name()) != null) {
                var file_path = GLib.Path.build_filename(cache_dir, name);
                
                FileInfo info = File.new_for_path(file_path).query_info(
                    FileAttribute.TIME_MODIFIED,
                    FileQueryInfoFlags.NONE
                );
                
                var modified = new DateTime.from_unix_local(
                    (int64) info.get_attribute_uint64(FileAttribute.TIME_MODIFIED)
                );
                
                var days_old = now.difference(modified) / TimeSpan.DAY;
                
                if (days_old > MAX_CACHE_DAYS) {
                    FileUtils.unlink(file_path);
                }
            }
        } catch (Error e) {
            warning("Failed to cleanup cache: %s", e.message);
        }
    }
}
