
### Stored Procedure - `insert_purchase_detail`

This procedure demonstrates how a single call can orchestrate multiple database operations atomically: registering a purchase header, inserting line items, and updating pharmacy stock—all within one transaction.

#### Parameters

The procedure accepts only 4 simple parameters:

```sql
CALL insert_purchase_detail(
    i_invoice_number VARCHAR(50),  -- Supplier invoice number
    i_supplier_id INT,              -- Supplier ID
    i_quantity TEXT,                -- Comma-separated quantities: '40, 50, 100'
    i_names TEXT                    -- Comma-separated drug names: 'Tylenol, Advil, Brufen'
);
```

With just these 4 inputs, the procedure performs complex multi-table operations automatically.

---

#### Step 1: Initial State - Stock Before Purchase

Before executing the purchase, let's examine the current pharmacy stock. The screenshot below shows the initial quantities for the drugs we're about to purchase:

![Stock before purchase](./sql/assets/pharmacy_stock_before_purchase.png)

**What we see:**
- **Tylenol**: Currently has 130 units in stock at $872.00 per unit
- **Advil**: Currently has 87 units in stock at $445.00 per unit  
- **Brufen**: Currently has 120 units in stock at $698.00 per unit

These quantities will be updated after the purchase is processed.

---

#### Step 2: Executing the Procedure - Simultaneous Multi-Table Insert

Now we execute the stored procedure with our purchase data:

```sql
CALL insert_purchase_detail(
    'FC-2025-014',           -- Invoice number
    1,                       -- Supplier ID (Farmacéutica del Sur)
    '40, 50, 100',          -- Quantities to purchase
    'Tylenol, Advil, Brufen' -- Drug names
);
```

With this **single call**, the procedure automatically inserts data into **two tables simultaneously**: `purchase` (header) and `purchase_detail` (line items).

![Purchase detail records - showing all inserted lines](./sql/assets/insert_purchases_sp.png)

**What the screenshot shows - `purchase_detail` table:**
The procedure created **3 detailed line items**, one for each drug:

| Line | Drug | Quantity | Unit Price | Total Price | Purchase ID | Branded Drug ID |
|------|------|----------|------------|-------------|-------------|-----------------|
| 1 | Tylenol | 40 | $3,200 | $128,000 | 32 | 1 |
| 2 | Advil | 50 | $4,500 | $225,000 | 32 | 2 |
| 3 | Brufen | 100 | $3,800 | $380,000 | 32 | 3 |

**Key observations:**
- All 3 rows share the same `purchase_id = 32` (links them to the same purchase)
- Unit prices are retrieved from `branded_drug` table
- Total prices are calculated automatically: `quantity × unit_price`
- Each row includes `branded_drug_id` as foreign key
- Timestamps (`created_at`, `updated_at`) are auto-generated

---

#### Step 3: Purchase Header Created

Simultaneously with the details, the procedure also created the purchase header in the `purchase` table:

![Purchase header - showing the generated purchase record](./sql/assets/purchase_after.png)

**What the screenshot shows - `purchase` table:**

| Purchase ID | Invoice Number | Total | Supplier ID | Created At | Updated At |
|-------------|----------------|-------|-------------|------------|------------|
| 32 | FC-2025-014 | $733,000 | 1 | 2025-11-21 18:01:49 | 2025-11-21 18:01:49 |

**Key observations:**
- **Purchase ID 32** is the same ID referenced by all detail rows
- **Invoice Number**: 'FC-2025-014' (unique identifier from supplier)
- **Total**: $733,000 (automatically calculated as sum of all line totals: $128,000 + $225,000 + $380,000)
- **Supplier ID**: 1 (Farmacéutica del Sur)
- **Timestamps**: Automatically recorded when the transaction commits

**How it works internally:**

1. **Validation Phase**
   - Checks that supplier ID 1 exists
   - Verifies drug names are unique in `branded_drug` table
   - Confirms supplier provides each drug via `branded_drug_supplier` relationship

2. **Header Insert First**
   - Creates new record in `purchase` table with invoice 'FC-2025-014'
   - Initially sets `total = 0` (will calculate after details)
   - Captures the new `purchase_id` using `LAST_INSERT_ID()` → returns 32

3. **Detail Loop** (iterates 3 times for our 3 drugs)
   - Parses first drug name ('Tylenol') and quantity (40) from comma-separated lists
   - Looks up drug details: unit price, presentation, category, expiration
   - Calculates line total: `40 × $3,200 = $128,000`
   - Inserts row into `purchase_detail` with `purchase_id = 32`
   - Repeats for 'Advil' (50 units) and 'Brufen' (100 units)

4. **Total Calculation**
   - Calls `calculate_total_purchase(32)` which sums all detail line totals
   - Updates `purchase.total = $733,000`

