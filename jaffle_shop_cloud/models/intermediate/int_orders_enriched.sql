with orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

locations as (

    select * from {{ ref('stg_locations') }}

),

enriched as (

    select
        orders.order_id,
        orders.order_date,
        orders.customer_id,
        customers.customer_name,
        orders.location_id,
        locations.location_name,
        locations.tax_rate,
        orders.subtotal,
        orders.tax_paid,
        orders.order_total

    from orders
    left join customers on orders.customer_id = customers.customer_id
    left join locations on orders.location_id = locations.location_id

)

select * from enriched
