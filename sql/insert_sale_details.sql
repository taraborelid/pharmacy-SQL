use pharmacy_db;

DROP FUNCTION  IF EXISTS calculate_total_sale;

DELIMITER $$
CREATE FUNCTION calculate_total_sale (p_sale_id INT)
RETURNS DECIMAL(10, 2)

DETERMINISTIC 
READS SQL DATA


BEGIN
    DECLARE total DECIMAL(10, 2);
	SELECT SUM(quantity * unit_price) into total
    FROM sale_detail
    WHERE sale_id = p_sale_id;

    RETURN IFNULL(total, 0); 
END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS insert_sale_details;
DELIMITER //

CREATE PROCEDURE insert_sale_details(
    IN i_invoice_number VARCHAR(50),
    IN i_customer_id INT,
    IN i_staff_id INT,
    IN i_names TEXT,
    IN i_quantity TEXT,
    IN i_prescriptions TEXT
)
BEGIN 
    DECLARE v_delimiter  CHAR(1) DEFAULT ',';
    DECLARE error_message TEXT;
    DECLARE unit_price DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE final_price DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE total_sale DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_sale_id INT;
    DECLARE name VARCHAR(255);
    DECLARE quantity INT; 
    DECLARE cnt INT;
    DECLARE v_pharmacy_stock_id INT;
    DECLARE v_current_stock INT DEFAULT 0;
	DECLARE prescription VARCHAR(50);
	DECLARE v_prescription_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;


    IF i_customer_id < 1 THEN
        SET error_message = 'Invalid customer ID';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    SELECT COUNT(*) INTO cnt FROM customer WHERE customer_id = i_customer_id;
    IF cnt = 0 THEN
        SET error_message = 'Customer does not exist';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    IF i_staff_id < 1 THEN
        SET error_message = 'Invalid staff ID';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    SELECT COUNT(*) INTO cnt FROM staff WHERE staff_id = i_staff_id;
    IF cnt = 0 THEN
        SET error_message = 'Staff does not exist';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    SELECT COUNT(*) INTO cnt FROM sale WHERE invoice_number = i_invoice_number;
    IF cnt > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Duplicate invoice_number';
    END IF;
	
    
    IF TRIM(i_prescriptions) = '' THEN 
        SET error_message = 'Prescription list cannot be empty';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;
    
    IF i_names IS NULL OR TRIM(i_names) = '' THEN 
        SET error_message = 'Name list cannot be empty';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;

    if i_quantity IS NULL OR TRIM(i_quantity) = '' THEN 
        SET error_message = 'Quantity list cannot be empty';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
    END IF;
	
    IF i_invoice_number IS NULL OR TRIM(i_invoice_number) = '' THEN
		SET error_message = 'Invoice number cannot be empty';
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
	END IF;

    START TRANSACTION;

    INSERT INTO sale (invoice_number, total_amount, customer_id, staff_id)
    VALUES (i_invoice_number, total_sale, i_customer_id, i_staff_id);

    SET v_sale_id = LAST_INSERT_ID();

    WHILE CHAR_LENGTH(i_names) > 0 DO
		
        SET name = TRIM(SUBSTRING_INDEX(TRIM(i_names), v_delimiter, 1));
        SET i_names = TRIM(SUBSTRING(i_names, CHAR_LENGTH(name) + 2));

        SET quantity = TRIM(SUBSTRING_INDEX(TRIM(i_quantity), v_delimiter, 1));
        SET i_quantity = TRIM(SUBSTRING(i_quantity, CHAR_LENGTH(quantity) + 2));
		
        SET prescription = TRIM(SUBSTRING_INDEX(TRIM(i_prescriptions), v_delimiter, 1));
        SET i_prescriptions = TRIM(SUBSTRING(i_prescriptions, CHAR_LENGTH(prescription) + 2));
        
        IF prescription IS NULL OR prescription = '' OR UPPER(prescription) = 'NULL' THEN
			SET v_prescription_id = NULL;
		ELSE
			SET v_prescription_id = CAST(prescription AS UNSIGNED);
			IF v_prescription_id IS NULL OR v_prescription_id < 1 THEN
				SET error_message = CONCAT('Invalid prescription for ', name);
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
			END IF;

			SELECT COUNT(*) INTO cnt
			FROM prescription
			WHERE prescription_id = v_prescription_id;

			IF cnt = 0 THEN
				SET error_message = CONCAT('Prescription ', v_prescription_id, ' does not exist for ', name);
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
			END IF;
		END IF;

        IF quantity IS NULL OR quantity < 1 THEN
            SET error_message = CONCAT('Invalid quantity for ', name);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
        END IF;


        SELECT COUNT(*) INTO cnt
        FROM pharmacy_stock ps
        WHERE TRIM(UPPER(ps.name)) = TRIM(UPPER(name));

        IF cnt = 0 THEN
			SET error_message = CONCAT('Item ', name, ' does not exist in stock');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
        ELSEIF cnt > 1 THEN
			SET error_message = CONCAT('Item ', name, ' does not exist in stock');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
        END IF;

        SELECT ps.pharmacy_stock_id, ps.unit_price, ps.quantity
        INTO v_pharmacy_stock_id, unit_price, v_current_stock
        FROM pharmacy_stock ps
        WHERE TRIM(UPPER(ps.name)) = TRIM(UPPER(name))
        FOR UPDATE;

        IF v_current_stock IS NULL THEN
			SET error_message = CONCAT('Stock row not found for ', name);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
        END IF;

        IF v_current_stock < quantity THEN
			SET error_message = CONCAT('Insufficient stock for ', name);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
        END IF;

        SET final_price = unit_price * quantity;

        INSERT INTO sale_detail (quantity, pharmacy_stock_id, unit_price, final_price, prescription_id, sale_id)
        VALUES (quantity, v_pharmacy_stock_id, unit_price, final_price, v_prescription_id, v_sale_id);

        UPDATE pharmacy_stock ps
        SET ps.quantity = ps.quantity - quantity
        WHERE ps.pharmacy_stock_id = v_pharmacy_stock_id;

    END WHILE;
	
    IF TRIM(i_quantity) <> '' THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Quantity list length does not match names list';
	END IF;

    
    SET total_sale = calculate_total_sale(v_sale_id);

    UPDATE sale
    SET total_amount = total_sale
    WHERE sale_id = v_sale_id;

    COMMIT;

END //

DELIMITER ;

CALL insert_sale_details("FV-2025-04", 2, 1, 'Tylenol, Advil, Brufen', '4, 6, 6', '1, null, 3');
select * from sale;
select * from sale_detail;
select * from pharmacy_stock;
