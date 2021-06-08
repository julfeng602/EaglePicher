         select
         null project_funded_total,
         sum(bd.baseline_cost) baseline_cost,
         null used_cost,
         sum(project_Connection_Temp_API.Get_Planned_Hours(p.project_id, bd.control_category))  calc_cost_progress,
         sum(project_Connection_Temp_API.Get_Planned_Hours(p.project_id, bd.control_category))  baseline_hours,
         sum(Project_Connection_Details_Api.Get_Actual_Hours(a.activity_seq, bd.control_category))  actual_hours,
         NULL  calc_progress_hours,
         sum(p.planned_revenue)  planned_revenue,
         NULL  posted_revenue,
         NULL  cost_forecast_30,
         NULL  cost_forecast_31_60,
         NULL  cost_total_projected_60,
         NULL  percent_funding_req,
         NULL  amt_diff_already_funded
         from customer_order co
         left outer join customer_order_line col
         on col.order_no = co.order_no
         inner join project_cfv p
         on p.project_id = co.project_id
         left outer join activity_cfv a on a.project_id = p.project_id
         left outer join project_baseline_detail bd on bd.activity_seq = a.activity_seq AND bd.project_id = p.project_id
     where
      --co.customer_po_no like cust_po_no_ and
      --co.order_no like cust_order_ and
      co.company like '100'
      order by co.order_no, col.line_no, col.rel_no, a.activity_no;