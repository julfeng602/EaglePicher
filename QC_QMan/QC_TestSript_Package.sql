SET serveroutput on;
DECLARE
      result_ number;
BEGIN
result_ := EP_QC_QMAN_Analysis.Get_Analysis_No('TIM MANUFACTURING TOOL', NULL, 10);
dbms_output.put_line('result_: ' || result_);
END;
/
