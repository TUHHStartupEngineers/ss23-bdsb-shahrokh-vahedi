# Data Science at TUHH ------------------------------------------------------
# SALES ANALYSIS ----

# 1.0 Load libraries ----
library(tidyverse)
library(readxl)

# 2.0 Importing Files ----
bikes_tbl      <- read_excel(path = "00_data/01_bike_sales/01_raw_data/bikes.xlsx")
orderlines_tbl <- read_excel("00_data/01_bike_sales/01_raw_data/orderlines.xlsx")

# Not necessary for this analysis, but for the sake of completeness
bikeshops_tbl  <- read_excel("00_data/01_bike_sales/01_raw_data/bikeshops.xlsx")

# 3.0 Examining Data ----


# 4.0 Joining Data ----
bike_orderlines_joined_tbl <- orderlines_tbl %>%
  left_join(bikes_tbl, by = c("product.id" = "bike.id")) %>%
  left_join(bikeshops_tbl, by = c("customer.id" = "bikeshop.id"))

# 5.0 Wrangling Data ----


bike_orderlines_wrangled_tbl <- bike_orderlines_joined_tbl %>% 
  # 5.1 Separate location
  separate(col    = location,
           into   = c("city", "state"),
           sep    = ", ") %>%
  # 5.2 Add the total price (price * quantity) 
  # Add a column to a tibble that uses a formula-style calculation of other columns
mutate(total.price = price * quantity) 



# 5.3 Optional: Reorganize. Using select to grab or remove unnecessary columns
# 5.3.1 by exact column name
bike_orderlines_wrangled_tbl_reorg<- bike_orderlines_wrangled_tbl %>% select(-...1, -gender)%>% 
  
  # 5.3.2 by a pattern
  # You can use the select_helpers to define patterns. 
  # Type ?ends_with and click on Select helpers in the documentation
  select(-ends_with(".id")) %>%
  
  # 5.3.3 Actually we need the column "order.id". Let's bind it back to the data
  bind_cols(bike_orderlines_joined_tbl %>% select(order.id)) 

# 5.3.4 You can reorder the data by selecting the columns in your desired order.
# You can use select_helpers like contains() or everything()
bike_orderlines_wrangled_tbl_reorg_reorder <- bike_orderlines_wrangled_tbl_reorg %>% select(order.id, contains("order"), contains("model"), contains("category"),
                                                                                            price, quantity, total.price,
                                                                                            everything()) %>%
  # 5.4 Rename columns because we actually wanted underscores instead of the dots
  # (one at the time vs. multiple at once)
  rename(bikeshop = name) %>%
  set_names(names(.) %>% str_replace_all("\\.", "_"))

# 6.0 Business Insights ----

# 6.1 Sales by State ----

# Step 1 - Manipulate

library(lubridate)
# Step 1 - Manipulate
sales_by_state_tbl <- bike_orderlines_wrangled_tbl_reorg_reorder %>%
  
  # Select columns
  select(state, total_price) %>%
  
  
  # Grouping by year and summarizing sales
  group_by(state) %>%
  summarize(sales = sum(total_price))%>%
  
  # Optional: Add a column that turns the numbers into a currency format 
  # (makes it in the plot optically more appealing)
  # mutate(sales_text = scales::dollar(sales)) <- Works for dollar values
  mutate(sales_text = scales::dollar(sales, big.mark = ".", 
                                     decimal.mark = ",", 
                                     prefix = "", 
                                     suffix = " €"))

sales_by_state_tbl





# Step 2 - Visualize
sales_by_state_tbl %>%
  
  # Setup canvas with the columns state (x-axis) and sales (y-axis)
  ggplot(aes(x = state, y = sales)) +
  
  # Geometries
  geom_col(fill = "#FFC300") + # Use geom_col for a bar plot
  geom_label(aes(label = sales_text)) + # Adding labels to the bars
  
  
  # Formatting
  # scale_y_continuous(labels = scales::dollar) + # Change the y-axis. 
  # Again, we have to adjust it for euro values
  scale_y_continuous(labels = scales::dollar_format(big.mark = ".", 
                                                    decimal.mark = ",", 
                                                    prefix = "", 
                                                    suffix = " €")) +
  labs(
    title    = "Revenue by state",
    x = "", # Override defaults for x and y
    y = "Revenue" 
  )+ theme(axis.text.x = element_text(angle = 45, hjust = 1))


# 6.2 Sales by state and year  ----

# Step 1 - Manipulate
sales_by_state_year_tbl <- bike_orderlines_wrangled_tbl_reorg_reorder %>%
  
  # Select columns and add a year
  select(order_date, total_price, state) %>%
  mutate(year = year(order_date)) %>%
  
  # Group by and summarize state and year
  group_by(state, year) %>%
  summarise(sales = sum(total_price)) %>%
  ungroup() %>%
  
  # Format $ Text
  mutate(sales_text = scales::dollar(sales, big.mark = ".", 
                                     decimal.mark = ",", 
                                     prefix = "", 
                                     suffix = " €"))

sales_by_state_year_tbl




# Step 2 - Visualize

sales_by_state_year_tbl %>%
  
  # Set up x, y, fill
  ggplot(aes(x = year, y = sales, fill = state)) +
  
  # Geometries
  geom_col() + # Run up to here to get a stacked bar plot
# Facet
facet_wrap(~ state) +
  
  
  
  # Formatting
  scale_y_continuous(labels = scales::dollar_format(big.mark = ".", 
                                                    decimal.mark = ",", 
                                                    prefix = "", 
                                                    suffix = " €")) +
  labs(
    title = "Revenue by state and year",
    fill = "year" # Changes the legend name
  )+ theme(axis.text.x = element_text(angle = 90, hjust = 1))


 