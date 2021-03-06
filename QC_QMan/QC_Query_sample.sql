--update qman_sample_value_tab set result = '51' where analysis_no = '26' and data_point = 1
--commit;
select * from qman_sample_value_tab
where analysis_no = '26'

select max(analysis_no) from qman_sample_value_tab
where analysis_no = '26'

SELECT OBJVERSION
from qman_sample_value_tab
where analysis_no = '26'

SELECT * FROM QMAN_SAMPLE_VALUE
where analysis_no = '26'

select max(analysis_no) 
from QMAN_ANALYSIS_VA1342390886_CFV
where
analysis_state = 'Planned'
and part_no = 'TIM MANUFACTURING TOOL'
and serial_no = '*'
and test_operation_no = 10


