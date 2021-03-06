SET SERVEROUTPUT ON SIZE 100000;
SET ECHO ON;
SET LINES 100;
SET PAGES 999;

column db new_value db noprint
SELECT LOWER(name) AS "db"
  FROM v$database;
  
column runtime new_value runtime noprint  
SELECT  to_char(sysdate, 'mmddyyyyhhmmss') as "runtime" from dual;  
  

spool ../logs/ExportShipmentCheck_&db._&runtime..log

-- Audit relevant information 
 SELECT '&db' DBINSTANCE,
        USER oracle_user,
        sys_context('userenv','os_user') AS OS_USER,
        sys_context('userenv','host')    AS USER_HOST,
        TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') RUN_ON, 
        DBTIMEZONE
   FROM DUAL;

-----------------------------------------------------------------------------
--
--  Logical unit: Analysis
--
--  File:         QC_QMAN_Package.sql
--
--  Date    Sign    History
--  ------  ------  ------------------------------------------------------------
--  210305  JoUlUS  Initial Create Package for Quality Assurance Input.

DEFINE MODULE             = QUAMAN
DEFINE LU                 = Analysis
DEFINE PKG                = EP_QC_QMAN_Analysis

-----------------------------------------------------------------------------
-- PACKAGE SPECIFICATION:     EP_QC_QMAN_Analysis
-----------------------------------------------------------------------------

PROMPT Creating &PKG specification

CREATE OR REPLACE PACKAGE &PKG AS

    module_ CONSTANT VARCHAR2(6)   := '&MODULE';
    lu_name_ CONSTANT VARCHAR2(25) := '&LU';

	function Get_Analysis_No(part_no_ in varchar2,
                           serial_no_ in varchar2,
                           operation_no_ int) RETURN int;

END &PKG;
/
SHOW ERROR

-----------------------------------------------------------------------------
-- PACKAGE IMPLEMENTATION     PURCHASE_ORDER_RPI
-----------------------------------------------------------------------------

PROMPT Creating &PKG implementation

CREATE OR REPLACE PACKAGE BODY &PKG AS

----------------------------------------------------------------------------
--------------------- GLOBAL DECLARATIONS -----------------------------------
-----------------------------------------------------------------------------
    function Get_Analysis_No(part_no_ in varchar2,
                           serial_no_ in varchar2,
                           operation_no_ int) RETURN int
    as
        analysis_no_ int;
    begin
        BEGIN
            SELECT max(analysis_no) INTO analysis_no_ FROM QMAN_ANALYSIS_VA1342390886_CFV an
                where
                    an.analysis_state = 'Planned' and
                    an.part_no = part_no_ AND
                    an.serial_no = coalesce(serial_no_, '*') and
                    an.test_operation_no = operation_no_;
                    
   
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN	
            analysis_no_ := -1;                  
        END;
        return analysis_no_;  
    end;

END &PKG;
/

COMMIT
/
SHOW ERROR

spool off