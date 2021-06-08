      select 
         co.customer_po_no   customer_po_no, 
         co.order_no       order_no, 
         col.line_no       line_no,
         col.rel_no        rel_no,
         co.company        company,
         p.project_id      project_id,
         a.sub_project_id  sub_project_id,
         a.activity_seq    activity_seq,
         p.cf$_contract_type    contract_type,
         p.cf$_funded_total    funded_total,
         a.cf$_funded_amt    funded_amt,
         bd.control_category    control_category,
         bd.baseline_cost    baseline_cost,
         Project_Connection_Temp_API.Get_Used_Cost(a.activity_seq)    used_cost,
         Project_Connection_Temp_API.Get_Progress_Cost(p.project_id, bd.control_category)    progress_cost,
         project_Connection_Temp_API.Get_Planned_Hours(p.project_id, bd.control_category)    baseline_hours,
         Project_Connection_Details_Api.Get_Actual_Hours(a.activity_seq, bd.control_category)    actual_hours,
         Project_Connection_Details_Api.Get_Progress_Hours(a.activity_seq, bd.control_category)    progress_hours,
         p.planned_revenue    planned_revenue,
         project_totals_api.Get_Rec_Revenue_Posted(co.company, 'F', p.project_id, '*')    revenue_posted,
         a.early_start    early_start,
         a.early_finish    early_finish,
         a.description    description
         from customer_order co
         left outer join customer_order_line col
         on col.order_no = co.order_no
         inner join project_cfv p
         on p.project_id = co.project_id
         left outer join activity_cfv a on a.project_id = p.project_id
         left outer join project_baseline_detail bd on bd.activity_seq = a.activity_seq AND bd.project_id = p.project_id
      where
      co.customer_po_no like 'TEST2' and --cust_po_no_ and
      co.order_no like 'D1002' and --cust_order_ and
      co.company like '100' --company_
      order by co.order_no, col.line_no, col.rel_no, a.activity_no;