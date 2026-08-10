- dashboard: executive
  title: Executive Dashboard
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "MRR at risk, high-risk customers, and churn probability trends"
  elements:
  - title: High-risk customers
    name: high_risk_customers
    model: churn_intelligence
    explore: customer_risk
    type: single_value
    fields: [customer_risk.high_risk_customers]
    limit: 500
    listen:
      Snapshot Date: customer_risk.snapshot_date
    row: 0
    col: 0
    width: 8
    height: 4

  - title: MRR at risk
    name: mrr_at_risk
    model: churn_intelligence
    explore: customer_risk
    type: single_value
    fields: [customer_risk.mrr_at_risk]
    limit: 500
    listen:
      Snapshot Date: customer_risk.snapshot_date
    row: 0
    col: 8
    width: 8
    height: 4

  - title: Average churn probability
    name: average_churn_prob
    model: churn_intelligence
    explore: customer_risk
    type: single_value
    fields: [customer_risk.average_churn_prob]
    limit: 500
    listen:
      Snapshot Date: customer_risk.snapshot_date
    row: 0
    col: 16
    width: 8
    height: 4

  - title: Average churn probability by snapshot date
    name: churn_prob_trend
    model: churn_intelligence
    explore: customer_risk
    type: looker_line
    fields: [customer_risk.snapshot_date, customer_risk.average_churn_prob]
    sorts: [customer_risk.snapshot_date]
    limit: 500
    listen:
      Snapshot Date: customer_risk.snapshot_date
    row: 4
    col: 0
    width: 12
    height: 8

  - title: MRR at risk by plan tier
    name: mrr_by_plan
    model: churn_intelligence
    explore: customer_risk
    type: looker_bar
    fields: [dim_customer.plan_tier, customer_risk.mrr_at_risk]
    sorts: [customer_risk.mrr_at_risk desc]
    limit: 500
    listen:
      Snapshot Date: customer_risk.snapshot_date
      Plan Tier: dim_customer.plan_tier
    row: 4
    col: 12
    width: 12
    height: 8

  - title: MRR at risk by country
    name: mrr_by_country
    model: churn_intelligence
    explore: customer_risk
    type: looker_column
    fields: [dim_customer.country, customer_risk.mrr_at_risk]
    sorts: [customer_risk.mrr_at_risk desc]
    limit: 500
    listen:
      Snapshot Date: customer_risk.snapshot_date
    row: 12
    col: 0
    width: 24
    height: 8

  filters:
  - name: Snapshot Date
    title: Snapshot Date
    type: field_filter
    default_value: ""
    allow_multiple_values: true
    required: false
    ui_config:
      type: advanced
      display: popover
    model: churn_intelligence
    explore: customer_risk
    field: customer_risk.snapshot_date

  - name: Plan Tier
    title: Plan Tier
    type: field_filter
    default_value: ""
    allow_multiple_values: true
    required: false
    ui_config:
      type: checkboxes
      display: popover
    model: churn_intelligence
    explore: customer_risk
    field: dim_customer.plan_tier
