select
	first_payment_month,
	product_name,
	count(distinct email) as total_customers_per_cohort
from
	(select
		email,
        subscriptionid,
		product_name,
		date_format(min(order_date), '%Y%m') as first_payment_month
	from
		view_braintree_transactions
	where
		status in ('SETTLED', 'SETTLING', 'SUBMITTED_FOR_SETTLEMENT') 
		and type = 'SALE' 
		and product_type = 'Subscription'
	group by
		email,
        subscriptionid,
		product_name
	) as a
group by
	first_payment_month,
	product_name