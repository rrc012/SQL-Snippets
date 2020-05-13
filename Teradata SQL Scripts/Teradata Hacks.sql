--This Query searches for a given table against a list of databses.
SELECT T.DatabaseName,
       T.TableName,
       T.CreatorName,
       T.CommentString
  FROM dbc.DatabasesV AS DB
       INNER JOIN dbc.tablesv AS T ON DB.DatabaseName = T.DatabaseName
 WHERE 1 = 1
   AND DB.DBKind = 'D'
   AND DB.OwnerName LIKE '%%'
   AND T.TableName LIKE '%%'
   AND T.TableKind = ''
 ORDER BY 1, 2;

--This Query returns the start and end ColumnID and the number of columns present in a Table/View.
SELECT MIN(ColumnID) AS ColId_Start,
       MAX(ColumnID) AS ColId_End,
       MAX(ColumnID) - MIN(ColumnID) + 1 AS Col_Count
  FROM DBC.ColumnsV
 WHERE 1 = 1
   AND DatabaseName = 'HTGPO_Spnd_Views'
   AND TableName = 'Seller_Invoice';

--This Query generates a statement which when executed on its own generates the defenition of a View.
SELECT 'SHOW VIEW '||TRIM(databasename)||'.'||TRIM(tablename)||';'
  FROM dbc.tablesv
 WHERE 1 = 1
   AND databasename = ''
   AND tablekind = 'V'
  ORDER BY databasename, tablename;

--This Query returns the column metadata for a given table/view.
SELECT *
  FROM DBC.ColumnsV
 WHERE 1 = 1
   AND DatabaseName = ''
   AND TableName = ''
   AND ColumnName LIKE '%%'
 ORDER BY ColumnID;

--This Query returns all the column names for a given table/view as a CSV.
SELECT TRIM (Trailing ',' FROM (XmlAgg(ColumnName || ',' ORDER BY ColumnID) (VARCHAR(10000))))
  FROM dbc.columnsV
 WHERE 1 = 1
   AND DatabaseName = 'HTGPO_Spnd_Views'
   AND TableName = 'Seller_Invoice';

--This Query builds an expression that can be subsequently used in another SELECT statement to return the data types of all the columns for a given table/view as a CSV.
;WITH CTE_DataType
AS
(
SELECT TRIM (Trailing ',' FROM (XmlAgg(CONCAT('TYPE(', ColumnName, ')', ', ', '''-''') || ',' ORDER BY ColumnID) (VARCHAR(10000)))) AS Col_Type_List
  FROM dbc.columnsV
 WHERE 1 = 1
   AND DatabaseName = 'HTGPO_Spnd_Views'
   AND TableName = 'Seller_Invoice'
)
SELECT Substr(Col_Type_List, 1, Length(Col_Type_List)-5) AS Col_Type_List
  FROM CTE_DataType;

