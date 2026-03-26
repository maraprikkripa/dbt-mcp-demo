with orders as (

    select * from {{ ref('int_orders_enriched') }}

),

item_summary as (

    select
        order_id,
        count(order_item_id)                                    as count_items,
        sum(case when is_food_item  then 1 else 0 end)          as count_food_items,
        sum(case when is_drink_item then 1 else 0 end)          as count_drink_items,
        sum(supply_cost)                                        as total_supply_cost,
        sum(gross_margin)                                       as total_gross_margin

    from {{ ref('int_order_items_enriched') }}
    group by order_id

),

joined as (

    select
        orders.order_id,
        orders.order_date,
        orders.customer_id,
        orders.customer_name,
        orders.location_id,
        orders.location_name,
        orders.subtotal,
        orders.tax_paid,
        orders.order_total,

        coalesce(item_summary.count_items, 0)           as count_items,
        coalesce(item_summary.count_food_items, 0)      as count_food_items,
        coalesce(item_summary.count_drink_items, 0)     as count_drink_items,
        coalesce(item_summary.count_food_items, 0) > 0  as is_food_order,
        coalesce(item_summary.count_drink_items, 0) > 0 as is_drink_order,
        coalesce(item_summary.total_supply_cost, 0)     as total_supply_cost,
        coalesce(item_summary.total_gross_margin, 0)    as total_gross_margin,

        row_number() over (
            partition by orders.customer_id
            order by orders.order_date asc
        )                                               as customer_order_number

    from orders
    left join item_summary on orders.order_id = item_summary.order_id

)

select * from joined
