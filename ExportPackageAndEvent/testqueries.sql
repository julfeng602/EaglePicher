select s.source_ref1,  co.*, s.* from customer_order co

join
shipment s on co.order_no = s.source_ref1

where co.country_code <> 'US'


select * from customer_order where order_no = '3371806'
select * from shipment_line
select * from shipment where source_ref1 = '3371806'
SELECT * FROM PARTCA_EXPORT_CONTROL WHERE PART_NO = 'EAP-12187'
SELECT ep_export_shipment_check.getexportcontrolled('EAP-12187') FROM DUAL;

select co.company, co.name from company co
join e_p_export_controlled_clv ev on co.objkey = ev.cf$_export_company_db

            Select 1 
            From 
                company co
                join e_p_export_controlled_clv ev on co.objkey = ev.cf$_export_company_db and co.company = (select company from customer_order where order_no = '3371806')
                
/*
set serveroutput on;
declare
 islinked boolean;
begin
islinked := EP_Export_Shipment_Check.ShipmentLinkedToCustomerOrder('100');
if (islinked) then
dbms_output.put_line('Yes');
else
dbms_output.put_line('No');
end if;
end;
*/

/*
set serveroutput on;
declare
 islinked boolean;
begin
islinked := EP_Export_Shipment_Check.ShipmentLinkedToExportCompany('10');
if (islinked) then
dbms_output.put_line('Yes');
else
dbms_output.put_line('No');
end if;
end;
*/
set serveroutput on;
declare
 islinked boolean;
begin
islinked := EP_Export_Shipment_Check.IsCountryOutsideUS('3371806');
if (islinked) then
dbms_output.put_line('Yes');
else
dbms_output.put_line('No');
end if;
end;
