with order_items as (

    select * from {{ ref('stg_order_items') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

supply_costs as (

    select
        product_id,
        sum(supply_cost) as total_supply_cost

    from {{ ref('stg_supplies') }}
    group by product_id

),

enriched as (

    select
        order_items.order_item_id,
        order_items.order_id,
        order_items.product_id,
        products.product_name,
        products.product_type,
        products.product_price,
        products.is_food_item,
        products.is_drink_item,
        coalesce(supply_costs.total_supply_cost, 0)                              as supply_cost,
        products.product_price - coalesce(supply_costs.total_supply_cost, 0)    as gross_margin

    from order_items
    left join products      on order_items.product_id = products.product_id
    left join supply_costs  on order_items.product_id = supply_costs.product_id

)

select * from enriched
