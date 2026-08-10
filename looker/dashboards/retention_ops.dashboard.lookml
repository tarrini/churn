- dashboard: retention_ops
  title: Retention Ops Dashboard
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Intervention shortlist sorted by ROI; filter selected_for_intervention"
  elements:
  - title: Selected for intervention
    name: selected_count
    model: churn_intelligence
    explore: retention_decision_engine
    type: single_value
    fields: [retention_decision_engine.selected_customers]
    filters:
      retention_decision_engine.selected_for_intervention: "yes"
    limit: 500
    listen:
      Snapshot Date: retention_decision_engine.snapshot_date
      Plan Tier: dim_customer.plan_tier
    row: 0
    col: 0
    width: 8
    height: 4

  - title: Expected MRR saved (selected)
    name: expected_mrr_saved_selected
    model: churn_intelligence
    explore: retention_decision_engine
    type: single_value
    fields: [retention_decision_engine.total_expected_mrr_saved]
    filters:
      retention_decision_engine.selected_for_intervention: "yes"
    limit: 500
    listen:
      Snapshot Date: retention_decision_engine.snapshot_date
      Plan Tier: dim_customer.plan_tier
    row: 0
    col: 8
    width: 8
    height: 4

  - title: MRR at risk (selected)
    name: mrr_at_risk_selected
    model: churn_intelligence
    explore: retention_decision_engine
    type: single_value
    fields: [retention_decision_engine.total_mrr_at_risk]
    filters:
      retention_decision_engine.selected_for_intervention: "yes"
    limit: 500
    listen:
      Snapshot Date: retention_decision_engine.snapshot_date
      Plan Tier: dim_customer.plan_tier
    row: 0
    col: 16
    width: 8
    height: 4

  - title: Intervention shortlist (top ROI)
    name: intervention_shortlist
    model: churn_intelligence
    explore: retention_decision_engine
    type: looker_grid
    fields:
    - retention_decision_engine.priority_rank
    - retention_decision_engine.customer_id
    - retention_decision_engine.predicted_churn_prob
    - retention_decision_engine.monthly_mrr
    - retention_decision_engine.mrr_at_risk
    - retention_decision_engine.primary_risk_driver
    - retention_decision_engine.policy_action_name
    - retention_decision_engine.roi_score
    - retention_decision_engine.expected_mrr_saved
    - dim_customer.plan_tier
    filters:
      retention_decision_engine.selected_for_intervention: "yes"
    sorts: [retention_decision_engine.priority_rank]
    limit: 200
    listen:
      Snapshot Date: retention_decision_engine.snapshot_date
      Plan Tier: dim_customer.plan_tier
      Risk Driver: retention_decision_engine.primary_risk_driver
    row: 4
    col: 0
    width: 24
    height: 10

  - title: Primary risk driver mix
    name: risk_driver_mix
    model: churn_intelligence
    explore: retention_decision_engine
    type: looker_pie
    fields: [retention_decision_engine.primary_risk_driver, retention_decision_engine.count]
    filters:
      retention_decision_engine.selected_for_intervention: "yes"
    sorts: [retention_decision_engine.count desc]
    limit: 500
    listen:
      Snapshot Date: retention_decision_engine.snapshot_date
      Plan Tier: dim_customer.plan_tier
    row: 14
    col: 0
    width: 12
    height: 8

  - title: Policy action mix
    name: policy_action_mix
    model: churn_intelligence
    explore: retention_decision_engine
    type: looker_pie
    fields: [retention_decision_engine.policy_action_name, retention_decision_engine.count]
    filters:
      retention_decision_engine.selected_for_intervention: "yes"
    sorts: [retention_decision_engine.count desc]
    limit: 500
    listen:
      Snapshot Date: retention_decision_engine.snapshot_date
      Plan Tier: dim_customer.plan_tier
    row: 14
    col: 12
    width: 12
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
    explore: retention_decision_engine
    field: retention_decision_engine.snapshot_date

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
    explore: retention_decision_engine
    field: dim_customer.plan_tier

  - name: Risk Driver
    title: Risk Driver
    type: field_filter
    default_value: ""
    allow_multiple_values: true
    required: false
    ui_config:
      type: checkboxes
      display: popover
    model: churn_intelligence
    explore: retention_decision_engine
    field: retention_decision_engine.primary_risk_driver
