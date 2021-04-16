SELECT
    lc.export_license_id,
    l.license_number,
    l.description,
    l.authority_license_no,
    l.issuing_authority,
    l.state,
    to_char(l.issued_date,'MM/dd/YYYY'),
    to_char(l.effective_from, 'MM/dd/YYYY'),
    to_char(l.expires, 'MM/dd/YYYY'),
    lc.qty_licensed,
    lc.part_no,
    lc.amt_licensed,
    lc.qty_shipped,
    lc.amt_shipped
FROM
    export_license           l
    LEFT OUTER JOIN export_license_coverage  lc ON lc.export_license_id = l.export_license_id