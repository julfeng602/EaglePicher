--select po.*, p.*  from purchase_order po
--left outer join project p
--on p.project_id = po.project_id
/*
Select
    co.customer_po_no, 
    co.order_no, 
    co.company,
    p.project_id
from customer_order co
inner join project_cfv p
on p.project_id = co.project_id
where
co.customer_po_no = 'TEST2' and co.company = '100'
order by co.order_no
*/

select 
    co.customer_po_no, 
    co.order_no, 
    col.line_no,
    col.rel_no,
    co.company,
    p.project_id,
    a.sub_project_id,
    a.activity_seq,
    dme_contract_api.Get_Contract_Type(co.customer_po_no),
    p.cf$_contract_type,
    p.cf$_funded_total,
    a.cf$_funded_amt,
    bd.control_category,
    bd.baseline_cost,
    --pc.used_cost,
    --pc.progress_cost,
    --pc.planned_hours,
    Project_Connection_Temp_API.Get_Used_Cost(a.activity_seq) used_cost,
    Project_Connection_Temp_API.Get_Progress_Cost(p.project_id, bd.control_category) progress_cost,
    project_Connection_Temp_API.Get_Planned_Hours(p.project_id, bd.control_category) baseline_hours,
    Project_Connection_Details_Api.Get_Actual_Hours(a.activity_seq, bd.control_category) actual_hours,
    Project_Connection_Details_Api.Get_Progress_Hours(a.activity_seq, bd.control_category) progress_hours,
    p.planned_revenue,
    project_totals_api.Get_Rec_Revenue_Posted(co.company, 'F', p.project_id, '*') revenue_posted,
    a.early_start,
    a.early_finish,
    a.description
   -- p.used_cost--,
    --a.*--,
    --p.*,
    --a.*
from customer_order co
left outer join customer_order_line col
on col.order_no = co.order_no
inner join project_cfv p
on p.project_id = co.project_id
left outer join activity_cfv a on a.project_id = p.project_id
left outer join project_baseline_detail bd on bd.activity_seq = a.activity_seq AND bd.project_id = p.project_id
--left outer join project_connection_temp pc on pc.project_id = p.project_id and pc.project_cost_element = bd.control_category
where
--co.customer_po_no like '%' and co.company like '%'
co.customer_po_no = 'TEST2' 
and co.company = '100'
--co.customer_po_no = 'COSTPLUS'
and co.order_no = 'D1002'
--a.activity_NO LIKE 'A%'
--p.project_id LIKE 'D102%'
order by co.order_no, col.line_no, col.rel_no, a.activity_no


--select * from dme_contract
--select * from contract
--select * from activity WHERE ACTIVITY_NO LIKE 'A%'
/*
select p.cf$_funded_total, p.* 
from IFSAPP.PROJECT_CFV p
where
p.cf$_funded_total is not null
*/
--select * from activity_ELEMENT
--select * from all_source where upper(text) like '%CONTROL_CATEGORY%'
--SELECT * FROM project
--select * from activity where project_id = 'D1002'

--select * from project_baseline_detail where project_id = 'D1002'