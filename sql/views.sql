use pharmacy_db;
/*supplier_purchase_details allows viewing all the details of purchases made from the pharmacy to suppliers.
In addition, the invoice number associated with each purchase will be displayed, along with the brand name of the medication and its presentation from the branded_drug table
and the suppliers from whom the purchase was made.*/

CREATE VIEW supplier_purchase_details AS
SELECT  
    p.purchase_id AS "Purchase ID",
    p.invoice_number AS "Invoice",
    b.brand_name AS "Brand Name",
    b.presentation AS "Presentation",
    d.quantity AS "Quantity",
    d.unit_price AS "Unit Price",
    d.total_price AS "Total Price",
    s.name AS "Supplier",
    p.created_at AS "Purchase Datetime"
FROM  
    purchase_detail d
INNER JOIN purchase p ON p.purchase_id = d.purchase_id
INNER JOIN branded_drug b ON d.branded_drug_id = b.branded_drug_id
INNER JOIN supplier s ON p.supplier_id = s.supplier_id
ORDER BY p.invoice_number;

select * from supplier_purchase_details;

/*This view displays all the data from the branded_drug table, showing its name, presentation,
drug, laboratory, unit price, available quantity, whether it's over-the-counter or prescription, its expiration date, the supplier and datetime.
We retrieve the name of the drug, laboratory, and supplier associated with each branded drug using the IDs they share with the drug_laboratory table
sorting it by its ID.*/

CREATE VIEW branded_drug_catalog AS
SELECT
    b.branded_drug_id AS "Branded Drug ID",
    b.brand_name AS "Name",
    b.presentation AS "Presentation",
    d.name AS "Drug",
    l.name AS "Laboratory",
    b.unit_price AS "Unit Price",
    b.available_quantity AS "Available Quantity",
    b.category AS "Prescription/OTC",
    b.expiration_date AS "Expiration Date",
    s.name AS "Supplier"
FROM 
    branded_drug b
LEFT JOIN drug d ON b.drug_id = d.drug_id
LEFT JOIN laboratory l ON b.laboratory_id = l.laboratory_id
LEFT JOIN branded_drug_supplier bds ON b.branded_drug_id = bds.branded_drug_id
LEFT JOIN supplier s ON bds.supplier_id = s.supplier_id
ORDER BY b.branded_drug_id ASC;

select * from branded_drug_catalog;


/*
The detailed_sales view allows you to view data on the sales made to customers. Sorted by the sale_id from the sales table, we can see:
the receipt, quantity, and unit_price from the sales_details table, first and last name from the customer table, and branded drug and presentation from the pharmacy_stock table.
the first and last name from the staff table.
*/

CREATE VIEW detailed_sales AS
SELECT 
    d.sale_id AS "Sale ID",
    s.invoice_number AS "Invoice",
    c.first_name AS "Customer First Name",
    c.last_name AS "Customer Last Name",
    ps.name AS "Branded drug",
    ps.presentation AS "Presentation",
    COALESCE(pr.prescription_number, 'Over-the-Counter') AS "Prescription Number",
    d.quantity AS "Quantity",
    d.unit_price AS "Unit Price",
    st.first_name AS "Staff First Name",
    st.last_name AS "Staff Last Name",
    s.created_at AS "Sale Datetime"
FROM sale_detail d
LEFT JOIN sale s ON d.sale_id = s.sale_id
LEFT JOIN prescription pr ON pr.prescription_id = d.prescription_id
LEFT JOIN pharmacy_stock ps ON ps.pharmacy_stock_id = d.pharmacy_stock_id
LEFT JOIN staff st ON st.staff_id = s.staff_id
LEFT JOIN customer c ON s.customer_id = c.customer_id
ORDER BY d.sale_id ASC;

select * from detailed_sales;


/*
The customer_profile view displays complete client information. First name, last name, phone number, address, email, ID, date of birth, and membership number
from the client table, which social security or prepaid plan they have, nationality, province, city, district, and gender from each table.
*/


CREATE VIEW customer_profile AS
SELECT 
    c.first_name AS "First Name",
    c.last_name AS "Last Name",
    c.phone AS "Phone",
    c.address AS "Address",
    c.email AS "Email",
    c.national_id AS "National ID",
    c.birth_date AS "Birth Date",
    COALESCE(ss.company_name, "NO COVERAGE") AS "Social Service",
    COALESCE(hi.company_name, "NO COVERAGE") AS "Insurance",
    c.affiliate_number AS "Affiliate Number",
    n.name AS "Nationality",
    st.name AS "State",
    ci.name AS "City",
    di.name AS "District",
    g.gender AS "Gender"
FROM customer c
LEFT JOIN social_service ss ON c.social_service_id = ss.social_service_id
LEFT JOIN health_insurance hi ON c.insurance_id = hi.insurance_id
LEFT JOIN nationality n ON c.nationality_id = n.nationality_id
LEFT JOIN state st ON c.state_id = st.state_id
LEFT JOIN city ci ON c.city_id = ci.city_id
LEFT JOIN district di ON c.district_id = di.district_id
LEFT JOIN gender g ON c.gender_id = g.gender_id
ORDER BY c.customer_id DESC;

select * from customer_profile;

