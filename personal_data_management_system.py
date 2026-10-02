#Personal Data Management System

import mysql.connector
import pandas as pd

db= mysql.connector.connect(
    host = 'localhost',
    user = 'puser',
    password = '1Long1234.',
    database = 'pdms'
)


def upload_csv_to_database(file_path):
    df = pd.read_csv(file_path)
    cursor = db.cursor()

    for _, row in df.iterrows():
        sql = """
            insert into customers (first_name, last_name, email, phone, company)
            values (%s, %s, %s, %s, %s)
        """
        cursor.execute(sql, (
            row['first_name'],
            row['last_name'],
            row['email'],
            row['phone'],
            row['company']
        ))

    db.commit()
    cursor.close()
    print("CSV import complete")


def upload_individual(first_name, last_name, email, phone, company):
    cursor = db.cursor()
    sql = """
        insert into customers (first_name, last_name, email, phone, company)
        values (%s, %s, %s, %s, %s)
    """
    cursor.execute(sql, (first_name, last_name, email, phone, company))
    db.commit()
    cursor.close()
    print("Customer added successfully")


print("Personal Data Management System")
print()
print("1. Add customer")
print("2. Find customers")
print("3. Update customer")
print("4. Delete customer")
print("5. Import CSV")
print("6. Export CSV")
print("7. Show customer count")
print("8. Exit")
print()

print("Please select menu option number")
option = input()

if option == "1":
    print("Add customer")
    print()
    print("Please enter first name")
    first_name = input()
    print("Please enter last name")
    last_name = input()
    print("Please enter email")
    email = input()
    print("Please enter phone number")
    phone = input()
    print("Please enter company name")
    company = input()
    upload_individual(first_name, last_name, email, phone, company)


elif option == "2":
     #TODO: Add logic to find customers here
     pass

elif option == "3":
    #TODO: Add logic to update customer here
    pass

elif option == "4":
     #TODO: Add logic to delete customer here
     pass

elif option == "5":
    print("enter the path to the CSV file. For example: C:\\Users\\YourUsername\\Documents\\customers.csv")
    file_path = input()
    upload_csv_to_database(file_path)

elif option == "6":
     # TODO: Add logic to export CSV here
     pass

elif option == "7":
     # Add logic to show customer count here
     pass

elif option == "8":
    print("Exiting...")
    exit()  

