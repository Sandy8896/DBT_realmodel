select * from dbt_test.raw.raw_customers;
select * from dbt_test.raw.raw_events;

select * from dbt_test.raw.raw_orders;

select * from dbt_test.staging.STG_CUSTOMERS;
select * from dbt_test.staging.STG_EVENTS;
select * from dbt_test.staging.STG_ORDERS;

select * from DBT_TEST.MARTS.DIM_CUSTOMERS;
select * from DBT_TEST.MARTS.FCT_DAILY_REVENUE_INCREMENTAL;
select * from DBT_TEST.MARTS.FCT_EVENTS_INCREMENTAL;
select * from DBT_TEST.MARTS.FCT_ORDERS;


select * from DBT_TEST.SNAPSHOTS.SNAP_CUSTOMERS;

select * from DBT_TEST.SNAPSHOTS.SNAP_ORDERS;



