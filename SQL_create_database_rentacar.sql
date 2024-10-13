-- Check if the 'RentACar' database exists, drop it if it does
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'RentACar')
BEGIN
    DROP DATABASE RentACar;
END
GO

-- Create 'RentACar' database if it does not exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'RentACar')
BEGIN
    CREATE DATABASE RentACar;
END
GO

-- Use 'RentACar' database
USE RentACar;
GO

-- Create 'general' schema if it does not exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'general')
BEGIN
    EXEC('CREATE SCHEMA general');
END
GO

-- =======================================
-- Create 'fact_rent' table (Rental information)
-- =======================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fact_rent' AND schema_id = SCHEMA_ID('general'))
BEGIN
    CREATE TABLE general.fact_rent (
        rent_id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
        nif VARCHAR(9) NOT NULL,
        license_plate VARCHAR(8) NOT NULL,
        cc VARCHAR(12) NOT NULL,  -- Employee code (includes special characters)
        total_amount DECIMAL(10, 2) NULL,
        date_of_rent DATE NOT NULL,
        delivery_date DATE NULL,
        daily_amount DECIMAL(10, 2) NOT NULL
    );
END
GO

-- =======================================
-- Create 'client' table (Client information)
-- =======================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'client' AND schema_id = SCHEMA_ID('general'))
BEGIN
    CREATE TABLE general.client (
        nif VARCHAR(9) PRIMARY KEY NOT NULL,
        cc VARCHAR(12) NOT NULL,
        first_name VARCHAR(20) NOT NULL,
        last_name VARCHAR(20) NOT NULL,
        driver_licence_nr VARCHAR(9) NOT NULL,
        driver_licence_expiration_date DATE NOT NULL,
        address_id INT NOT NULL,
        credit_card_number VARCHAR(16) NOT NULL,
        phone_number VARCHAR(20) NOT NULL,
        email VARCHAR(40) NULL,
        birth_date DATE NOT NULL
    );
END
GO

-- =======================================
-- Create 'model' table (Car models)
-- =======================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'model' AND schema_id = SCHEMA_ID('general'))
BEGIN
    CREATE TABLE general.model (
        model_id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
        color VARCHAR(50) NULL,
        nr_seats INT NOT NULL,
        production_year INT NOT NULL,
        category VARCHAR(50) NULL,
        type_of_fuel VARCHAR(50) NOT NULL,
        brand_id INT NOT NULL
    );
END
GO

-- =======================================
-- Create 'address' table (Client addresses)
-- =======================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'address' AND schema_id = SCHEMA_ID('general'))
BEGIN
    CREATE TABLE general.[address] (
        address_id INT PRIMARY KEY NOT NULL,
        country NVARCHAR(50) NOT NULL,
        street NVARCHAR(50) NOT NULL,
        number INT NOT NULL,
        [floor] INT NULL,
        zip_code NVARCHAR(7) NOT NULL,
        region NVARCHAR(20) NOT NULL
    );
END
GO

-- =======================================
-- Create 'employee' table (Employee information)
-- =======================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'employee' AND schema_id = SCHEMA_ID('general'))
BEGIN
    CREATE TABLE general.employee (
        cc VARCHAR(12) PRIMARY KEY NOT NULL,
        first_name VARCHAR(10) NOT NULL,
        last_name VARCHAR(10) NOT NULL,
        gender VARCHAR(10) NULL,
        employment_start_date DATE NOT NULL,
        employment_end_date DATE NULL,
        date_of_birth DATE NULL,
        phone_number VARCHAR(20) NOT NULL
    );
END
GO

-- =======================================
-- Create 'brand' table (Car brands)
-- =======================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'brand' AND schema_id = SCHEMA_ID('general'))
BEGIN
    CREATE TABLE general.brand (
        brand_id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
        brand VARCHAR(50) NOT NULL
    );
END
GO

-- =======================================
-- Create 'car' table (Cars available for rent)
-- =======================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'car' AND schema_id = SCHEMA_ID('general'))
BEGIN
    CREATE TABLE general.car (
        license_plate VARCHAR(8) PRIMARY KEY NOT NULL,
        model_id INT NOT NULL,
        km NUMERIC(10, 2) NOT NULL
    );
END
GO

-- =======================================
-- Alter Tables: Add Constraints and Foreign Keys
-- =======================================

-- Alter 'fact_rent' table: Add constraints and foreign keys
BEGIN
    ALTER TABLE general.fact_rent
    ADD CONSTRAINT ck_daily_amount CHECK (daily_amount > 0),
        CONSTRAINT fk_nif FOREIGN KEY (nif) REFERENCES general.client (nif),
        CONSTRAINT fk_license_plate FOREIGN KEY (license_plate) REFERENCES general.car (license_plate),
        CONSTRAINT fk_cc FOREIGN KEY (cc) REFERENCES general.employee (cc);
END
GO

-- Alter 'car' table: Add foreign key and constraint for kilometers
BEGIN
    ALTER TABLE general.car
    ADD CONSTRAINT fk_model_id FOREIGN KEY (model_id) REFERENCES general.model (model_id),
        CONSTRAINT ck_km CHECK (km > 0);
END
GO

-- Alter 'brand' table: Enforce unique brand names
BEGIN
    ALTER TABLE general.brand
    ADD CONSTRAINT uc_brand UNIQUE (brand);
END
GO

-- Alter 'model' table: Add constraints for seats, production year, fuel type, and foreign key
BEGIN
    ALTER TABLE general.model
    ADD CONSTRAINT ck_nr_seats CHECK (nr_seats > 0 AND nr_seats < 10),
        CONSTRAINT ck_production_year CHECK (production_year > 1950 AND production_year < YEAR(GETDATE())),
        CONSTRAINT ck_type_of_fuel CHECK (UPPER(type_of_fuel) IN ('DIESEL', 'GASOLINA', 'ELÉTRICO')),
        CONSTRAINT fk_brand_id FOREIGN KEY (brand_id) REFERENCES general.brand (brand_id);
END
GO

-- Alter 'client' table: Add constraints for phone number, unique fields, and foreign key
BEGIN
    ALTER TABLE general.client
    ADD CONSTRAINT ck_phone_number_1 CHECK (phone_number LIKE '+[1-9]%' AND LEN(phone_number) BETWEEN 7 AND 15),
        CONSTRAINT uc_cc UNIQUE (cc),
        CONSTRAINT uc_driver_license_nr UNIQUE (driver_licence_nr),
        CONSTRAINT uc_credit_card_number UNIQUE (credit_card_number),
        CONSTRAINT fk_address_id FOREIGN KEY (address_id) REFERENCES general.[address] (address_id);
END
GO

-- Alter 'address' table: Add constraints for address details
BEGIN
    ALTER TABLE general.[address]
    ADD CONSTRAINT ck_number CHECK (number > 0),
        CONSTRAINT ck_floor CHECK ([floor] >= 0),
        CONSTRAINT ck_zip_code CHECK (zip_code LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9]');
END
GO

-- Alter 'employee' table: Add constraint for phone number format
BEGIN
    ALTER TABLE general.employee
    ADD CONSTRAINT ck_phone_number CHECK (phone_number LIKE '+[1-9]%' AND LEN(phone_number) BETWEEN 7 AND 15);
END
GO
