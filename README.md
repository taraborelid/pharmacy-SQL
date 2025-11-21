# Pharmacy Database Project

This repository contains the SQL scripts and resources for a pharmacy management database. The project includes schema definitions, seed data, views, and stored procedures for managing purchases, sales, inventory, and customer information.

### SQL Queries and Executions

To see screenshots of the queries, views, and stored procedures in action, check:

[Database Execution Examples](./DatabaseExecutionExamples.md)

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

## Stored Procedures Usage

### How `insert_purchase_detail` Stored Procedure Works

The `insert_purchase_detail` procedure is used to record a new purchase from a supplier, including all purchased items and their details. It automates the process of inserting purchase records, updating inventory, and calculating totals.

**Parameters:**
- `i_invoice_number`: The invoice number for the purchase.
- `i_supplier_id`: The ID of the supplier.
- `i_quantity`: A comma-separated list of quantities for each product.
- `i_names`: A comma-separated list of product names (as they appear in the branded drug catalog).

**How it works:**
1. Validates all input parameters (checks for existence, non-empty values, and matching records).
2. Creates a new purchase record in the `purchase` table.
3. Iterates through each product name and quantity:
   - Checks for product and supplier validity.
   - Inserts a record into `purchase_detail` for each item.
   - Updates or inserts the product in `pharmacy_stock`, increasing the quantity and updating price and expiration.
4. Calculates the total purchase amount and updates the purchase record.
5. Rolls back the transaction if any error occurs, ensuring data integrity.

**Example usage:**
```sql
CALL insert_purchase_detail(
  "FC-2025-010",     -- Invoice number
  1,                 -- Supplier ID
  '4, 6, 6',         -- Quantities
  'Tylenol, Advil, Brufen'  -- Product names
);
```

This procedure ensures that all purchases are recorded consistently and that inventory is updated automatically.

### How `insert_sale_details` Stored Procedure Works

The `insert_sale_details` procedure is used to insert a new sale and its details into the database. It automates the process of recording a sale, including the customer, staff, items sold, quantities, and associated prescriptions.

**Parameters:**
- `i_invoice_number`: The invoice number for the sale.
- `i_customer_id`: The ID of the customer making the purchase.
- `i_staff_id`: The ID of the staff member processing the sale.
- `i_names`: A comma-separated list of product names (as they appear in stock).
- `i_quantity`: A comma-separated list of quantities for each product.
- `i_prescriptions`: A comma-separated list of prescription IDs (or 'null' for OTC items).

**How it works:**
1. Validates all input parameters (checks for existence, non-empty values, and matching records).
2. Creates a new sale record in the `sale` table.
3. Iterates through each product name, quantity, and prescription:
   - Checks stock availability and prescription validity.
   - Inserts a record into `sale_detail` for each item.
   - Updates the stock quantity in `pharmacy_stock`.
4. Calculates the total sale amount and updates the sale record.
5. Rolls back the transaction if any error occurs, ensuring data integrity.

**Example usage:**
```sql
CALL insert_sale_details(
  "FV-2025-04",      -- Invoice number
  2,                 -- Customer ID
  1,                 -- Staff ID
  'Tylenol, Advil, Brufen',  -- Product names
  '4, 6, 6',         -- Quantities
  '1, null, 3'       -- Prescription IDs (or 'null' for OTC)
);
```

This procedure ensures that all sales are recorded consistently and that inventory is updated automatically.

## EER Diagram
![EER Diagram](sql/EER-Diagram.png)

## Assets
An `assets/` directory (e.g. `sql/assets/` or a top-level `assets/`) is intended for storing diagrams and future visual documentation (flow charts, sequence diagrams, etc.). Currently the diagram file is located at `sql/EER-Diagram.png`. If you prefer a cleaner structure you can move it to `sql/assets/EER-Diagram.png` and update the path above accordingly:

```markdown
![EER Diagram](sql/assets/EER-Diagram.png)
```

Recommended naming for future images:
- `eer-diagram.png`
- `purchase-flow.png`
- `sale-procedure-sequence.png`

Keep images under ~1 MB for fast repository browsing.


## Notes
- All scripts are written for MySQL.
- Make sure to run the scripts in the order listed above for proper setup.
- For any issues or questions, refer to the comments in each SQL file.

