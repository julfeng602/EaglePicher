/*******************************************************************************
 * COPYRIGHT 2021 EAGLE PICHER                                                 *
 *******************************************************************************
 * Created By:      Jonathan Ulfeng                                            *
 * Date Created:    2/11/2021                                                   *
 * Description:     Checks Export Status for Customer Order                    *
 *                                                                             *
 *                                                                             *
 * Modification:                                                               *
 *     2/3/2021   J Ulfeng - Initial creation                                  *
 *                                                                             *
 ******************************************************************************/



column db new_value db noprint
select lower(name) as "db" from v$database;
SPOOL ../../logs/ExportControlCustomerOrderExport_&db..log
SELECT '&db' DBINSTANCE,
        USER oracle_user,
        sys_context('userenv','os_user') AS OS_USER,
        sys_context('userenv','host')    AS USER_HOST,
        TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') RUN_ON,
        DBTIMEZONE
   FROM DUAL;


DECLARE
cnt_rep NUMBER;

objid_ quick_report.objid % type;
info_ VARCHAR2(32000);
attr_ VARCHAR2(32000);
objversion_ quick_report.objversion%type;
action_ varchar2(5) := 'DO';
report_name_ varchar2(100) :='Export Control - Customer Orders';

BEGIN

	Select count(*) into cnt_rep from quick_report_tab where description = report_name_;

	IF cnt_rep > 0 THEN
		Client_Sys.Clear_Attr(attr_);
		Select objid, objversion into objid_, objversion_ from quick_report where description = report_name_;


		QUICK_REPORT_API.Remove__(info_, objid_, objversion_, action_);
		commit;
	END IF;
END;
/

column sql_s new_value mysql noprint

select
'select  '
|| 'o.order_no ""' || ' Order No ' || '"" , '
|| 'o.customer_no ""' || ' Customer No ' || '""  , '
|| 'IFSAPP.Customer_Info_Address_API.Get_Name(ai.CUSTOMER_NO,ai.BILL_ADDR_NO) ""' || ' Customer Name ' || '"" , '
|| 'o.customer_po_no ""' || ' Customer PO No ' || '"" , '
|| 'to_char(o.wanted_delivery_date, ''''MM/dd/YYYY'''') ""' || ' Wanted Delivery Date ' || '"" , '
|| 'o.currency_code ""' || ' Currency Code ' || '"" , '
|| 'o.state ""' || ' Order Status ' || '"" , '
|| 'ai.address1 || '''' '''' || ai.address2 || '''' '''' || ai.city || '''', '''' || ''''  '''' || ai.state || ''''  '''' || ai.zip_code || '''' '''' || ai.country_code  ""' || ' Address ' || '"" , '
|| '(select sum(l.buy_qty_due) from customer_order_line l where l.order_no = o.order_no) ""' || ' Total Units ' || '"" , '
|| '(select sum(l.buy_qty_due * l.unit_price_incl_tax) from customer_order_line l where l.order_no = o.order_no) ""' || ' Total Amount ' || '"" , '
|| 'l.line_no ""' || ' Line No ' || '"" , '
|| 'l.catalog_no ""' || ' Catalog No ' || '"" , '
|| 'l.catalog_desc ""' || ' Catalog Desc ' || '"" , '
|| 'l.buy_qty_due ""' || ' Price Qty ' || '"" , '
|| '(l.buy_qty_due * l.sale_unit_price ) ""' || ' Total Net Amount ' || '"" , '
|| 'IFSAPP.EP_Export_Shipment_Check.GetExportControlled(l.part_no) ""' || ' Export Controlled Part ' || '"" , '
|| 'IFSAPP.EP_Export_Shipment_Check.GetLicenseNo(l.order_no, l.line_no, l.rel_no, l.line_item_no, l.part_no, l.buy_qty_due,  o.customer_no) ""' || ' License No ' || '"" ,  '
|| 'IFSAPP.EP_Export_Shipment_Check.GetLicenseConn(l.order_no, l.line_no, l.rel_no, l.line_item_no, l.part_no, l.buy_qty_due, o.customer_no) ""' || ' License Status/Connected ' || '""  '
|| 'from  '
|| 'ifsapp.customer_order_cfv o '
|| 'left outer join ifsapp.customer_order_line l '
|| 'ON l.order_no = o.order_no and l.catalog_type_db = ''''INV'''' '
|| 'left outer join ifsapp.CUST_ORD_ADDRESS_2_UIV ai '
|| 'on ai.order_no = o.order_no '
|| 'where '
|| '  o.order_no  LIKE ( '''''||chr(38)||'OrderNo'||chr(37)||''''' ) '
|| 'order by  '
|| 'o.order_no, l.line_no, l.rel_no, l.line_item_no '
as sql_s
from dual;

@H:\Utilities\Quick_Report_Create  'Export Control' 'Export Control - Customer Orders' "&mysql" 'IFSAPP' 'Export Check Customer Order p: OrderNo'
/
show errors
SPOOL OFF