**This demonstrates the power of the stored procedure**: with **4 simple parameters**, it orchestrates complex operations across multiple tables, maintaining referential integrity through the shared `purchase_id`

---

#### Step 4: Stock Updated Automatically

While inserting purchase details, the procedure **simultaneously updates** `pharmacy_stock` using `ON DUPLICATE KEY UPDATE`:

![Stock after purchase](./sql/assets/stock_after_purchase.png)

**What changed:**
- **Tylenol**: 130 → **170 units** (+40 purchased)
- **Advil**: 87 → **137 units** (+50 purchased)
- **Brufen**: 120 → **220 units** (+100 purchased)

**How it works:**
```sql
INSERT INTO pharmacy_stock (name, presentation, unit_price, quantity, ...) 
VALUES (...)
ON DUPLICATE KEY UPDATE 
    quantity = pharmacy_stock.quantity + new.quantity,
    unit_price = new.unit_price,
    ...
```

Since `pharmacy_stock` has a UNIQUE constraint on `branded_drug_id`, if the drug already exists, the quantities **accumulate** instead of creating duplicates. The procedure also applies a **21% tax markup** for retail pricing:

```sql
final_price_wtaxes = unit_price + (unit_price * 0.21)
```

So wholesale prices from suppliers are marked up for pharmacy sales.

---

#### Step 5: Final Purchase Summary

The procedure completes by calculating the total and updating the purchase header:

![Purchase summary view](./sql/assets/view_purchase_details_after.png)

**Final result in `purchase` table:**
- **Invoice**: FC-2025-014
- **Total**: $733,000 (sum of all line totals: $128,000 + $225,000 + $380,000)
- **Supplier**: Farmacéutica del Sur (ID: 1)
- **Timestamp**: Automatically recorded

This is done by calling the helper function:
```sql
SET total_purchase = calculate_total_purchase(v_purchase_id);
UPDATE purchase SET total = total_purchase WHERE purchase_id = v_purchase_id;
```

The view `supplier_purchase_details` (shown in screenshot) joins all related tables to display:
- Purchase ID and invoice number
- Brand names and presentations
- Quantities and prices per line
- Supplier name
- Purchase datetime

---

#### Why This Design is Powerful

**Single Atomic Operation:**
- One procedure call updates **3 different tables** (`purchase`, `purchase_detail`, `pharmacy_stock`)
- If ANY step fails (e.g., invalid drug name), **everything rolls back**—no partial data

**Transaction Safety:**
```sql
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
    ROLLBACK;
    RESIGNAL;
END;
```

**Automatic Calculations:**
- Line totals computed from quantity × price
- Purchase total aggregated from all lines
- Stock quantities accumulated (old + new)
- Tax markup applied for retail pricing

**Data Integrity Enforced:**
- Validates supplier exists
- Checks drug names are unambiguous (no duplicates)
- Verifies supplier-drug relationship via `branded_drug_supplier`
- Ensures matching list lengths (quantities ↔ names)

---

#### Complete Example Query Sequence

```sql
-- 1. Check stock before
SELECT name, quantity, unit_price FROM pharmacy_stock 
WHERE name IN ('Tylenol', 'Advil', 'Brufen');

-- 2. Execute purchase
CALL insert_purchase_detail(
    'FC-2025-014', 
    1, 
    '40, 50, 100', 
    'Tylenol, Advil, Brufen'
);

-- 3. View purchase header
SELECT * FROM purchase WHERE invoice_number = 'FC-2025-014';

-- 4. View line items
SELECT * FROM purchase_detail 
WHERE purchase_id = (SELECT purchase_id FROM purchase WHERE invoice_number = 'FC-2025-014');

-- 5. Check stock after
SELECT name, quantity, unit_price FROM pharmacy_stock 
WHERE name IN ('Tylenol', 'Advil', 'Brufen');

-- 6. View complete purchase report (using view)
SELECT * FROM supplier_purchase_details 
WHERE Invoice = 'FC-2025-014';
```

---

#### Technical Highlights

**String Parsing Technique:**
The procedure uses `SUBSTRING_INDEX` to split comma-separated lists:
```sql
SET name = TRIM(SUBSTRING_INDEX(TRIM(i_names), ',', 1));
SET i_names = TRIM(SUBSTRING(i_names, CHAR_LENGTH(name) + 2));
```

This iteratively extracts and removes elements from the TEXT parameters.

**Upsert Pattern:**
The `ON DUPLICATE KEY UPDATE` clause elegantly handles both scenarios:
- **Drug not in stock** → INSERT new row
- **Drug already in stock** → UPDATE quantity (add to existing)

**Function Reusability:**
Total calculation is separated into `calculate_total_purchase()` function, making it:
- Testable independently
- Reusable (e.g., for recalculating totals after corrections)
- Clearer to read

---
