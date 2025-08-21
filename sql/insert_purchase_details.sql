use pharmacy_db;

DROP FUNCTION  IF EXISTS calculate_total_purchase;

DELIMITER $$
CREATE FUNCTION calculate_total_purchase (p_purchase_id INT)
RETURNS DECIMAL(10, 2)

DETERMINISTIC 
READS SQL DATA

BEGIN
    DECLARE total DECIMAL(10, 2);
	SELECT SUM(quantity * unit_price) into total
    FROM purchase_detail
    WHERE purchase_id = p_purchase_id;
    
    RETURN IFNULL(total, 0); 
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS insert_purchase_detail;
DELIMITER //

CREATE PROCEDURE insert_purchase_detail(
    IN i_invoice_number VARCHAR(50),
    IN i_supplier_id INT,
    IN i_quantity TEXT,
    IN i_names TEXT
)
BEGIN
    DECLARE v_delimiter CHAR(1) DEFAULT ',';
    DECLARE error_message TEXT;
    DECLARE unit_price DECIMAL(10, 2);
    DECLARE total_price DECIMAL(10, 2);
    DECLARE total_supplier_id INT;
    DECLARE total_purchase_id INT;
    DECLARE total_purchase DECIMAL(10, 2) DEFAULT 0;
    DECLARE name VARCHAR(100);
    DECLARE quantity INT;
    DECLARE branded_drug_id INT;
    DECLARE presentation VARCHAR(100);
    DECLARE category VARCHAR(100);
    DECLARE expiration_date DATETIME;
    DECLARE cnt INT;
    DECLARE v_purchase_id INT;
    DECLARE final_price_wtaxes DECIMAL(10, 2) DEFAULT 0;

	-- Error handler: undo everything if something fails
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
IF i_names IS NULL OR TRIM(i_names) = '' THEN
		SET error_message = 'La lista de nombres no puede estar vacía';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
END IF;

IF i_quantity IS NULL OR TRIM(i_quantity) = '' THEN
		SET error_message = 'La lista de cantidades no puede estar vacía';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
END IF;

-- Validate that the values ​​are not null or negative if applicable
IF i_supplier_id <= 0 THEN
	SET error_message = 'El id del proveedor debe ser mayor a 1';
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
END IF;

SELECT COUNT(*) INTO cnt FROM supplier WHERE supplier_id = i_supplier_id;
IF cnt = 0 THEN
    SET error_message = CONCAT('Supplier ID ', i_supplier_id, ' does not exist');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
END IF;


START TRANSACTION;

INSERT INTO purchase(invoice_number, total, supplier_id)
VALUES(i_invoice_number, total_purchase, i_supplier_id);

SET v_purchase_id := LAST_INSERT_ID();

-- Split the name string and insert into purchase_details
WHILE CHAR_LENGTH(i_names) > 0 DO
	
	SET name = TRIM(SUBSTRING_INDEX(TRIM(i_names), v_delimiter, 1)); -- Get the first name and remove spaces
	SET i_names = TRIM(SUBSTRING(i_names, CHAR_LENGTH(name) + 2)); -- Remove the name from the string and trim spaces

	-- Get the first quantity as INT
	SET quantity = CAST(SUBSTRING_INDEX(TRIM(i_quantity), v_delimiter, 1) AS UNSIGNED);
	-- remove the quantity from the string
	SET i_quantity = TRIM(SUBSTRING(i_quantity, CHAR_LENGTH(CAST(quantity AS CHAR)) + 2));
	
    -- Reset variables to avoid carrying over previous values
    SET branded_drug_id = NULL;
    SET unit_price = NULL;
    SET presentation = NULL;
    SET category = NULL;
    SET expiration_date = NULL;

    -- Check for ambiguity first
	SELECT COUNT(*) INTO cnt
	FROM branded_drug bd
	WHERE TRIM(UPPER(bd.brand_name)) = TRIM(UPPER(name));
    
	 IF cnt = 0 THEN
        SET error_message = CONCAT('Branded drug not found: ', name);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    ELSEIF cnt > 1 THEN
        SET error_message = CONCAT('Ambiguous branded drug name: ', name, ' (multiple matches)');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    ELSE 
    	SELECT bd.branded_drug_id, bd.unit_price, bd.presentation, bd.category, bd.expiration_date
		INTO branded_drug_id, unit_price, presentation, category, expiration_date
		FROM branded_drug AS bd
		WHERE TRIM(UPPER(bd.brand_name)) = TRIM(UPPER(name));
    END IF;
	
    SELECT COUNT(*) INTO cnt
    FROM branded_drug_supplier bds
    WHERE bds.branded_drug_id = branded_drug_id
		AND bds.supplier_id = i_supplier_id;
    
    IF cnt = 0 THEN
        SET error_message = CONCAT('The supplier dont have the branded_drug: ', name);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    ELSEIF cnt > 1 THEN
        SET error_message = CONCAT('Ambiguous branded drug name: ', name, ' (multiple matches)');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
	END IF;

	-- Calculate total price
	SET total_price = quantity * unit_price;

	-- Insert into purchase_detail
	INSERT INTO purchase_detail (quantity, unit_price, total_price, purchase_id, branded_drug_id)
	VALUES (quantity, unit_price, total_price, v_purchase_id, branded_drug_id);
    
    SET final_price_wtaxes = unit_price + (unit_price * 0.21);
    
    INSERT INTO pharmacy_stock (name, presentation, unit_price, quantity, category, expiration_date, branded_drug_id) 
    VALUES (name, presentation, final_price_wtaxes, quantity, category, expiration_date, branded_drug_id)
    AS new
    ON DUPLICATE KEY UPDATE 
		presentation = new.presentation,
		unit_price = new.unit_price,
        quantity = pharmacy_stock.quantity + new.quantity,
        category = new.category,
        expiration_date = new.expiration_date;
END WHILE;

-- Calculate total purchase and update header
SET total_purchase = calculate_total_purchase(v_purchase_id);

UPDATE purchase
SET total = total_purchase
WHERE purchase_id = v_purchase_id;

COMMIT;


END //
DELIMITER ;

select 
	bds.branded_drug_supplier_id,
    bds.supplier_id,
    bds.branded_drug_id,
    bd.brand_name
from
	branded_drug_supplier bds
join branded_drug bd on
	bd.branded_drug_id = bds.branded_drug_id
order by
	bds.supplier_id;
    
CALL insert_purchase_detail("FC-2025-010", 1, '4, 6, 6', 'Tylenol, Advil, Brufen');
select * from purchase;
select * from purchase_detail;
select * from pharmacy_stock;
SHOW INDEX FROM pharmacy_stock WHERE Column_name = 'branded_drug_id';
