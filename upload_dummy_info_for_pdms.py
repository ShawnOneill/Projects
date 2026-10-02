import mysql.connector
import pandas as pd

db = mysql.connector.connect(
    host = 'localhost',
    user = 'puser',
    password = '1Long1234.',
    database = 'pdms'
)

df = pd.read_csv('pdms dummy info.csv')

for _, row in df.iterrows():
    sql = """
        insert into customers (first_name, last_name, email, phone, company)
        values (%s, %s, %s, %s, %s)
    """

cursor = db.cursor()

cursor.execute(sql, (
    row['first_name'],
    row['last_name'],
    row['email'],
    row['phone'],
    row['company']
))

db.commit()

cursor.close()

db.close()

print("CSV import complete")