--select po.*, p.*  from purchase_order po
--left outer join project p
--on p.project_id = po.project_id

select 
    co.customer_po_no, 
    co.order_no, 
    col.line_no,
    col.rel_no,
    p.project_id,
    a.sub_project_id,
    a.activity_seq,
    p.*
from customer_order co
left outer join customer_order_line col
on col.order_no = co.order_no
left outer join project p
on p.project_id = co.project_id
left outer join activity a on a.project_id = p.project_id
where
a.activity_NO LIKE 'A%'
--p.project_id LIKE 'VM%'
order by co.order_no, col.line_no, col.rel_no


select * from activity WHERE ACTIVITY_NO LIKE 'A%'
