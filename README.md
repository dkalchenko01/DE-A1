# **Data Engineering - Assignment 1**

I've chosen the TV Series Dataset, that contains over 150.000 details of every TV series on The Movie Database.

Link to the Dataset: [here](https://www.kaggle.com/datasets/bourdier/all-tv-series-details-dataset?select=tvs.json)

# Data Parsing
I used DuckDB as an analytical environment for this work.

In order to transform semi-structured JSON data into a structured format I used such function:
- `read_json()` - to load JSON file
- `json_value()` - to extract the nested fields 
- `unnest()` -  to flatten the arrays
- `cast()` and `try_cast` - to change to appropriate data type
- `trim()` - to remove unnecessary symbols at the beginning and ending of the value
- `nullif()` - to handle null values

# Data Analysis
The detailed information about the data-driven insights is provided in `assignment_1.sql` file (the query itself, what it does, a sample of the result set, an explanation for the result)

# Bonus Task - Visualisation
I used Tableau the visualise the result of the query, which returns an average production company popularity with their best show.

The link to Tableau viz : [here](https://public.tableau.com/views/A1_17708989076510/Sheet1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)
