# sql-data-warehouse-project

Design Exercise for a data warehouse with a SQL Server, including ETL processes, data modeling, and analytics

Based on the turorial series by Data with Baraa

https://youtu.be/9GVqKuTVANE?si=yV5pYLd9XMRY7iqh

---

## Project Requirements
**Objective:**

Develop a modern data warehouse using SQL Server to consolidate sales data, enabling analytical reporting

**Specification:**

- **Data Sources:** Import data from 2 source systems (ERP and CRM) provides as CSV files
- **Data Quality:** Cleanse and resolve data quality issue prior to analysis
- **Integration:** Combine both sources into a single, user-friendly data model designed for analytical queries.
- **Scope:** Focus on the latest datasets only; historization of data is not required.
- **Documentation:**  Provide clear documentation of the data model to support both business stakeholders and analytics team

The database is erranged using the medallion architecture as follows:
![High Level Architefcture](/docs/HL%20Architecture.png)
![Data Flow](/docs/Data%20Flow.png)

The practice data processed was 6 csv files, detailing the customer, product, and sales information of a outdoor equipment shop.
After being extracted to the Bronze layer, the data was cleaned and standarized in the silver layer to allow integration within the gold layer.
![Integration Model Detailed](/docs/Integration Model Detail.png)

The final data is presented as views in the gold layer, detailed in a [catalog](/docs/data_catalog.md) and arranged in star schema as follows:
![Gold Layer](/docs/Gold%20Layer%20Data.png) 
