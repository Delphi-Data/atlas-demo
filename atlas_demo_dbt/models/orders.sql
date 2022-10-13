{{ config(materialized="table", tags="event_stream") }}

{{ dbt_product_analytics.event_stream(
    from=ref('raw_orders'),
    event_type_col="status",
    user_id_col="user_id",
    date_col="order_date",
)}}