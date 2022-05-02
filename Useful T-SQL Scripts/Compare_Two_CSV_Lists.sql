SET NOCOUNT ON;

/*
 ==========================================================================
 Author:	  Raghunandan Cumbakonam
 Source:      http://www.sqlservercentral.com/articles/Tally+Table/72993/
 Create Date: 15-FEB-2022
 Description: 1. This code compares the individual members from TWO
                 different CSV Lists and gives the list of members missing
                 across the other CSV list.
              2. This code uses the split8K function by Jeff Moden to split
                 the CSV list into individual elements based on the
                 delimiter.
              3. The premise of using a split8K function instead of the
                 in-built STRING_SPLIT function is to make the code
                 backward compatible.
              4. The premise of NOT encapsulating this logic into a SP or
                 a UDF is to make this code environment independent.
 ==========================================================================
*/

DECLARE @sList1 VARCHAR(8000) = 'ISSUERID|IVA_COMPANY_RATING|IVA_RATING_DATE|IVA_INDUSTRY|IVA_PREVIOUS_RATING|IVA_RATING_TREND|INDUSTRY_ADJUSTED_SCORE|WEIGHTED_AVERAGE_SCORE|LAST_SCORE_UPDATE_DATE|ENVIRONMENTAL_PILLAR_SCORE|ENVIRONMENTAL_PILLAR_WEIGHT|ENVIRONMENTAL_PILLAR_QUARTILE|GOVERNANCE_PILLAR_SCORE|GOVERNANCE_PILLAR_WEIGHT|GOVERNANCE_PILLAR_QUARTILE|SOCIAL_PILLAR_SCORE|SOCIAL_PILLAR_WEIGHT|SOCIAL_PILLAR_QUARTILE|GICS_SUB_IND|CLIMATE_CHANGE_THEME_SCORE|CLIMATE_CHANGE_THEME_WEIGHT|BUSINESS_ETHICS_THEME_SCORE|CORPORATE_GOV_THEME_SCORE|ENVIRONMENTAL_OPPS_THEME_SCORE|ENVIRONMENTAL_OPPS_THEME_WEIGHT|HUMAN_CAPITAL_THEME_SCORE|HUMAN_CAPITAL_THEME_WEIGHT|NATURAL_RES_USE_THEME_SCORE|NATURAL_RES_USE_THEME_WEIGHT|WASTE_MGMT_THEME_SCORE|WASTE_MGMT_THEME_WEIGHT|PRODUCT_SAFETY_THEME_SCORE|PRODUCT_SAFETY_THEME_WEIGHT|SOCIAL_OPPS_THEME_SCORE|SOCIAL_OPPS_THEME_WEIGHT|STAKEHOLDER_OPPOSIT_THEME_SCORE|STAKEHOLDER_OPPOSIT_THEME_WEIGHT|E_WASTE_SCORE|E_WASTE_WEIGHT|E_WASTE_QUARTILE|FINANCING_ENV_IMP_SCORE|FINANCING_ENV_IMP_QUARTILE|FINANCING_ENV_IMP_WEIGHT|OPPS_CLN_TECH_SCORE|OPPS_CLN_TECH_QUARTILE|OPPS_CLN_TECH_WEIGHT|OPPS_GREEN_BUILDING_SCORE|OPPS_GREEN_BUILDING_QUARTILE|OPPS_GREEN_BUILDING_WEIGHT|OPPS_RENEW_ENERGY_SCORE|OPPS_RENEW_ENERGY_QUARTILE|OPPS_RENEW_ENERGY_WEIGHT|PACK_MAT_WASTE_SCORE|PACK_MAT_WASTE_WEIGHT|PACK_MAT_WASTE_QUARTILE|PROD_CARB_FTPRNT_SCORE|PROD_CARB_FTPRNT_QUARTILE|PROD_CARB_FTPRNT_WEIGHT|RAW_MAT_SRC_SCORE|RAW_MAT_SRC_QUARTILE|RAW_MAT_SRC_WEIGHT|TOXIC_EMISS_WSTE_SCORE|TOXIC_EMISS_WASTE_QUARTILE|TOXIC_EMISS_WSTE_WEIGHT|WATER_STRESS_SCORE|WATER_STRESS_QUARTILE|WATER_STRESS_WEIGHT|CORP_BEHAV_SCORE|CORP_BEHAV_QUARTILE|TAX_TRANSP_SCORE|ACCESS_TO_COMM_SCORE|ACCESS_TO_COMM_QUARTILE|ACCESS_TO_COMM_WEIGHT|ACCESS_TO_FIN_SCORE|ACCESS_TO_FIN_QUARTILE|ACCESS_TO_FIN_WEIGHT|ACCESS_TO_HLTHCRE_SCORE|ACCESS_TO_HLTHCRE_QUARTILE|ACCESS_TO_HLTHCRE_WEIGHT|CHEM_SAFETY_SCORE|CHEM_SAFETY_QUARTILE|CHEM_SAFETY_WEIGHT|COMM_REL_SCORE|COMM_REL_QUARTILE|COMM_REL_WEIGHT|FIN_PROD_SAFETY_SCORE|FIN_PROD_SAFETY_QUARTILE|FIN_PROD_SAFETY_WEIGHT|CONTROV_SRC_SCORE|CONTROV_SRC_QUARTILE|CONTROV_SRC_WEIGHT|HLTH_SAFETY_SCORE|HLTH_SAFETY_QUARTILE|INS_HLTH_DEMO_RISK_WEIGHT|HLTH_SAFETY_WEIGHT|HUMAN_CAPITAL_DEV_SCORE|HUMAN_CAPITAL_DEV_QUARTILE|HUMAN_CAPITAL_DEV_WEIGHT|INS_HLTH_DEMO_RISK_SCORE|INS_HLTH_DEMO_RISK_QUARTILE|LABOR_MGMT_SCORE|LABOR_MGMT_QUARTILE|LABOR_MGMT_WEIGHT|OPPS_NUTRI_HLTH_SCORE|OPPS_NUTRI_HLTH_QUARTILE|OPPS_NUTRI_HLTH_WEIGHT|PRIVACY_DATA_SEC_SCORE|PRIVACY_DATA_SEC_QUARTILE|PRIVACY_DATA_SEC_WEIGHT|PROD_SFTY_QUALITY_SCORE|PROD_SFTY_QUALITY_QUARTILE|PROD_SFTY_QUALITY_WEIGHT|RESPONSIBLE_INVEST_SCORE|RESPONSIBLE_INVEST_QUARTILE|RESPONSIBLE_INVEST_WEIGHT|SUPPLY_CHAIN_LAB_SCORE|SUPPLY_CHAIN_LAB_QUARTILE|SUPPLY_CHAIN_LAB_WEIGHT|ACCOUNTING_SCORE|BOARD_SCORE|CORP_GOVERNANCE_SCORE|CORP_GOVERNANCE_QUARTILE|OWNERSHIP_AND_CONTROL_SCORE|PAY_SCORE|BUS_ETHICS_GOV_PILLAR_SD|BUS_ETHICS_PCTL_GLOBAL|BUS_ETHICS_PCTL_HOME|CORP_BEHAV_ETHICS_SCORE|CORP_BEHAV_GOV_PILLAR_SD|CORP_BEHAV_PCTL_GLOBAL|CORP_BEHAV_PCTL_HOME|TAX_TRANSP_GOV_PILLAR_SD|TAX_TRANSP_PCTL_GLOBAL|TAX_TRANSP_PCTL_HOME|ACCOUNTING_GOV_PILLAR_SD|ACCOUNTING_PCTL_GLOBAL|ACCOUNTING_PCTL_HOME|ASSESSMENT_CHANGE_DATE|BOARD_GOV_PILLAR_SD|BOARD_PCTL_GLOBAL|BOARD_PCTL_HOME|CORP_GOVERNANCE_GOV_PILLAR_SD|GOVERNANCE_PCTL_GLOBAL|GOVERNANCE_PCTL_HOME|OWNERSHIP_GOV_PILLAR_SD|OWNERSHIP_PCTL_GLOBAL|OWNERSHIP_PCTL_HOME|PAY_GOV_PILLAR_SD|PAY_PCTL_GLOBAL|PAY_PCTL_HOME|ESG_HEADLINE|IVA_RATING_ANALYSIS ',
        @sList2 VARCHAR(8000) = 'IVA_COMPANY_RATING,IVA_RATING_DATE,IVA_INDUSTRY,IVA_PREVIOUS_RATING,IVA_RATING_TREND,INDUSTRY_ADJUSTED_SCORE,WEIGHTED_AVERAGE_SCORE,LAST_SCORE_UPDATE_DATE,ENVIRONMENTAL_PILLAR_SCORE,ENVIRONMENTAL_PILLAR_WEIGHT,ENVIRONMENTAL_PILLAR_QUARTILE,GOVERNANCE_PILLAR_SCORE,GOVERNANCE_PILLAR_WEIGHT,GOVERNANCE_PILLAR_QUARTILE,SOCIAL_PILLAR_SCORE,SOCIAL_PILLAR_WEIGHT,SOCIAL_PILLAR_QUARTILE,GICS_SUB_IND,CLIMATE_CHANGE_THEME_SCORE,CLIMATE_CHANGE_THEME_WEIGHT,BUSINESS_ETHICS_THEME_SCORE,CORPORATE_GOV_THEME_SCORE,ENVIRONMENTAL_OPPS_THEME_SCORE,ENVIRONMENTAL_OPPS_THEME_WEIGHT,HUMAN_CAPITAL_THEME_SCORE,HUMAN_CAPITAL_THEME_WEIGHT,NATURAL_RES_USE_THEME_SCORE,NATURAL_RES_USE_THEME_WEIGHT,WASTE_MGMT_THEME_SCORE,WASTE_MGMT_THEME_WEIGHT,PRODUCT_SAFETY_THEME_SCORE,PRODUCT_SAFETY_THEME_WEIGHT,SOCIAL_OPPS_THEME_SCORE,SOCIAL_OPPS_THEME_WEIGHT,STAKEHOLDER_OPPOSIT_THEME_SCORE,STAKEHOLDER_OPPOSIT_THEME_WEIGHT,E_WASTE_SCORE,E_WASTE_WEIGHT,E_WASTE_QUARTILE,FINANCING_ENV_IMP_SCORE,FINANCING_ENV_IMP_QUARTILE,FINANCING_ENV_IMP_WEIGHT,OPPS_CLN_TECH_SCORE,OPPS_CLN_TECH_QUARTILE,OPPS_CLN_TECH_WEIGHT,OPPS_GREEN_BUILDING_SCORE,OPPS_GREEN_BUILDING_QUARTILE,OPPS_GREEN_BUILDING_WEIGHT,OPPS_RENEW_ENERGY_SCORE,OPPS_RENEW_ENERGY_QUARTILE,OPPS_RENEW_ENERGY_WEIGHT,PACK_MAT_WASTE_SCORE,PACK_MAT_WASTE_WEIGHT,PACK_MAT_WASTE_QUARTILE,PROD_CARB_FTPRNT_SCORE,PROD_CARB_FTPRNT_QUARTILE,PROD_CARB_FTPRNT_WEIGHT,RAW_MAT_SRC_SCORE,RAW_MAT_SRC_QUARTILE,RAW_MAT_SRC_WEIGHT,TOXIC_EMISS_WSTE_SCORE,TOXIC_EMISS_WASTE_QUARTILE,TOXIC_EMISS_WSTE_WEIGHT,WATER_STRESS_SCORE,WATER_STRESS_QUARTILE,WATER_STRESS_WEIGHT,CORP_BEHAV_SCORE,CORP_BEHAV_QUARTILE,TAX_TRANSP_SCORE,ACCESS_TO_COMM_SCORE,ACCESS_TO_COMM_QUARTILE,ACCESS_TO_COMM_WEIGHT,ACCESS_TO_FIN_SCORE,ACCESS_TO_FIN_QUARTILE,ACCESS_TO_FIN_WEIGHT,ACCESS_TO_HLTHCRE_SCORE,ACCESS_TO_HLTHCRE_QUARTILE,ACCESS_TO_HLTHCRE_WEIGHT,CHEM_SAFETY_SCORE,CHEM_SAFETY_QUARTILE,CHEM_SAFETY_WEIGHT,COMM_REL_SCORE,COMM_REL_QUARTILE,COMM_REL_WEIGHT,FIN_PROD_SAFETY_SCORE,FIN_PROD_SAFETY_QUARTILE,FIN_PROD_SAFETY_WEIGHT,CONTROV_SRC_SCORE,CONTROV_SRC_QUARTILE,CONTROV_SRC_WEIGHT,HLTH_SAFETY_SCORE,HLTH_SAFETY_QUARTILE,INS_HLTH_DEMO_RISK_WEIGHT,HLTH_SAFETY_WEIGHT,HUMAN_CAPITAL_DEV_SCORE,HUMAN_CAPITAL_DEV_QUARTILE,HUMAN_CAPITAL_DEV_WEIGHT,INS_HLTH_DEMO_RISK_SCORE,INS_HLTH_DEMO_RISK_QUARTILE,LABOR_MGMT_SCORE,LABOR_MGMT_QUARTILE,LABOR_MGMT_WEIGHT,OPPS_NUTRI_HLTH_SCORE,OPPS_NUTRI_HLTH_QUARTILE,OPPS_NUTRI_HLTH_WEIGHT,PRIVACY_DATA_SEC_SCORE,PRIVACY_DATA_SEC_QUARTILE,PRIVACY_DATA_SEC_WEIGHT,PROD_SFTY_QUALITY_SCORE,PROD_SFTY_QUALITY_QUARTILE,PROD_SFTY_QUALITY_WEIGHT,RESPONSIBLE_INVEST_SCORE,RESPONSIBLE_INVEST_QUARTILE,RESPONSIBLE_INVEST_WEIGHT,SUPPLY_CHAIN_LAB_SCORE,SUPPLY_CHAIN_LAB_QUARTILE,SUPPLY_CHAIN_LAB_WEIGHT,ACCOUNTING_SCORE,BOARD_SCORE,CORP_GOVERNANCE_SCORE,CORP_GOVERNANCE_QUARTILE,OWNERSHIP_AND_CONTROL_SCORE,PAY_SCORE,BUS_ETHICS_GOV_PILLAR_SD,BUS_ETHICS_PCTL_GLOBAL,BUS_ETHICS_PCTL_HOME,CORP_BEHAV_ETHICS_SCORE,CORP_BEHAV_GOV_PILLAR_SD,CORP_BEHAV_PCTL_GLOBAL,CORP_BEHAV_PCTL_HOME,TAX_TRANSP_GOV_PILLAR_SD,TAX_TRANSP_PCTL_GLOBAL,TAX_TRANSP_PCTL_HOME,ACCOUNTING_GOV_PILLAR_SD,ACCOUNTING_PCTL_GLOBAL,ACCOUNTING_PCTL_HOME,ASSESSMENT_CHANGE_DATE,BOARD_GOV_PILLAR_SD,BOARD_PCTL_GLOBAL,BOARD_PCTL_HOME,CORP_GOVERNANCE_GOV_PILLAR_SD,GOVERNANCE_PCTL_GLOBAL,GOVERNANCE_PCTL_HOME,OWNERSHIP_GOV_PILLAR_SD,OWNERSHIP_PCTL_GLOBAL,OWNERSHIP_PCTL_HOME,PAY_GOV_PILLAR_SD,PAY_PCTL_GLOBAL,PAY_PCTL_HOME,ESG_HEADLINE,IVA_RATING_ANALYSIS ,BIODIV_LAND_USE_SCORE,BIODIV_LAND_USE_WEIGHT,CARBON_EMISSIONS_SCORE,CARBON_EMISSIONS_WEIGHT,INS_CLIMATE_CHG_RISK_SCORE,INS_CLIMATE_CHG_RISK_WEIGHT,ESG_OVERALL_QUARTILE,BIODIV_LAND_USE_QUARTILE,CARBON_EMISSIONS_QUARTILE,INS_CLIMATE_CHG_RISK_QUARTILE',
        @sDelimiter1 CHAR(1) = '|',
        @sDelimiter2 CHAR(1) = ',',
        @sSplit8KSQL NVARCHAR(MAX),
        @sParams NVARCHAR(100) = N'@sList VARCHAR(8000), @sDelimiter CHAR(1)';

