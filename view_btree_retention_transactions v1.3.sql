select
	email,
    subscriptionid,
	product_name,
    product_group_1,
    product_group_2,
	order_date
from
	view_braintree_transactions
where
	status in ('SETTLED', 'SETTLING', 'SUBMITTED_FOR_SETTLEMENT') 
	and type = 'SALE' 
	and product_type = 'Subscription'