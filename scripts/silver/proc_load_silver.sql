/*=========================================
PROC LOAD SCRIPT: TRANSFORM AND LOAD DATA FOR SILVER LAYER

Create the procedure 'silver.load_silver' that:
Delete the previous data from the tables, then load 
data from the bronze layer and transforms them for
cleanup and standardization
===========================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
	BEGIN TRY
		PRINT '====================================='
		PRINT 'Loading Silver Layer'
		PRINT '====================================='
	
		PRINT '-------------------------------------'
		PRINT 'Loading CRM Tables'
		PRINT '-------------------------------------'
		
		SET @batch_start_time = GETDATE();
		
		SET @start_time = GETDATE();
		PRINT '>>Truncationg Table: crm_cust_info'
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>>Inserting Data Into: crm_cust_info'
		INSERT INTO silver.crm_cust_info(  
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)

		SELECT
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,
		CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
			 WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
			 ELSE 'n/a'
		END cst_marital_status,
		CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			 ELSE 'n/a'
		END cst_gndr,
		cst_create_date
		FROM(
			SELECT 
			*,
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC)as flag_last
			FROM bronze.crm_cust_info
		)t WHERE (flag_last = 1 AND cst_id IS NOT NULL)
		
		SET @end_time = GETDATE();
		PRINT '>> Loading Duration :' + CAST(DATEDIFF(microsecond, @start_time, @end_time) AS NVARCHAR) + ' microseconds';
		PRINT '-------------------------------------'
		
		SET @start_time = GETDATE();
		PRINT '>>Truncationg Table: crm_prd_info'
		TRUNCATE TABLE silver.crm_prd_info;

		PRINT '>>Inserting Data Into: crm_prd_info'
		INSERT INTO silver.crm_prd_info(
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT
		prd_id,
		REPLACE(SUBSTRING(prd_key, 1,5),'-','_') AS cat_id,
		SUBSTRING(prd_key, 7,LEN(prd_key)) AS prd_key,
		prd_nm,
		ISNULL(prd_cost,0) AS prd_cost,
		CASE UPPER(TRIM(prd_line)) 
			 WHEN 'M' THEN 'Mountain'
			 WHEN 'R' THEN 'Road'
			 WHEN 'S' THEN 'Other Sales'
			 WHEN 'T' THEN 'Touring'
			 ELSE 'n/a'
		END prd_line,
		CAST(prd_start_dt AS DATE) AS prd_start_dt,
		DATEADD(day, -1,LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
		FROM bronze.crm_prd_info

		SET @end_time = GETDATE();
		PRINT '>> Loading Duration :' + CAST(DATEDIFF(microsecond, @start_time, @end_time) AS NVARCHAR) + ' microseconds';
		PRINT '-------------------------------------'
		
		SET @start_time = GETDATE();
		PRINT '>>Truncationg Table: crm_sales_details'
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>>Inserting Data Into: crm_sales_details'
		INSERT INTO silver.crm_sales_details (
			  sls_ord_num,
			  sls_prd_key,
			  sls_cust_id,
			  sls_order_dt,
			  sls_ship_dt,
			  sls_due_dt,
			  sls_sales,
			  sls_quantity,
			  sls_price
		)
		SELECT 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE WHEN sls_order_dt <=0 OR LEN(sls_order_dt)!=8 THEN NULL 
			 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		END sls_order_dt,
		CASE WHEN sls_ship_dt <=0 OR LEN(sls_ship_dt)!=8 THEN NULL 
			 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
		END sls_ship_dt,
		CASE WHEN sls_due_dt <=0 OR LEN(sls_due_dt)!=8 THEN NULL 
			 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		END sls_due_dt,
		CASE WHEN sls_price IS NULL OR sls_price = 0 THEN sls_sales 
			 ELSE sls_quantity*ABS(sls_price) 
		END sls_sales,
		sls_quantity,
		CASE WHEN sls_price IS NULL AND sls_quantity >0 AND sls_sales >0 THEN sls_sales/sls_quantity
			 ELSE ABS(sls_price) 
		END sls_price

		FROM bronze.crm_sales_details
		
		SET @end_time = GETDATE();
		PRINT '>> Loading Duration :' + CAST(DATEDIFF(microsecond, @start_time, @end_time) AS NVARCHAR) + ' microseconds';
		PRINT '-------------------------------------'
		
		SET @start_time = GETDATE();
		PRINT '>>Truncationg Table: erp_cust_az12'
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '>>Inserting Data Into: erp_cust_az12'
		INSERT INTO silver.erp_cust_az12(
		cid,
		bdate,
		gen
		)
		SELECT 
		SUBSTRING(cid, len(cid)-9,len(cid)) cid,
		CASE WHEN bdate > GETDATE() THEN NULL 
			 ELSE bdate
		END bdate,
		CASE UPPER(TRIM(gen)) 
			WHEN 'M' THEN 'Male'
			WHEN 'MALE' THEN 'Male'
			WHEN 'F' THEN 'Female'
			WHEN 'FEMALE' THEN 'Female'
			ELSE 'n/a'
		END gen
		FROM [DataWarehouse].[bronze].[erp_cust_az12]
		

		SET @end_time = GETDATE();
		PRINT '>> Loading Duration :' + CAST(DATEDIFF(microsecond, @start_time, @end_time) AS NVARCHAR) + ' microseconds';
		PRINT '-------------------------------------'
		
		SET @start_time = GETDATE();
		PRINT '>>Truncationg Table: erp_loc_a101'
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>>Inserting Data Into: erp_loc_a101'
		INSERT INTO silver.erp_loc_a101(
		cid,
		cntry
		)
		SELECT 
		REPLACE (cid,'-','') cid,
		CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
			 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
			 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
			 ELSE TRIM(cntry)
		END cntry
		FROM [DataWarehouse].[bronze].[erp_loc_a101]

		SET @end_time = GETDATE();
		PRINT '>> Loading Duration :' + CAST(DATEDIFF(microsecond, @start_time, @end_time) AS NVARCHAR) + ' microseconds';
		PRINT '-------------------------------------'
		
		PRINT '>>Truncationg Table: silver.erp_px_cat_g1v2'
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>>Inserting Data Into: silver.erp_px_cat_g1v2'
		INSERT INTO silver.erp_px_cat_g1v2(
		id,
		cat,
		subcat,
		maintenance
		)
		SELECT
		id,
		cat,
		subcat,
		maintenance
		FROM [DataWarehouse].[bronze].[erp_px_cat_g1v2]

	END TRY
	BEGIN CATCH
		PRINT '====================================='
		PRINT 'ERROR OCCURED DRUING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '====================================='
	END CATCH
END