IF OBJECT_ID('tempdb.dbo.#CSV_List_1', 'U') IS NOT NULL DROP TABLE #CSV_List_1;
IF OBJECT_ID('tempdb.dbo.#CSV_List_2', 'U') IS NOT NULL DROP TABLE #CSV_List_2;

CREATE TABLE #CSV_List_1
(
 MemberPosition_1 INT NOT NULL,
 MemberValue_1    VARCHAR(8000) NULL
);

CREATE TABLE #CSV_List_2
(
 MemberPosition_2 INT NOT NULL,
 MemberValue_2    VARCHAR(8000) NULL
);

SET @sSplit8KSQL = N'
 ;WITH E1(N) AS (
                 SELECT 1 UNION ALL
                 SELECT 1 UNION ALL
                 SELECT 1 UNION ALL
                 SELECT 1 UNION ALL
                 SELECT 1 UNION ALL
                 SELECT 1 UNION ALL
                 SELECT 1 UNION ALL
                 SELECT 1 UNION ALL
                 SELECT 1 UNION ALL
                 SELECT 1
                ),
       E2(N) AS (SELECT 1 FROM E1 a, E1 b),
       E4(N) AS (SELECT 1 FROM E2 a, E2 b),
 cteTally(N) AS (SELECT TOP (ISNULL(DATALENGTH(@sList),0)) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM E4),