--This Query returns the data types of all the columns for a given table/view as a CSV. Use the Expresson returned from the above query and replace it between the keword
--"DISTINCT and "FROM".
SELECT DISTINCT
       CONCAT(TYPE(Seller_Invoice_SID), '-', TYPE(Source_Start_Date_Time), '-', TYPE(Seller_Name), '-', TYPE(Customer_Account_Num), '-', TYPE(Invoice_Num), '-', TYPE(Invoice_Line_Num), '-', TYPE(Invoice_Date), '-', TYPE(Source_Invoice_Date), '-', TYPE(Source_Alias_ID), '-', TYPE(GPOID), '-', TYPE(Facility_Name), '-', TYPE(COID), '-', TYPE(Seller_Provided_GPOID), '-', TYPE(Seller_Provided_Facility_Name), '-', TYPE(Seller_Provided_COID), '-', TYPE(Company_Name), '-', TYPE(Facility_Ship_to_State), '-', TYPE(Facility_Ship_to_City), '-', TYPE(Facility_Ship_to_Zip), '-', TYPE(Manufacturer_Name), '-', TYPE(Manufacturer_Catalog_Num), '-', TYPE(Seller_Part_Num), '-', TYPE(Seller_Item_Desc), '-', TYPE(Seller_GLN), '-', TYPE(Seller_Parent_GLN), '-', TYPE(Seller_Markup_Percentage), '-', TYPE(Contract_Num), '-', TYPE(Contract_Tier_Desc), '-', TYPE(Rebate_Ind), '-', TYPE(Taxable_Ind), '-', TYPE(Admin_Fee_Ind), '-', TYPE(Admin_Fee_Percentage), '-', TYPE(SIP_Ind), '-', TYPE(Shipped_Date), '-', TYPE(Source_Shipped_Date), '-', TYPE(PO_Num), '-', TYPE(PO_Line_Num), '-', TYPE(PO_Date), '-', TYPE(Source_PO_Date), '-', TYPE(PO_UOM_Code), '-', TYPE(PO_UOM_Quantity_Ordered_Amt), '-', TYPE(Source_PO_UOM_Quantity_Ordered_Amt), '-', TYPE(Original_Invoice_Num), '-', TYPE(Invoice_Type), '-', TYPE(Invoice_UOM_Code), '-', TYPE(Invoice_UOM_QOE), '-', TYPE(Source_Invoice_UOM_QOE), '-', TYPE(Invoice_UOM_QOE_Desc), '-', TYPE(Invoice_UOM_Price), '-', TYPE(Source_Invoice_UOM_Price), '-', TYPE(Invoice_UOM_Quantity), '-', TYPE(Source_Invoice_UOM_Quantity), '-', TYPE(Invoice_Extended_Sales_Price), '-', TYPE(Source_Invoice_Extended_Sales_Price), '-', TYPE(Invoice_Total_Amt), '-', TYPE(Source_Invoice_Total_Amt), '-', TYPE(Contract_Status), '-', TYPE(Compliance_Eligible_Ind), '-', TYPE(Compliance_Rule_SID), '-', TYPE(Compliance_Version), '-', TYPE(Compliance_Timestamp), '-', TYPE(ROA_Version), '-', TYPE(Recognition_Timestamp), '-', TYPE(Manufacturer_GLN), '-', TYPE(Manufacturer_Parent_GLN), '-', TYPE(Manufacturer_GTIN), '-', TYPE(Manufacturer_Parent_GTIN), '-', TYPE(Manufacturer_Production_Lot_ID), '-', TYPE(Invoice_Total_Freight_Amt), '-', TYPE(Source_Invoice_Total_Freight_Amt), '-', TYPE(Invoice_Special_Charge_Amt), '-', TYPE(Source_Invoice_Special_Charge_Amt), '-', TYPE(Invoice_Total_Tax_Amt), '-', TYPE(Source_Invoice_Total_Tax_Amt), '-', TYPE(Invoice_Payment_Terms), '-', TYPE(External_Tracking_ID), '-', TYPE(Rebate_Percentage), '-', TYPE(Base_Price), '-', TYPE(Packaging_String), '-', TYPE(Price_Source_Buy_Group), '-', TYPE(Seller_Item_Product_Level_1), '-', TYPE(Seller_Item_Product_Level_2), '-', TYPE(Seller_Item_Product_Level_3), '-', TYPE(Cross_Match_Type_Name), '-', TYPE(Cross_Match_Type_Reason), '-', TYPE(Item_Identifier), '-', TYPE(Sent_To_Event_Workbench_Ind), '-', TYPE(Recognition_Exception_SID), '-', TYPE(Suggested_Category), '-', TYPE(Catalyst_Version), '-', TYPE(Catalyst_Date_Time), '-', TYPE(Source_End_Date_Time), '-', TYPE(DW_Active_Ind), '-', TYPE(DW_Delete_Ind), '-', TYPE(Data_Source_ID), '-', TYPE(DW_Last_Update_Date_Time))
  FROM HTGPO_Spnd_Views.Seller_Invoice;

--This Query splits a sting based on the delimiter specified.
SELECT *
  FROM TABLE (StrTok_Split_To_Table('string1', 'BIGINT-TIMESTAMP(0)-VARCHAR(255)-VARCHAR(50)-VARCHAR(50)-VARCHAR(50)-DATE-VARCHAR(50)-VARCHAR(50)-VARCHAR(7)-VARCHAR(100)-VARCHAR(7)-VARCHAR(7)-VARCHAR(100)-VARCHAR(7)-VARCHAR(50)-VARCHAR(50)-VARCHAR(50)-VARCHAR(50)-VARCHAR(255)-VARCHAR(50)-VARCHAR(50)-VARCHAR(128)-VARCHAR(50)-VARCHAR(50)-VARCHAR(50)-VARCHAR(50)-VARCHAR(255)-CHAR(1)-CHAR(1)-CHAR(1)-VARCHAR(50)-CHAR(1)-DATE-VARCHAR(50)-VARCHAR(50)-VARCHAR(50)-DATE-VARCHAR(50)-VARCHAR(50)-DECIMAL(18,3)-VARCHAR(50)-VARCHAR(50)-VARCHAR(50)-VARCHAR(50)-INTEGER-VARCHAR(50)-VARCHAR(50)-DECIMAL(18,3)-VARCHAR(50)-INTEGER-VARCHAR(50)-DECIMAL(18,3)-VARCHAR(50)-DECIMAL(18,3)-VARCHAR(50)-VARCHAR(16)-CHAR(1)-BIGINT-VARCHAR(20)-TIMESTAMP(6)-VARCHAR(20)-TIMESTAMP(6)-VARCHAR(13)-VARCHAR(13)-VARCHAR(15)-VARCHAR(15)-VARCHAR(10)-DECIMAL(18,3)-VARCHAR(50)-DECIMAL(18,3)-VARCHAR(50)-VARCHAR(50)-VARCHAR(50)-VARCHAR(128)-VARCHAR(128)-VARCHAR(128)-VARCHAR(128)-VARCHAR(128)-VARCHAR(128)-VARCHAR(128)-VARCHAR(128)-VARCHAR(128)-VARCHAR(128)-VARCHAR(128)-VARCHAR(128)-CHAR(1)-BIGINT-VARCHAR(128)-VARCHAR(128)-TIMESTAMP(6)-TIMESTAMP(0)-CHAR(1)-CHAR(1)-INTEGER-TIMESTAMP(0)', '-')
RETURNS (outkey VARCHAR(10) CHARACTER SET Unicode
        ,tokennum INTEGER
        ,token VARCHAR(50) CHARACTER SET Unicode)
        ) AS dt