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
--  Logical unit: ExportShipmentCheck
--
--  File:         ExportShipmentCheck.sql
--
--  Date    Sign    History
--  ------  ------  ------------------------------------------------------------
--  201014  JoUlUS  Initial Create Package for Export License.

DEFINE MODULE             = EXPCTR
DEFINE LU                 = ExportShipmentCheck
DEFINE PKG                = EP_Export_Shipment_Check

-----------------------------------------------------------------------------
-- PACKAGE SPECIFICATION:     PURCHASE_ORDER_RPI
-----------------------------------------------------------------------------

PROMPT Creating &PKG specification

CREATE OR REPLACE PACKAGE &PKG AS

    module_ CONSTANT VARCHAR2(6)   := '&MODULE';
    lu_name_ CONSTANT VARCHAR2(25) := '&LU';

	function ExportCheckOk(shipment_id_ in int) RETURN int;
    function ExportMessage(shipment_id_ in int) RETURN varchar2;
    function GetLicenseNo(order_no_ in varchar2,
                          order_ref2_ in varchar2,
                          order_ref3_ in varchar2,
                          order_ref4_ in varchar2,
                          part_no_ in varchar2,
                          customer_id_ in varchar2) RETURN varchar2;
    function GetLicenseConn(order_no_ in varchar2,
                          order_ref2_ in varchar2,
                          order_ref3_ in varchar2,
                          order_ref4_ in varchar2,
                          part_no_ in varchar2,
                          customer_id_ in varchar2) RETURN varchar2;
    function GetExportControlled(part_no_ in varchar2) return varchar2;
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
    function IsExportControlled(part_no_ in varchar2) return boolean
    as
        export_controlled_ INT := 0;
    begin
        BEGIN
            SELECT 1 INTO export_controlled_ FROM PARTCA_EXPORT_CONTROL ec
                where
                    ec.part_no = part_no_ AND
                    ec.export_controlled in ('Yes', 'Not Decided', 'Denied Party Only');
                    
   
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN	
            export_controlled_ := 0;                  
        END;
        if(export_controlled_ = 1) then
            return true;
        else
            return false;
        end if;

    end IsExportControlled;
    
    procedure GetCustomerCountryInfo(order_no_ in NVARCHAR2, customer_no_ out nvarchar2, ship_addr_no_ out nvarchar2, country_code_ out nvarchar2)
    is
    begin
        BEGIN
            select customer_no, 
                   ship_addr_no, 
                   Cust_Ord_Customer_Address_API.Get_Country_Code(CUSTOMER_NO,SHIP_ADDR_NO)
            into customer_no_,
                 ship_addr_no_, 
                 country_code_
            from 
            customer_order
            where order_no = order_no_;--shipment_line_.order_no;
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN	
            customer_no_ := 0;
            ship_addr_no_ := 0;
            country_code_ := '';
        END;    
    end GetCustomerCountryInfo;
    
    procedure LicenseInfo(
                          order_no_ in varchar2,
                          order_ref2_ in varchar2,
                          order_ref3_ in varchar2,
                          order_ref4_ in varchar2,
                          part_no_ in varchar2,
                          customer_id_ in varchar2, 
                          license_no_ out varchar2,
                          license_connected_ out varchar2)
    is
    begin
        BEGIN
            license_no_ := NULL;
            license_connected_ := NULL;
                select 
                Export_License_Api.Get_License_Number(d.export_license_id) license_no,
                d.license_connected
                into license_no_, license_connected_
                from EXP_LICENSE_CONNECT_HEAD h
                JOIN EXP_LICENSE_CONNECT_DETAIL d
                on d.EXP_LICENSE_CONNECT_ID = h.EXP_LICENSE_CONNECT_ID
                join export_license l
                on l.export_license_id = d.export_license_id
                where 
                h.ORDER_REF1 = order_no_
                and h.ORDER_REF2 = order_ref2_
                and h.ORDER_REF3 = order_ref3_
                and h.ORDER_REF4 = order_ref4_
                and h.PART_NO = part_no_
                AND h.END_USER_CUSTOMER_ID = customer_id_
                AND sysdate between l.effective_from and l.expires
                 order by d.license_connected desc fetch first 1 rows only;
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN	
            license_no_ := NULL;
            license_connected_ := NULL;
        END;          
    end;
    
    function ExportCheckOk (shipment_id_ in int) RETURN int
	IS 
	  --customer_id customer_info.customer_id%type := '';
      export_controlled_ boolean := false;
      customer_no_ customer_order_tab.customer_no%type;
      ship_addr_no_ customer_order_tab.ship_addr_no%type;
      country_code_ customer_info_address_tab.country%type;
      license_no_ export_license_tab.license_number%TYPE;
      license_connected_ EXP_LICENSE_CONNECT_DETAIL.LICENSE_CONNECTED%TYPE;
      retVal int := 1;
      CURSOR get_shipment_lines IS
        select  
            s.shipment_id,
            s.RECEIVER_ID AS CUSTOMER_NO,
            s.RECEIVER_ADDR_ID,
            s.CONTRACT,
            s.SOURCE_REF1 AS ORDER_NO,
            l.shipment_line_no,
            l.source_ref2,
            l.source_ref3,
            l.source_ref4,
            l.source_part_no as part_no
        from shipment s 
        left outer join shipment_line l
        on l.shipment_id = s.shipment_id
        where  s.shipment_id = shipment_id_ and  s.receiver_type_db = 'CUSTOMER'
        order by l.shipment_line_no;
	BEGIN
     FOR shipment_line_ IN get_shipment_lines LOOP
        export_controlled_ := IsExportControlled(shipment_line_.part_no);
        if(export_controlled_ = true) then
            GetCustomerCountryInfo(shipment_line_.order_no, customer_no_, ship_addr_no_, country_code_);    
            dbms_output.put_line('CustomerCountryInfo: ' || customer_no_ || ', ' || ship_addr_no_ || ', ' || country_code_);
            if(country_code_ != 'US') then --check for a valid license
                LicenseInfo(shipment_line_.order_no,
                            shipment_line_.source_ref2,
                            shipment_line_.source_ref3,
                            shipment_line_.source_ref4,
                            shipment_line_.part_no,
                            customer_no_,
                            license_no_,
                            license_connected_);
                dbms_output.put_line('License: ' || license_no_ || ', ' || license_connected_ );
                if (license_no_ is null or (license_no_ is not null and license_connected_ = 'False')) THEN
                   
                    retVal := 0;
                end if;
                 --Client_SYS.Add_Warning('CustomerOrderReservation', 'Invalid Licese');
                  --raise_application_error(-20001, 'Export License not Found');
            end if;
        end if;
        EXIT WHEN retVal  = 0;
      
      END LOOP;
      
        if (retVal = 1) THEN
            dbms_output.put_line('EXPORT_CONTROLLED: TRUE');
        ELSE
            dbms_output.put_line('EXPORT_CONTROLLED: FALSE');
        END IF;       
      Return retVal;
	END ExportCheckOk;
    function ExportMessage (shipment_id_ in int) RETURN varchar2
	IS 
    retVal varchar2(4000);
    BEGIN
        IF (ExportCheckOk(shipment_id_) = 0) then
            retVal := 'Shipment is not allowed due to customer order line(s) not linked to Export License.';
        else
            retVal := 'Shipment is allowed for export or is a US based shipment.';
        end if;
        return retVal;
    END ExportMessage;

    /* Functions used in Reporting (Quick Reports) */
    function GetLicenseNo(order_no_ in varchar2,
                          order_ref2_ in varchar2,
                          order_ref3_ in varchar2,
                          order_ref4_ in varchar2,
                          part_no_ in varchar2,
                          customer_id_ in varchar2) RETURN varchar2
    IS
      retVal export_license_tab.license_number%type;
    BEGIN
        retVal := null;
            BEGIN
                select 
                Export_License_Api.Get_License_Number(d.export_license_id)
                into retVal
                from EXP_LICENSE_CONNECT_HEAD h
                JOIN EXP_LICENSE_CONNECT_DETAIL d
                on d.EXP_LICENSE_CONNECT_ID = h.EXP_LICENSE_CONNECT_ID
                join export_license l
                on l.export_license_id = d.export_license_id
                where 
                h.ORDER_REF1 = order_no_
                and h.ORDER_REF2 = order_ref2_
                and h.ORDER_REF3 = order_ref3_
                and h.ORDER_REF4 = order_ref4_
                and h.PART_NO = part_no_
                AND h.END_USER_CUSTOMER_ID = customer_id_
                AND sysdate between l.effective_from and l.expires 
                order by d.license_connected desc fetch first 1 rows only;
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN	
            retVal := NULL;
        END; 
        return retVal;
    END GetLicenseNo;
    
    function GetLicenseConn(order_no_ in varchar2,
                          order_ref2_ in varchar2,
                          order_ref3_ in varchar2,
                          order_ref4_ in varchar2,
                          part_no_ in varchar2,
                          customer_id_ in varchar2) RETURN varchar2
    IS
      retVal EXP_LICENSE_CONNECT_DETAIL.license_connected%type;
    BEGIN
        retVal := null;
            BEGIN
                select 
                d.license_connected
                into retVal
                from EXP_LICENSE_CONNECT_HEAD h
                JOIN EXP_LICENSE_CONNECT_DETAIL d
                on d.EXP_LICENSE_CONNECT_ID = h.EXP_LICENSE_CONNECT_ID
                join export_license l
                on l.export_license_id = d.export_license_id
                where 
                h.ORDER_REF1 = order_no_
                and h.ORDER_REF2 = order_ref2_
                and h.ORDER_REF3 = order_ref3_
                and h.ORDER_REF4 = order_ref4_
                and h.PART_NO = part_no_
                AND h.END_USER_CUSTOMER_ID = customer_id_
                AND sysdate between l.effective_from and l.expires 
                order by d.license_connected desc -- returnes true value first
                fetch first 1 rows only;
        EXCEPTION 
          WHEN NO_DATA_FOUND THEN	
            retVal := NULL;
        END; 
        return retVal;
    END GetLicenseConn; 

    function GetExportControlled(part_no_ in varchar2) return varchar2
    is
        retVal varchar2(5);
    BEGIN
        IF (IsExportControlled(part_no_) = true) then
            retVal := 'True';
        ELSE
            retVal := 'False';
        END IF;
        return retVal;
        
    END GetExportControlled;
END &PKG;
/

COMMIT
/
SHOW ERROR

spool off