cteStart(N1) AS (
                 SELECT 1
                  UNION ALL
                 SELECT t.N+1 FROM cteTally t WHERE SUBSTRING(@sList,t.N,1) = @sDelimiter
                ),
cteLen(N1,L1) AS(
                 SELECT s.N1,
                        ISNULL(NULLIF(CHARINDEX(@sDelimiter,@sList,s.N1),0)-s.N1,8000)
                   FROM cteStart s
                )
SELECT MemberPosition = ROW_NUMBER() OVER(ORDER BY N1),
       MemberValue = SUBSTRING(@sList, N1, L1)
  FROM cteLen;';

INSERT INTO #CSV_List_1
(MemberPosition_1, MemberValue_1)
EXEC sp_executesql @sSplit8KSQL, @sParams, @sList = @sList1, @sDelimiter = @sDelimiter1;

INSERT INTO #CSV_List_2
(MemberPosition_2, MemberValue_2)
EXEC sp_executesql @sSplit8KSQL, @sParams, @sList = @sList2, @sDelimiter = @sDelimiter2;

SELECT *
  FROM #CSV_List_1 AS L1
       FULL JOIN #CSV_List_2 AS L2 ON TRIM(UPPER(L1.MemberValue_1)) = TRIM(UPPER(L2.MemberValue_2))
 WHERE 1 = 1
   AND (L1.MemberValue_1 IS NULL OR L2.MemberValue_2 IS NULL)
 ORDER BY L1.MemberPosition_1, L2.MemberPosition_2;