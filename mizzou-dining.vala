/* Mizzou Dining Menu Fetcher
 * A GNOME application to fetch and display dining hall menus
 */

using Gtk;
using Soup;
using Json;

public class MizzouDining : Gtk.Application {
    private Gtk.ApplicationWindow window;
    private Gtk.Stack main_stack;
    private Gtk.ListBox location_list;
    private Gtk.Stack menu_stack;
    private Gtk.Label status_label;
    private MenuCache cache;
    
    private const string[] DINING_LOCATIONS = {
        "The MARK on 5th Street|https://dining.missouri.edu/locations/the-mark-on-5th-street/",
        "The Restaurants at Southwest|https://dining.missouri.edu/locations/the-restaurants-at-southwest/",
        "Plaza 900 Dining|https://dining.missouri.edu/locations/plaza-900-dining/"
    };
    
    public MizzouDining() {
        Object(
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
        
        // Load cached menus initially
        load_cached_menus();
    }
    
    private void build_ui() {
        window = new Gtk.ApplicationWindow(this);
        window.title = "Mizzou Dining Menus";
        window.default_width = 900;
        window.default_height = 700;
        
        var header_bar = new Gtk.HeaderBar();
        header_bar.show_close_button = true;
        header_bar.title = "Mizzou Dining";
        
        var refresh_button = new Gtk.Button.from_icon_name("view-refresh-symbolic", Gtk.IconSize.BUTTON);
        refresh_button.tooltip_text = "Refresh all menus";
        refresh_button.clicked.connect(refresh_all_menus);
        header_bar.pack_start(refresh_button);
        
        window.set_titlebar(header_bar);
        
        var paned = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
        
        // Left sidebar with location list
        var sidebar_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        sidebar_box.set_size_request(250, -1);
        
        var sidebar_label = new Gtk.Label("Dining Locations");
        sidebar_label.get_style_context().add_class("title");
        sidebar_label.margin = 12;
        sidebar_box.pack_start(sidebar_label, false, false, 0);
        
        var scrolled_locations = new Gtk.ScrolledWindow(null, null);
        scrolled_locations.hscrollbar_policy = Gtk.PolicyType.NEVER;
        
        location_list = new Gtk.ListBox();
        location_list.selection_mode = Gtk.SelectionMode.SINGLE;
        location_list.row_selected.connect(on_location_selected);
        
        foreach (var location in DINING_LOCATIONS) {
            var parts = location.split("|");
            var row = new LocationRow(parts[0], parts[1]);
            location_list.add(row);
        }
        
        scrolled_locations.add(location_list);
        sidebar_box.pack_start(scrolled_locations, true, true, 0);
        
        paned.pack1(sidebar_box, false, false);
        
        // Right side with menu display
        var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        
        status_label = new Gtk.Label("Select a location to view menus");
        status_label.margin = 12;
        content_box.pack_start(status_label, false, false, 0);
        
        menu_stack = new Gtk.Stack();
        menu_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        
        content_box.pack_start(menu_stack, true, true, 0);
        
        paned.pack2(content_box, true, false);
        
        window.add(paned);
        window.show_all();
    }
    
    private void on_location_selected(Gtk.ListBoxRow? row) {
        if (row == null) return;
        
        var location_row = row as LocationRow;
        if (location_row == null) return;
        
        status_label.label = location_row.location_name;
        
        var cached_menu = cache.get_menu(location_row.url);
        if (cached_menu != null) {
            display_menu(location_row.location_name, cached_menu);
        } else {
            fetch_menu(location_row.location_name, location_row.url);
        }
    }
    
    private void load_cached_menus() {
        // Silently load cached menus in background
        foreach (var location in DINING_LOCATIONS) {
            var parts = location.split("|");
            var cached = cache.get_menu(parts[1]);
            if (cached == null) {
                fetch_menu_silent(parts[0], parts[1]);
            }
        }
    }
    
    private void refresh_all_menus() {
        status_label.label = "Refreshing menus...";
        
        foreach (var location in DINING_LOCATIONS) {
            var parts = location.split("|");
            fetch_menu_silent(parts[0], parts[1]);
        }
        
        status_label.label = "Menus refreshed";
    }
    
    private void fetch_menu_silent(string name, string url) {
        var session = new Soup.Session();
        var message = new Soup.Message("GET", url);
        
        session.queue_message(message, (sess, msg) => {
            if (msg.status_code == 200) {
                var html = (string) msg.response_body.data;
                var menu_data = parse_menu_html(html);
                cache.save_menu(url, menu_data);
            }
        });
    }
    
    private void fetch_menu(string name, string url) {
        status_label.label = "Fetching menu for " + name + "...";
        
        var session = new Soup.Session();
        var message = new Soup.Message("GET", url);
        
        session.queue_message(message, (sess, msg) => {
            if (msg.status_code == 200) {
                var html = (string) msg.response_body.data;
                var menu_data = parse_menu_html(html);
                cache.save_menu(url, menu_data);
                display_menu(name, menu_data);
                status_label.label = name;
            } else {
                status_label.label = "Failed to fetch menu for " + name;
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
    
    private void display_menu(string location_name, MenuData menu_data) {
        var menu_widget = menu_stack.get_child_by_name(location_name);
        
        if (menu_widget == null) {
            menu_widget = create_menu_widget(menu_data);
            menu_stack.add_named(menu_widget, location_name);
        } else {
            // Update existing widget
            menu_stack.remove(menu_widget);
            menu_widget = create_menu_widget(menu_data);
            menu_stack.add_named(menu_widget, location_name);
        }
        
        menu_stack.set_visible_child_name(location_name);
    }
    
    private Gtk.Widget create_menu_widget(MenuData menu_data) {
        var scrolled = new Gtk.ScrolledWindow(null, null);
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
        box.margin = 18;
        
        if (menu_data.days.size == 0) {
            var no_menu = new Gtk.Label("No menu data available");
            no_menu.get_style_context().add_class("dim-label");
            box.pack_start(no_menu, false, false, 0);
        } else {
            foreach (var day in menu_data.days) {
                var day_frame = create_day_widget(day);
                box.pack_start(day_frame, false, false, 0);
            }
        }
        
        var timestamp = new Gtk.Label("Last updated: " + menu_data.timestamp.format("%B %d, %Y at %I:%M %p"));
        timestamp.get_style_context().add_class("dim-label");
        timestamp.halign = Gtk.Align.END;
        timestamp.margin_top = 12;
        box.pack_start(timestamp, false, false, 0);
        
        scrolled.add(box);
        scrolled.show_all();
        
        return scrolled;
    }
    
    private Gtk.Widget create_day_widget(DayMenu day) {
        var frame = new Gtk.Frame(day.day_name);
        frame.margin = 6;
        
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
        box.margin = 12;
        
        foreach (var meal in day.meals) {
            var meal_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
            
            var meal_label = new Gtk.Label(meal.name);
            meal_label.get_style_context().add_class("title");
            meal_label.halign = Gtk.Align.START;
            meal_box.pack_start(meal_label, false, false, 0);
            
            foreach (var item in meal.items) {
                var item_label = new Gtk.Label("• " + item);
                item_label.halign = Gtk.Align.START;
                item_label.margin_start = 12;
                item_label.wrap = true;
                item_label.xalign = 0;
                meal_box.pack_start(item_label, false, false, 0);
            }
            
            box.pack_start(meal_box, false, false, 0);
            
            var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
            separator.margin_top = 4;
            box.pack_start(separator, false, false, 0);
        }
        
        frame.add(box);
        return frame;
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

// Location row widget
public class LocationRow : Gtk.ListBoxRow {
    public string location_name { get; private set; }
    public string url { get; private set; }
    
    public LocationRow(string name, string location_url) {
        location_name = name;
        url = location_url;
        
        var label = new Gtk.Label(name);
        label.halign = Gtk.Align.START;
        label.margin = 12;
        label.wrap = true;
        
        add(label);
    }
}

// Menu cache manager
public class MenuCache {
    private string cache_dir;
    private const int MAX_CACHE_DAYS = 7;
    
    public MenuCache() {
        cache_dir = Path.build_filename(Environment.get_user_cache_dir(), "mizzou-dining");
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
            var timestamp = new DateTime.from_iso8601(timestamp_str, null);
            
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
        builder.add_string_value(menu_data.timestamp.to_iso8601());
        
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
        return Path.build_filename(cache_dir, hash + ".json");
    }
    
    private void cleanup_old_entries() {
        try {
            var dir = Dir.open(cache_dir);
            string? name;
            var now = new DateTime.now_local();
            
            while ((name = dir.read_name()) != null) {
                var file_path = Path.build_filename(cache_dir, name);
                
                FileInfo info = File.new_for_path(file_path).query_info(
                    FileAttribute.TIME_MODIFIED,
                    FileQueryInfoFlags.NONE
                );
                
                var modified = new DateTime.from_unix_local(
                    info.get_attribute_uint64(FileAttribute.TIME_MODIFIED)
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
