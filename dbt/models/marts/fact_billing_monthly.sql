select
  customer_id,
  date_trunc(invoice_date, month) as invoice_month,
  sum(amount) as billed_amount,
  countif(status = 'failed') as failed_invoices
from {{ ref('stg_invoices') }}
group by 1, 2
