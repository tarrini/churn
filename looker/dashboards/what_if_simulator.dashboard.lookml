- dashboard: what_if_simulator
  title: What-if Simulator
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Capacity × threshold scenarios and marginal gain from adding capacity"
  elements:
  - title: Net expected value by scenario
    name: net_value_by_scenario
    model: churn_intelligence
    explore: retention_what_if
    type: looker_bar
    fields: [retention_what_if.scenario_id, retention_what_if.net_expected_value]
    sorts: [retention_what_if.net_expected_value desc]
    limit: 500
    listen:
      Snapshot Date: retention_what_if.snapshot_date
      Risk Threshold: retention_what_if.risk_threshold
      Capacity Limit: retention_what_if.capacity_limit
    row: 0
    col: 0
    width: 24
    height: 8

  - title: Scenario detail
    name: scenario_table
    model: churn_intelligence
    explore: retention_what_if
    type: looker_grid
    fields:
    - retention_what_if.scenario_id
    - retention_what_if.capacity_limit
    - retention_what_if.risk_threshold
    - retention_what_if.selected_customers
    - retention_what_if.total_expected_mrr_saved
    - retention_what_if.total_action_cost
    - retention_what_if.net_expected_value
    sorts: [retention_what_if.net_expected_value desc]
    limit: 500
    listen:
      Snapshot Date: retention_what_if.snapshot_date
      Risk Threshold: retention_what_if.risk_threshold
      Capacity Limit: retention_what_if.capacity_limit
    row: 8
    col: 0
    width: 14
    height: 10

  - title: Expected MRR saved vs action cost
    name: saved_vs_cost
    model: churn_intelligence
    explore: retention_what_if
    type: looker_column
    fields:
    - retention_what_if.scenario_id
    - retention_what_if.total_expected_mrr_saved
    - retention_what_if.total_action_cost
    sorts: [retention_what_if.total_expected_mrr_saved desc]
    limit: 500
    listen:
      Snapshot Date: retention_what_if.snapshot_date
      Risk Threshold: retention_what_if.risk_threshold
      Capacity Limit: retention_what_if.capacity_limit
    row: 8
    col: 14
    width: 10
    height: 10

  - title: Marginal net value when increasing capacity
    name: marginal_gain
    model: churn_intelligence
    explore: retention_marginal_gain
    type: looker_bar
    fields:
    - retention_marginal_gain.base_capacity
    - retention_marginal_gain.new_capacity
    - retention_marginal_gain.marginal_net_value
    - retention_marginal_gain.risk_threshold
    sorts: [retention_marginal_gain.marginal_net_value desc]
    limit: 500
    listen:
      Snapshot Date: retention_marginal_gain.snapshot_date
      Risk Threshold: retention_marginal_gain.risk_threshold
    row: 18
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
    explore: retention_what_if
    field: retention_what_if.snapshot_date

  - name: Risk Threshold
    title: Risk Threshold
    type: field_filter
    default_value: ""
    allow_multiple_values: true
    required: false
    ui_config:
      type: advanced
      display: popover
    model: churn_intelligence
    explore: retention_what_if
    field: retention_what_if.risk_threshold

  - name: Capacity Limit
    title: Capacity Limit
    type: field_filter
    default_value: ""
    allow_multiple_values: true
    required: false
    ui_config:
      type: advanced
      display: popover
    model: churn_intelligence
    explore: retention_what_if
    field: retention_what_if.capacity_limit
