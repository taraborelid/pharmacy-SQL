DROP DATABASE IF EXISTS pharmacy_db;

-- PHARMACY DATABASE PROJECT - DENIS TARABORELI

CREATE DATABASE pharmacy_db;
USE pharmacy_db;

-- TABLE CREATION

CREATE TABLE IF NOT EXISTS gender (
    gender_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    gender ENUM('Male', 'Female')
);

CREATE TABLE IF NOT EXISTS nationality (
    nationality_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS district (
    district_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS state (
    state_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS drug (
    drug_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL -- prescription or over-the-counter
);

CREATE TABLE IF NOT EXISTS city (
    city_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS laboratory (
    laboratory_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(100),
    phone VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    nationality_id INT NOT NULL,
    state_id INT,
    city_id INT,
    FOREIGN KEY (nationality_id) REFERENCES nationality(nationality_id),
    FOREIGN KEY (state_id) REFERENCES state(state_id),
    FOREIGN KEY (city_id) REFERENCES city(city_id)
);

CREATE TABLE IF NOT EXISTS branded_drug (
    branded_drug_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    brand_name VARCHAR(100) NOT NULL,
    presentation VARCHAR(50) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    available_quantity INT NOT NULL,
    category VARCHAR(50) NOT NULL,
    expiration_date DATETIME,
    drug_id INT NOT NULL,
    laboratory_id INT NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (drug_id) REFERENCES drug(drug_id),
    FOREIGN KEY (laboratory_id) REFERENCES laboratory(laboratory_id),
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS supplier (
    supplier_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(100) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(100),
    tax_id VARCHAR(30) NOT NULL,
    nationality_id INT NOT NULL,
    state_id INT NOT NULL,
    city_id INT NOT NULL,
    FOREIGN KEY (nationality_id) REFERENCES nationality(nationality_id),
    FOREIGN KEY (state_id) REFERENCES state(state_id),
    FOREIGN KEY (city_id) REFERENCES city(city_id)
);

CREATE TABLE IF NOT EXISTS branded_drug_supplier (
    branded_drug_supplier_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    supplier_id INT NOT NULL,
    branded_drug_id INT NOT NULL,
    FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id),
    FOREIGN KEY (branded_drug_id) REFERENCES branded_drug(branded_drug_id)
);

CREATE TABLE IF NOT EXISTS pharmacy_stock (
    pharmacy_stock_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    presentation VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    category VARCHAR(20) NOT NULL,
    expiration_date DATETIME,
    branded_drug_id INT NOT NULL UNIQUE,
    FOREIGN KEY (branded_drug_id) REFERENCES branded_drug(branded_drug_id),
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

);

CREATE TABLE IF NOT EXISTS purchase (
    purchase_id INT PRIMARY KEY AUTO_INCREMENT,
    invoice_number VARCHAR(50),
    total DECIMAL(10,2),
    supplier_id INT,
    FOREIGN KEY (supplier_id) REFERENCES supplier(supplier_id),
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS purchase_detail (
    purchase_detail_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    purchase_id INT NOT NULL,
    branded_drug_id INT NOT NULL,
    FOREIGN KEY (purchase_id) REFERENCES purchase(purchase_id),
    FOREIGN KEY (branded_drug_id) REFERENCES branded_drug(branded_drug_id),
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS health_insurance (
    insurance_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    company_name VARCHAR(100),
    tax_id VARCHAR(30),
    address VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS insurance_plan (
    insurance_plan_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    plan_name VARCHAR(100),
    insurance_id INT NOT NULL,
    FOREIGN KEY (insurance_id) REFERENCES health_insurance(insurance_id)
);

CREATE TABLE IF NOT EXISTS social_service (
    social_service_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    company_name VARCHAR(100),
    tax_id VARCHAR(30),
    address VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS social_service_plan (
    social_service_plan_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    plan_name VARCHAR(100),
    social_service_id INT NOT NULL,
    FOREIGN KEY (social_service_id) REFERENCES social_service(social_service_id)
);

CREATE TABLE IF NOT EXISTS customer (
    customer_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    address VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    national_id VARCHAR(30) NOT NULL UNIQUE,
    birth_date DATETIME NOT NULL,
    affiliate_number VARCHAR(100),
    social_service_id INT,
    insurance_id INT,
    nationality_id INT NOT NULL,
    state_id INT NOT NULL,
    city_id INT NOT NULL,
    district_id INT NOT NULL,
    gender_id INT NOT NULL,
    FOREIGN KEY (social_service_id) REFERENCES social_service(social_service_id),
    FOREIGN KEY (insurance_id) REFERENCES health_insurance(insurance_id),
    FOREIGN KEY (nationality_id) REFERENCES nationality(nationality_id),
    FOREIGN KEY (state_id) REFERENCES state(state_id),
    FOREIGN KEY (district_id) REFERENCES district(district_id),
    FOREIGN KEY (city_id) REFERENCES city(city_id),
    FOREIGN KEY (gender_id) REFERENCES gender(gender_id)
);

CREATE TABLE IF NOT EXISTS doctor (
    doctor_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    license_number VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS staff (
    staff_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    address VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    national_id VARCHAR(30) NOT NULL UNIQUE,
    birth_date DATETIME NOT NULL,
    district_id INT NOT NULL,
    state_id INT NOT NULL,
    FOREIGN KEY (district_id) REFERENCES district(district_id),
    FOREIGN KEY (state_id) REFERENCES state(state_id)
);

CREATE TABLE IF NOT EXISTS sale (
    sale_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    invoice_number VARCHAR(50) NOT NULL,
    total_amount DECIMAL(10,2),
    customer_id INT NOT NULL,
    staff_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS prescription (
    prescription_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    prescription_number VARCHAR(50) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    customer_id INT NOT NULL,
    doctor_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id)
);

CREATE TABLE IF NOT EXISTS sale_detail (
    sale_detail_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    quantity INT NOT NULL,
    pharmacy_stock_id INT NOT NULL,
    unit_price DECIMAL(10,2),
    final_price DECIMAL(10,2),
    prescription_id INT,
    sale_id INT NOT NULL,
    FOREIGN KEY (sale_id) REFERENCES sale(sale_id),
    FOREIGN KEY (pharmacy_stock_id) REFERENCES pharmacy_stock(pharmacy_stock_id),
    FOREIGN KEY (prescription_id) REFERENCES prescription(prescription_id),
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
