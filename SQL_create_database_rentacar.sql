IF EXISTS (SELECT * FROM sys.databases WHERE name = 'RentACar')
BEGIN
    Drop DATABASE RentACar;
END
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'RentACar')
BEGIN
    CREATE DATABASE RentACar;
END
GO

USE RentACar;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'general')
BEGIN
    EXEC('CREATE SCHEMA general');
END
GO

-- Create 'rent' table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'fact_rent' AND schema_id = SCHEMA_ID('general'))
BEGIN
    CREATE TABLE general.fact_rent (
        rent_id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
        nif VARCHAR(9) NOT NULL,
        license_plate VARCHAR(8) NOT NULL,
        cc VARCHAR(12) NOT NULL, -- includes special characters
        total_amount DECIMAL(10, 2) NULL,
        date_of_rent DATE NOT NULL,
        delivery_date DATE NULL,
        daily_amount DECIMAL(10, 2) NOT NULL
    );
END
GO

-- Create 'client' table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'client' AND schema_id = SCHEMA_ID('general'))
BEGIN
    CREATE TABLE general.client (
        nif VARCHAR(9) PRIMARY KEY  NOT NULL,
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

-- Create 'model' table
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

-- Create 'address' table
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

-- Create 'employee' table
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

-- Create 'brand' table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'brand' AND schema_id = SCHEMA_ID('general'))
BEGIN
    CREATE TABLE general.brand (
        brand_id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
        brand VARCHAR(50) NOT NULL
    );
END
GO

-- Create 'car' table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'car' AND schema_id = SCHEMA_ID('general'))
BEGIN
    CREATE TABLE general.car (
        license_plate VARCHAR(8) PRIMARY KEY NOT NULL,
        model_id INT NOT NULL,
        km NUMERIC(10, 2) NOT NULL,
    );
END
GO

-- alter table

BEGIN
ALTER TABLE general.fact_rent
add constraint ck_daily_amount CHECK (daily_amount > 0),
	constraint fk_nif FOREIGN KEY (nif)
		references general.client (nif),
	constraint fk_license_plate FOREIGN KEY (license_plate)
		references general.car (license_plate),
	constraint fk_cc FOREIGN KEY (cc)
		references general.employee (cc)
END
GO

BEGIN
ALTER TABLE general.car
add constraint fk_model_id FOREIGN KEY (model_id)
	references general.model (model_id),
constraint ck_km CHECK (km>0)
END
GO

BEGIN
ALTER TABLE general.brand
add constraint uc_brand unique(brand)
END
GO

BEGIN
ALTER TABLE general.model
add constraint ck_nr_seats CHECK (nr_seats > 0 AND nr_seats < 10),
constraint ck_production_year  CHECK (production_year  > 1950 AND production_year < year(getdate())),
constraint ck_type_of_fuel CHECK (UPPER(type_of_fuel) in ('DIESEL', 'GASOLINA', 'ELÉTRICO')),
constraint fk_brand_id FOREIGN KEY (brand_id)
	references general.brand (brand_id)
END
GO

BEGIN
ALTER TABLE general.client
add constraint ck_phone_number_1 CHECK ( phone_number LIKE '+[1-9]%' AND LEN(phone_number) BETWEEN 7 AND 15), --CHECK (phone_number not like '%[^0-9]%'), 
constraint uc_cc unique(cc),
constraint uc_driver_license_nr unique(driver_licence_nr),
constraint uc_credit_card_number unique(credit_card_number),
constraint fk_address_id FOREIGN KEY ([address_id])
		references general.[address] ([address_id])
END
GO

BEGIN
ALTER TABLE general.[address]
add constraint ck_number CHECK (number > 0),
constraint ck_floor CHECK ([floor] >= 0),
constraint ck_zip_code CHECK (zip_code  LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9]')
END
GO

BEGIN
ALTER TABLE general.employee
add constraint ck_phone_number CHECK ( phone_number LIKE '+[1-9]%' AND LEN(phone_number) BETWEEN 7 AND 15)
END
GO