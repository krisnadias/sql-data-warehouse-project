/*
========================================
INIT DATABASE: CREATE DATABASE AND SCHEMAS

Creates a nwe database named 'DataWarehouse'
and drops the old one if it exist. Would also
Create 3 schemas: bronze, silver, gold.

Warning:
Will drop the entire 'DataWarehouse' database
if it already exist
========================================
*/

USE master;
GO

--Drop and recreate the 'DataWarehouse` dataset
IF EXISTS (select 1 From sys.databases WHERE name = 'DataWarehouse')
BEGIN
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE DataWarehouse;
END;
GO

CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
