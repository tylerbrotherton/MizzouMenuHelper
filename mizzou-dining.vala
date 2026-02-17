// Updated display_menu function to ensure correct column mapping for meals display.

function display_menu() {
    // Fetching the meal data
    const meals = get_meal_data();

    // URLs categorized by column
    const columnMapping = {
        'MARK': [],
        'Southwest': [],
        'Plaza 900': []
    };

    // Mapping URLs to their respective columns
    meals.forEach(meal => {
        if (meal.url.includes('mark')) {
            columnMapping['MARK'].push(meal);
        } else if (meal.url.includes('southwest')) {
            columnMapping['Southwest'].push(meal);
        } else if (meal.url.includes('plaza900')) {
            columnMapping['Plaza 900'].push(meal);
        }
    });

    // Creating widgets for each column
    create_column_widgets(columnMapping);
}