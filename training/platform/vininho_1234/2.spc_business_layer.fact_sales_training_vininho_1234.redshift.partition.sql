select
 to_char(sale_order_store_date::timestamp, 'YYYYMMDD') as partition_field
, src_fk_sale_order_store_item||2 					as custom_primary_key
, src_fk_sale_order_store_item
, src_fk_sale_order_store
, sale_order_store_number
, sale_order_store_date::timestamp 					as sale_order_store_date
, fk_product_simple
, fk_product_config
, fk_customer
, fk_address_billing
, fk_address_shipping
, 2 as fk_country
, 2 as fk_company
, coalesce(gross_merchandise_value, 0) 				as gross_merchandise_value
, coalesce(markdown_discount_value, 0) 				as markdown_discount_value
, coalesce(cart_discount_value, 0) 					as cart_discount_value
, coalesce(gross_shipping_chaged_to_customer, 0) 	as gross_shipping_chaged_to_customer
, coalesce(gross_merchandise_value, 0) + coalesce(gross_shipping_chaged_to_customer, 0) as gross_total_value
from spc_staging.fact_sales_delta_load_vininho_1234
;