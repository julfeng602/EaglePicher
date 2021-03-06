SET serveroutput on;
DECLARE
    InParam1 varchar2(1000);


    OutParam3 varchar2(1000);
    OutParam4 varchar2(1000);
    report_attr_ varchar2(10000);

      objid_         QMAN_SAMPLE_VALUE.objid%TYPE;
      objversion_    QMAN_SAMPLE_VALUE.objversion%TYPE;
      result_ number;
BEGIN
    /* Assign values to IN parameters */
    InParam1 := NULL;
    Select ObjID into objid_ from qman_sample_value where analysis_no = '26' and data_point = '2';
    select objversion into objversion_ from qman_sample_value where analysis_no = '26' and data_point = '2';

    client_sys.Add_To_Attr('RESULT', '403',report_attr_);
    client_sys.Add_To_Attr('ACCURACY', '0',report_attr_);
--OutParam3 := report_attr_;--'RESULT200ACCURACY0'
                           --RESULT203ACCURACY0
OutParam4 := 'CHECK';
    dbms_output.put_line('report_attr_: ' || report_attr_);
BEGIN
    SAVEPOINT do_insert;
    --QMAN_SAMPLE_VALUE_API.MODIFY__(InParam1, objid_,
    --    objversion_, report_attr_, OutParam4);
        OutParam4 := 'DO';

    QMAN_SAMPLE_VALUE_API.MODIFY__(InParam1, objid_,
        objversion_, report_attr_, OutParam4);
    commit;
EXCEPTION 
WHEN Error_SYS.Err_Security_Checkpoint THEN 
dbms_output.put_line('ERROR OCCURRED ' );
raise; 
WHEN OTHERS THEN 
rollback to do_insert; 
raise; 
END;
SELECT RESULT into result_ FROM QMAN_SAMPLE_VALUE
where analysis_no = '26'and data_point = '2';
    /* Display OUT parameters */
    dbms_output.put_line('objid_: ' || objid_);
    dbms_output.put_line('objversion_: ' || objversion_);
    dbms_output.put_line('report_attr_: ' || report_attr_);
dbms_output.put_line('result_: ' || result_);
SELECT RESULT into result_ FROM QMAN_SAMPLE_VALUE
where analysis_no = '26'and data_point = '2';
dbms_output.put_line('result_: ' || result_);
END;
/
COMMIT;
/