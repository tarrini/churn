{# Use the folder schema (staging, mart, ml, monitoring) as the BigQuery dataset name
   so models land in e.g. `ml.*` and match sql/bqml + sql/serving paths. Default dbt
   would prefix with target.dataset (staging_ml, staging_mart, ...). #}
{% macro generate_schema_name(custom_schema_name, node) -%}
  {%- if custom_schema_name is none -%}
    {{ target.schema }}
  {%- else -%}
    {{ custom_schema_name | trim }}
  {%- endif -%}
{%- endmacro %}
