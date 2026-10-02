# The line spacing is extended to make the comments more readable for this example.

import mysql.connector
import pandas as pd # pandas is a cool tool used for data analysis, data cleaning and data ingestion.

# Create database connection
db = mysql.connector.connect(
    host = "localhost",
    user = "XXXXX",
    password = "XXXXX",
    database= "XXXXX"
    )

# Reada the csv file into a df(DataFrame). This allows me to loop through the data one row at a time    
df = pd.read_csv("bulk_data_all.csv")

# Creating the loop the "_" means ignore the index. row is an object that contains the values for an individual row.
for _, row in df.iterrows():

# Creates the variable "sql" which is everything between the triple quotes.
    sql = """
        insert into bulk_data_all (employee_id, first_name, last_name, email, location, title, department, salary, date_of_hire, bonus_count, office)
        values (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """

# Creates the cursor. The cursor is the object that sends the sql command.
    cursor = db.cursor()

# The execute command that contains the row values.
    cursor.execute(sql, (
        row['employee_id'],
        row['first_name'],
        row['last_name'],
        row['email'],
        row['location'],
        row['title'],
        row['department'],
        row['salary'],
        row['date_of_hire'],
        row['bonus_count'],
        row['office']
))

# Saves the changes to the database.
db.commit()

# Removes the cursor.
cursor.close()

# Closes the connection to the database.
db.close()

# Not necessary for the import, but it's common to print something at the end to let the user know the import is done. 
# This is especially true for very large files.
print("CSV import complete")
