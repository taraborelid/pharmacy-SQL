# Pharmacy Database Project

This repository contains the SQL scripts and resources for a pharmacy management database. The project includes schema definitions, seed data, views, and stored procedures for managing purchases, sales, inventory, and customer information.

## Folder Structure

All SQL files are located in the `sql/` folder:
- `schema.sql`: Database schema and table definitions.
- `seed.sql`: Initial data for tables (drugs, suppliers, customers, etc.).
- `views.sql`: SQL views for reporting and data aggregation.
- `insert_purchase_details.sql`: Stored procedures and functions for handling purchases.
- `insert_sale_details.sql`: Stored procedures and functions for handling sales.
- `EER-Diagram.png`: Entity-Relationship diagram of the database.
- `models.mwb`: MySQL Workbench model file.

## How to Set Up the Database

1. **Install MySQL Server**
   - Make sure you have MySQL installed on your system.

2. **Create the Database and Tables**
   - Open MySQL Workbench or your preferred SQL client.
   - Run the script `sql/schema.sql` to create the database and all tables.

3. **Insert Initial Data**
   - Run the script `sql/seed.sql` to populate the tables with initial data.

4. **Create Views**
   - Run the script `sql/views.sql` to create useful views for reporting and analysis.

5. **Add Stored Procedures and Functions**
   - Run `sql/insert_purchase_details.sql` and `sql/insert_sale_details.sql` to add stored procedures and functions for managing purchases and sales.

## Usage
- You can use the provided stored procedures to insert purchase and sale details efficiently.
- The views allow you to easily query and report on purchases, sales, inventory, and customer profiles.
- The EER diagram (`sql/EER-Diagram.png`) provides a visual overview of the database structure.

## Notes
- All scripts are written for MySQL.
- Make sure to run the scripts in the order listed above for proper setup.
- For any issues or questions, refer to the comments in each SQL file.

