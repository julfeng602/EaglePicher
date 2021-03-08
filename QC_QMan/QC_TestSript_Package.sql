SET serveroutput on;
DECLARE
      result_ varchar2(200);
BEGIN
result_ := EP_QC_QMAN_Analysis.Update_Point_Value('TIM MANUFACTURING TOOL', NULL, 10, 2, 210, 0);
dbms_output.put_line('result_: ' || result_);
END;
/
