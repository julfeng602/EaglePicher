/************************************************************************ 
** CQ 37553 - IFS APPS 7.5 Upgrade
** Input Parameteres:
** 1. Report Category
** 2. Report Description
** 3. Report SQL
** 4. Comma separated list of IFS roles
** 5. Report comments
**  Rev     Date        Author         Description
** -----------------------------------------------------------------------------
**  -     2010/06/03  Igor Knelev    Created to install any quick report by passing 
**                                   report category, report description and SQL expression 
**                                   as a parameter       
**  A     2011/03/11  Igor Knelev    Add functionality to accept IFS roles as a comma separated                       
**                                   string. CQ63967      
**  B     2011/08/17  John Peet      Fix table build index
**
**  C     2018/03/12  Nicole Dennler Uplifted for GDMS IFS 9 per RFC 33115.  Removed IFSAPP. added new code for sql statement 
** -----------------------------------------------------------------------------
/************************************************************************/

SET FEEDBACK OFF

col 1 new_value 1 
col 2 new_value 2 
col 3 new_value 3 
col 4 new_value 4 
col 5 new_value 5 
 
select null "1",null "2",null "3",null "4",null "5"
from dual where rownum=0;

SET FEEDBACK ON

prompt 1=&1
prompt 2=&2
prompt 3=&3
prompt 4=&4
prompt 5=&5

DECLARE
info_        VARCHAR2(32000) := NULL;
objid_       VARCHAR2(2000) := NULL;
objversion_  VARCHAR2(2000) := NULL;
attr_        VARCHAR2(32000) := NULL;
action_      VARCHAR2(20) := NULL;
category_       report_category_tab.description%type;
rprt_desc_      quick_report_tab.description%type;
sql_expression_ quick_report_tab.sql_expression%type;
newrecid_       QUICK_REPORT_TAB.QUICK_REPORT_ID%TYPE;
--CQ63967
TYPE split_tbl is TABLE OF VARCHAR2(32767)index by binary_integer;
roles_tbl_ split_tbl;
comments_ varchar2(2000);
i binary_integer;
--

rowid_ VARCHAR2(2000);  -- RFC 33115


cursor get_sec_objects(rep_id_ QUICK_REPORT_TAB.QUICK_REPORT_ID%TYPE) is
select OBJID, OBJVERSION, PO_ID, SEC_OBJECT, SEC_OBJECT_TYPE, PRES_OBJECT_SEC_SUB_TYPE, INFO_TYPE 
from PRES_OBJECT_SECURITY where PO_ID = 'repQUICK_REPORT'||rep_id_ 
order by SEC_OBJECT_TYPE DESC, SEC_OBJECT;
--CQ63967
FUNCTION f_split (
    p_list VARCHAR2,
    p_del VARCHAR2 := ','
) RETURN split_tbl
IS
    l_idx    binary_INTEGER;
    l_list    VARCHAR2(32767) := p_list;
    l_value VARCHAR2(32767);
    result_tbl_ split_tbl;
    l_tbl_idx binary_INTEGER := 1;
BEGIN
    dbms_output.put_line('fsplit begin');
    LOOP
        l_idx := INSTR(l_list,p_del);
        IF l_idx > 0 THEN
            result_tbl_(l_tbl_idx) := LTRIM(RTRIM(SUBSTR(l_list,1,l_idx-1)));
            dbms_output.put_line('fsplit: '|| result_tbl_(l_tbl_idx));
            l_list := SUBSTR(l_list,l_idx+LENGTH(p_del));
        ELSE
            result_tbl_(l_tbl_idx) := LTRIM(RTRIM(l_list));
            dbms_output.put_line('fsplit: '|| result_tbl_(l_tbl_idx));
            EXIT;
        END IF;
        l_tbl_idx := l_tbl_idx +1;
    END LOOP;
    RETURN result_tbl_;
END f_split;
--
begin
-- set up parameteres
category_ := '&1';
rprt_desc_ :='&2';
sql_expression_ := '&3';
--CQ63967
roles_tbl_ := f_split('&4'); 
comments_ := '&5';
--
dbms_output.put_line('first ndx:' || roles_tbl_.FIRST || ' last ndx: ' || roles_tbl_.LAST);
dbms_output.put_line('before role output'); 
dbms_output.put_line(roles_tbl_(roles_tbl_.FIRST)); 
dbms_output.put_line(roles_tbl_(roles_tbl_.LAST)); 
  
  -- Create a new quick report record
  -- Call Prepare Insert to get the next sequence for the Report Id
  action_ := 'PREPARE';
  Client_SYS.Clear_Attr (attr_);
  Quick_Report_API.New__(info_,
                         objid_,
                         objversion_,
                         attr_,
                         action_);

  -- Add the report name to the attr_ string.
  Client_SYS.Add_To_Attr('DESCRIPTION', rprt_desc_, attr_);

  -- No limit on SQL Expression size any more it is a CLOB.  
  Client_SYS.Add_To_Attr('SQL_EXPRESSION', sql_expression_, attr_);

  -- Add comments to the report.
  Client_SYS.Add_To_Attr('COMMENTS', trim(comments_), attr_);

  -- Add category description
  Client_SYS.Add_To_Attr('CATEGORY_DESCRIPTION', category_, attr_); 

  -- Report Type
  Client_SYS.Add_To_Attr('QR_TYPE',Quick_Report_Type_API.DECODE('SQL'),attr_);

  -- Insert Record into Quick Report
  action_ := 'DO';
  Quick_Report_API.New__(info_,
                         objid_,
                         objversion_,
                         attr_,
                         action_);

					  
  -- Publish the report    

-- fetch new reportid
dbms_output.put_line('before report select for objid: ' || objid_);
  select quick_report_id into newrecid_ from quick_report t where t.objid = objid_;
dbms_output.put_line('after report select for objid: ' || objid_);  
-- grant 'SELECT' on  underlying security objects(views) to list of passed roles. 
-- This will allow Quick Report to be visible by specific role
  
  for sec_obj_rec in get_sec_objects(newrecid_) loop
    IF UPPER(sec_obj_rec.sec_object_type) = 'VIEW' then 
      --CQ63967
      dbms_output.put_line(roles_tbl_(1)|| ' ' || roles_tbl_(2));
      FOR i IN roles_tbl_.FIRST..roles_tbl_.LAST loop
         dbms_output.put_line('view: ' || sec_obj_rec.sec_object || ' ' || roles_tbl_(i));  
          Security_Sys.Grant_View(sec_obj_rec.sec_object,roles_tbl_(i));
         dbms_output.put_line('view done');  
      end loop;
      --
    END IF;  
    IF UPPER(sec_obj_rec.sec_object_type) = 'METHOD' then 
      --CQ63967
      FOR i IN roles_tbl_.FIRST..roles_tbl_.LAST loop
         dbms_output.put_line('method: ' || sec_obj_rec.sec_object || ' ' || roles_tbl_(i)); 
          Security_Sys.Grant_Method(sec_obj_rec.sec_object,roles_tbl_(i));
         dbms_output.put_line('method done'); 

      end loop;
      --
    END IF;  
  end loop;

   Quick_Report_API.Publish__(newrecid_);      


 -- RFC 33115						 
  -- Write SQL Expression
  
    SELECT rowid
      INTO rowid_ FROM quick_report_tab
      WHERE DESCRIPTION = rprt_desc_;

  Quick_Report_API.Write_Sql_Expression__(objversion_,rowid_,sql_expression_);

  -- END RFC 33115	  
   
commit;                         
end;
