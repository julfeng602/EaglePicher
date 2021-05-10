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

    function Update_Point_Value(part_no_ in varchar2,
                                serial_no_ in varchar2,
                                operation_no_ in int,
                                data_point_ in int,
                                result_ in int,
                                accuracy_ in int) return varchar2;                           

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
                           operation_no_ in int,
                           data_point_ in int) RETURN int
    as
        analysis_no_ int;
    begin
        BEGIN
            SELECT max(analysis_no) INTO analysis_no_ FROM QMAN_ANALYSIS_VA1342390886_CFV an
                where
                    an.analysis_state = 'Planned' and
                    an.part_no = part_no_ AND
                    an.test_operation_no = operation_no_; --and
                   -- an.data_point = data_point_;
                    /*
           if (serial_no_ is null) then
            SELECT max(analysis_no) INTO analysis_no_ FROM QMAN_ANALYSIS_VA1342390886_CFV an
                where
                    an.analysis_state = 'Planned' and
                    an.part_no = part_no_ AND
                    an.serial_no is null and
                    an.test_operation_no = operation_no_;
           else
            SELECT max(analysis_no) INTO analysis_no_ FROM QMAN_ANALYSIS_VA1342390886_CFV an
                where
                    an.analysis_state = 'Planned' and
                    an.part_no = part_no_ AND
                    an.serial_no = serial_no_ and
                    an.test_operation_no = operation_no_;
            end if;    
            */
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN	
            analysis_no_ := -1;                  
        END;
        return analysis_no_;  
    end Get_Analysis_No;

    function Update_Point_Value(part_no_ in varchar2,
                                serial_no_ in varchar2,
                                operation_no_ in int,
                                data_point_ in int,
                                result_ in int,
                                accuracy_ in int) return varchar2
    is
        analysis_no_ int; 
        info_ varchar2(1000) := '';
        serial_no_new_ varchar2(200) := null;
        report_attr_ varchar2(10000);
        objid_         QMAN_SAMPLE_VALUE.objid%TYPE;
        objversion_    QMAN_SAMPLE_VALUE.objversion%TYPE;    
    begin
        if(Length(serial_no_) > 0)  then
            serial_no_new_ := serial_no_;
        else
            serial_no_new_ := null;
        end if;
        analysis_no_ := Get_Analysis_No(part_no_, serial_no_new_, operation_no_, data_point_);
        if(analysis_no_ = -1) then
          info_ := 'Analysis not found';
          return info_;
        end if;
        Select ObjID into objid_ from qman_sample_value where analysis_no = analysis_no_ and data_point = data_point_ AND and result_no = (select max(result_no) from qman_sample_value where analysis_no = analysis_no_ and data_point = data_point_) ;
        select objversion into objversion_ from qman_sample_value where analysis_no = analysis_no_ and data_point = data_point_  and result_no = (select max(result_no) from qman_sample_value where analysis_no = analysis_no_ and data_point = data_point_) ;
        if ((objid_ IS NULL)  OR (objversion_ is null)) then
            info_ := 'Data Point Not found for point: ' || data_point_;
            return info_;
        end if;
        client_sys.Add_To_Attr('RESULT', result_, report_attr_);
        client_sys.Add_To_Attr('ACCURACY', accuracy_ ,report_attr_);
        if(Length(serial_no_) > 0)  then
            client_sys.Add_To_Attr('SERIAL_NO', serial_no_ ,report_attr_);
        END IF;
        dbms_output.put_line('report_attr: ' || report_attr_);
        BEGIN
            SAVEPOINT do_insert;
            dbms_output.put_line('info_: ' || info_);
            QMAN_SAMPLE_VALUE_API.MODIFY__(info_, objid_,
                objversion_, report_attr_, 'DO');
            if ((info_ is null) or (length(info_) = 0)) then
              info_ := 'Success updating point: ' || data_point_  || ' with value: ' || result_;
            end if;
            commit;
        EXCEPTION 
        WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE (SQLERRM);
            info_ := info_ + '...Error: ' ||SQLERRM;
            rollback to do_insert; 
             
        END;
        return info_;
    end Update_Point_Value;
END &PKG;
/

COMMIT
/
SHOW ERROR

spool off