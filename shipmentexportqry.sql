

select  s.shipment_id,
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
where  s.shipment_id = 2 and  s.receiver_type_db = 'CUSTOMER'
order by l.shipment_line_no

--export control record
SELECT 1 AS EXPORT_CONTROLLED FROM PARTCA_EXPORT_CONTROL ec
where
ec.EXPORT_CONTROLLED in ('Yes', 'Not Decided', 'Denied Party Only') and
UPPER(ec.part_no) = UPPER('&p')

--select * from customer_order_line where order_no = 'I109'
--verify customer not us
select c.customer_no, c.ship_addr_no, Cust_Ord_Customer_Address_API.Get_Country_Code(c.CUSTOMER_NO,c.SHIP_ADDR_NO) country_code, c.* 
from 
customer_order c
where c.order_no = 'I109'

select * from customer_order where order_no = 'I109'

--check export license on part
select 
    h.exp_license_connect_id,
    h.order_ref1,
    h.order_ref2,
    h.order_ref3,
    h.order_ref4,
    h.end_user_customer_id,
    d.export_license_id,
    Export_License_Api.Get_License_Number(d.export_license_id) license_no,
    d.license_connected,
    l.*
from EXP_LICENSE_CONNECT_HEAD h
JOIN EXP_LICENSE_CONNECT_DETAIL d
on d.EXP_LICENSE_CONNECT_ID = h.EXP_LICENSE_CONNECT_ID
join export_license l
on l.export_license_id = d.export_license_id
where h.PART_NO = 'MD-BAT-SERIAL'  AND h.ORDER_REF1 = 'I109' AND h.END_USER_CUSTOMER_ID = 'SWEDEN001'
  --and d.license_connected_db = 'TRUE'
  AND sysdate between l.effective_from and l.expires--MAT_PART_SERIAL AND CUSTOMER ORDER


--select sysdate from dual;
select * from exp_license_connect_head




