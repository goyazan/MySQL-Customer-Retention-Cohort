# subscription_detail nulls labeled as 'Purchase'

select
	x.order_date,
    x.orderid,
    x.email,
	x.amount,
	x.currencyisocode,
	x.status,
	x.type,
    wp.product_name,
	x.recurring,
    x.payment_system,
    wp.product_type,
    wp.product_group_1,
    wp.product_group_2,
    wp.product_campaign,
    wp.is_promotion,
    wp.percent_discount,
	x.subscriptionid,
    x.order_count,
    x.payment_ordinal_number,
    
	case
		when wp.product_type = 'Subscription' and recurring = 0 then 'Purchase'
		when wp.product_type = 'Subscription' and recurring = 1 then 'Renewal'
		else 'Purchase'
	end as subscription_detail

from
	(select
		convert_tz(tr.createdat, "UTC", "America/Los_Angeles") as order_date,
		tr.orderid,
		cu.email,
		tr.amount,
		tr.currencyisocode,
		tr.status,
		tr.type,
		
		case
			when wo.order_item_name is not null then wo.order_item_name
			when tr.planid is not null then tr.planid
			else tr2.planid
		end as product_name,
		
		tr.recurring,
		"Braintree" as payment_system,
        
		case
			when tr.subscriptionid is null and tr.recurring = 1 then tr.orderid + 1
			when tr.subscriptionid is null and tr.recurring = 0 and (wo.order_item_name in (select order_item_name from woo_product_groups where product_type = 'Subscription')) then tr.orderid + 1
			else tr.subscriptionid
		end as subscriptionid,
		
		vt.order_count,
		
		concat(
			vt.order_count, 
			case
				when vt.order_count = 1 then "st Month Payment"
				when vt.order_count % 100 between 11 and 13 then "th Month Renewal"
				when vt.order_count % 10 = 1 then "st Month Renewal"
				when vt.order_count % 10 = 2 then "nd Month Renewal"
				when vt.order_count % 10 = 3 then "rd Month Renewal"
				else "th Month Renewal"
			end
		) as payment_ordinal_number
        
	from
		btree_transaction as tr
		
	left outer join
		(select id, planid from btree_transaction where type = 'SALE' and planid is not null) as tr2
		on tr.refundedtransactionid = tr2.id
	
	inner join 
		btree_transaction_customer as cu
		on tr.daton_batch_id = cu.daton_parent_batch_id and tr.daton_batch_runtime = cu.daton_batch_runtime
		
	left outer join 
		(select * from woo_order_items where order_item_type = 'line_item') as wo
		on tr.orderid = wo.order_id
			
	left outer join
		(select
			a.email,
			if(a.subscriptionid is null, a.orderid + 1, a.subscriptionid) as subscriptionid,
			a.createdat,
			count(*) as order_count
		
        from
			(select
				cu.email, tr.createdat, tr.recurring, wo.order_item_name, tr.status, tr.type, tr.subscriptionid, tr.orderid
			from
				btree_transaction as tr
			inner join
				btree_transaction_customer as cu 
				on tr.daton_batch_id = cu.daton_parent_batch_id and tr.daton_batch_runtime = cu.daton_batch_runtime
			left outer join
				(select * from woo_order_items where order_item_type = 'line_item') as wo 
				on tr.orderid = wo.order_id
			) as a
			
		inner join
		
			(select
				cu.email, tr.createdat, tr.recurring, wo.order_item_name, tr.status, tr.type, tr.subscriptionid, tr.orderid
			from
				btree_transaction as tr
			inner join
				btree_transaction_customer as cu 
				on tr.daton_batch_id = cu.daton_parent_batch_id and tr.daton_batch_runtime = cu.daton_batch_runtime
			left outer join
				(select * from woo_order_items where order_item_type = 'line_item') as wo 
				on tr.orderid = wo.order_id
			) as b
			
		on a.email = b.email 
        and if(a.subscriptionid is null, a.orderid + 1, a.subscriptionid) = if(b.subscriptionid is null, b.orderid + 1, b.subscriptionid) 
        and a.createdat >= b.createdat
		
		where
			((a.recurring = 1) or ((a.recurring = 0) and (a.order_item_name in (select order_item_name from woo_product_groups where product_type = 'Subscription'))))
			and a.status in ('SETTLED', 'SETTLING', 'SUBMITTED_FOR_SETTLEMENT')
			and a.type = 'SALE'
			and ((b.recurring = 1) or ((b.recurring = 0) and (b.order_item_name in (select order_item_name from woo_product_groups where product_type = 'Subscription'))))
			and b.status in ('SETTLED', 'SETTLING', 'SUBMITTED_FOR_SETTLEMENT')
			and b.type = 'SALE'
			
		group by
			a.email,
			a.subscriptionid,
			a.createdat
		) as vt
		on tr.createdat = vt.createdat and cu.email = vt.email 
        and
		(case
			when tr.subscriptionid is null and tr.recurring = 1 then tr.orderid + 1
			when tr.subscriptionid is null and tr.recurring = 0 and (wo.order_item_name in (select order_item_name from woo_product_groups where product_type = 'Subscription')) then tr.orderid + 1
			else tr.subscriptionid
		end
		) = vt.subscriptionid
		
	where
		convert_tz(tr.createdat, "UTC", "America/Los_Angeles") >= '2020-11-02'
        and cu.email is not null
	) as x

left outer join
	woo_product_groups as wp
    on x.product_name = wp.order_item_name