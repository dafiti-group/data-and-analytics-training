select
  soi.id_sales_order_item 					as src_fk_sale_order_store_item
, so.id_sales_order 						as src_fk_sale_order_store
, cast(so.order_nr as bigint) 				as sale_order_store_number
, so.created_at								as sale_order_store_date
, soi.paid_price							as gross_merchandise_value
, soi.original_unit_price - soi.unit_price 	as markdown_discount_value
, soi.unit_price - soi.paid_price			as cart_discount_value
, coalesce(cs.id_catalog_simple, 0)			as fk_product_simple
, coalesce(cc.id_catalog_config, 0)			as fk_product_config
, so.fk_customer
, so.fk_sales_order_address_billing 		as fk_address_billing
, so.fk_sales_order_address_shipping 		as fk_address_shipping
, so.shipping_amount / count(soi.id_sales_order_item) over(partition by so.id_sales_order) as gross_shipping_chaged_to_customer
from spc_raw_bob_dafiti_ar.sales_order_item 	as soi
inner join spc_raw_bob_dafiti_ar.sales_order 	as so on so.id_sales_order = soi.fk_sales_order
left join spc_raw_bob_dafiti_ar.catalog_simple	as cs on cs.sku = soi.sku
left join spc_raw_bob_dafiti_ar.catalog_config	as cc on cc.id_catalog_config = cs.fk_catalog_config
where 1=1
and soi.partition_value >= cast(date_format(date_add('month', -1, current_date), '%Y%m') as bigint)
and so.partition_value >= cast(date_format(date_add('month', -1, current_date), '%Y%m') as bigint)
and cast(so.created_at as timestamp) between cast(date_add('day', -${DAYS_GONE_FROM_DATE}, current_date) as timestamp) and cast(date_add('day', -${DAYS_GONE_TO_DATE}, current_date) as timestamp)
;