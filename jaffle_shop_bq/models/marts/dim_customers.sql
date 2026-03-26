with orders as (

    select * from {{ ref('int_orders_enriched') }}

),

customer_metrics as (

    select
        customer_id,
        customer_name,

        count(order_id)             as total_orders,
        sum(order_total)            as total_spend,
        avg(order_total)            as avg_order_value,
        min(order_date)             as first_order_date,
        max(order_date)             as last_order_date,
        count(distinct location_id) as locations_visited

    from orders
    group by customer_id, customer_name

),

segmented as (

    select
        customer_id,
        customer_name,
        total_orders,
        round(total_spend, 2)       as total_spend,
        round(avg_order_value, 2)   as avg_order_value,
        first_order_date,
        last_order_date,
        locations_visited,

        case
            when total_spend >= 100 then 'Gold'
            when total_spend >= 50  then 'Silver'
            else                         'Bronze'
        end                         as customer_segment

    from customer_metrics

)

select * from segmented
