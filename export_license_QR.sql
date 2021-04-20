/*******************************************************************************
 * COPYRIGHT 2021 EAGLE PICHER                                                 *
 *******************************************************************************
 * Created By:      Jonathan Ulfeng                                            *
 * Date Created:    2/5/2021                                                   *
 * Description:     Checks Export Status for Customer Order                    *
 *                                                                             *
 *                                                                             *
 * Modification:                                                               *
 *     2/5/2021   J Ulfeng - Initial creation                                  *
 *                                                                             *
 ******************************************************************************/



column db new_value db noprint
select lower(name) as "db" from v$database;
SPOOL ../../logs/ExportLicenseStatus_&db..log
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
report_name_ varchar2(100) :='Export License Status';

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
'SELECT '
|| 'lc.export_license_id ""' || ' License ID ' || '"" , '
|| 'l.license_number  ""' || ' License No' || '"" , '
|| 'l.description ""' || ' Description ' || '"" , '
|| 'l.authority_license_no  ""' || ' Authority License No ' || '"" , '
|| 'l.issuing_authority ""' || ' Issuing Authority ' || '"" , '
|| 'l.state  ""' || ' License Status ' || '"" , '
|| 'to_char(l.issued_date, ''''MM/dd/YYYY'''') ""' || ' Issue Date ' || '"" , '
|| 'to_char(l.effective_from, ''''MM/dd/YYYY'''') ""' || ' Effective From  ' || '"" , '
|| 'to_char(l.expires, ''''MM/dd/YYYY'''') ""' || ' Expires ' || '"" , ' 
|| 'lc.qty_licensed ""' || ' Qty Licensed ' || '"" , '
|| 'lc.part_no ""' || ' Part No ' || '"" , '
|| 'lc.amt_licensed ""' || ' Amount Licensed ' || '"" , '
|| 'lc.qty_shipped ""' || ' Qty Shipped ' || '"" , '
|| 'lc.amt_shipped ""' || ' Amount Shipped' || '""  '
|| ' FROM '
|| ' ifsapp.export_license l '
|| ' LEFT OUTER JOIN ifsapp.export_license_coverage  lc ON lc.export_license_id = l.export_license_id '
|| 'where '
|| '  UPPER(lc.part_no)  LIKE ( UPPER('''''||chr(38)||'PartNo'||chr(37)||''''' )) '
|| 'order by  '
|| 'lc.part_no, l.effective_from desc '
as sql_s
from dual;

@Quick_Report_Create  'EXPORT CONTROL' 'Export License Status' "&mysql" 'IFSAPP' 'Export License p: PartNo'
/
show errors
SPOOL OFF