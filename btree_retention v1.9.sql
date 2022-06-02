select
	first_payment_month,
    payment_ordinal_number,
    product_name,
    product_group_1,
    product_group_2,
    count(distinct email) as customers,
    min(total_customers_per_cohort) as total_customers_per_cohort,
	count(distinct email) / min(total_customers_per_cohort) as retention_rate
    
from
	(select
		br.email,
		br.product_name,
        br.product_group_1,
        br.product_group_2,
		t1.first_payment_month,
		period_diff(date_format(br.order_date, '%Y%m'), t1.first_payment_month) as payment_ordinal_number,
		t2.total_customers_per_cohort
	from
		gds_btree_retention_transactions as br
	left outer join
		gds_btree_retention_cohorts as t1
		on t1.email = br.email
        and t1.subscriptionid = br.subscriptionid
		and t1.product_name = br.product_name
	left outer join
		gds_btree_retention_cohort_totals as t2
		on t2.product_name = br.product_name
		and t2.first_payment_month = t1.first_payment_month
	) as x
			
group by
	first_payment_month,
    payment_ordinal_number,
    product_name,
    product_group_1,
    product_group_2