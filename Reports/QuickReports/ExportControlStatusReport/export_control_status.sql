select 
o.order_no,
o.customer_no,
IFSAPP.Customer_Info_Address_API.Get_Name(ai.CUSTOMER_NO,ai.BILL_ADDR_NO) customer_name,
o.customer_po_no,
to_char(o.wanted_delivery_date, 'MM/dd/YYYY') "Wanted Delivery Date",
o.currency_code,
o.state status,
ai.address1 || ' ' || ai.address2 || ' ' || ai.city || ', ' || '  ' || ai.state || '  ' || ai.zip_code || ' ' || ai.country_code  "address",
(select sum(l.buy_qty_due) from customer_order_line l where l.order_no = o.order_no) "Total Units",
(select sum(l.buy_qty_due * l.unit_price_incl_tax) from customer_order_line l where l.order_no = o.order_no) "Total Amount",
l.line_no,
l.catalog_type,
l.catalog_no,
l.catalog_desc,
l.buy_qty_due "Price Qty",
(l.buy_qty_due * l.sale_unit_price ) "Total Net Amt",
IFSAPP.EP_Export_Shipment_Check.GetExportControlled(l.part_no) "Export Controlled Part",
IFSAPP.EP_Export_Shipment_Check.GetLicenseNo(l.order_no, l.line_no, l.rel_no, l.line_item_no, l.part_no, l.buy_qty_due, o.customer_no) "License No", 
IFSAPP.EP_Export_Shipment_Check.GetLicenseConn(l.order_no, l.line_no, l.rel_no, l.line_item_no, l.part_no, l.buy_qty_due, o.customer_no) "License Status/Connected"
from 
customer_order_cfv o
left outer join customer_order_line l
ON l.order_no = o.order_no
left outer join ifsapp.CUST_ORD_ADDRESS_2_UIV ai
on ai.order_no = o.order_no
where
--o.order_no = '3212589'
--and 
ai.country_code != 'US'
and
l.catalog_type_db = 'INV'
order by 
o.order_no, l.line_no, l.rel_no, l.line_item_no

--select * from shipment_line s where shipment_id = '10'
--select * from customer_order_line where order_no = 'I109'