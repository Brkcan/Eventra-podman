prompt === Eventra Oracle smoke test ===

prompt [1] required tables
with expected(table_name) as (
  select 'EVENTS' from dual union all
  select 'CUSTOMER_PROFILES' from dual union all
  select 'ACTION_LOG' from dual union all
  select 'EXTERNAL_CALL_LOG' from dual union all
  select 'JOURNEY_FOLDERS' from dual union all
  select 'JOURNEYS' from dual union all
  select 'JOURNEY_INSTANCES' from dual union all
  select 'EVENT_DLQ' from dual union all
  select 'JOURNEY_INSTANCE_TRANSITIONS' from dual union all
  select 'CONSUMED_EVENTS' from dual union all
  select 'EDGE_CAPACITY_USAGE' from dual union all
  select 'JOURNEY_RELEASE_CONTROLS' from dual union all
  select 'JOURNEY_APPROVALS' from dual union all
  select 'RUNTIME_CONTROLS' from dual union all
  select 'CATALOGUE_EVENT_TYPES' from dual union all
  select 'CATALOGUE_SEGMENTS' from dual union all
  select 'CATALOGUE_TEMPLATES' from dual union all
  select 'CATALOGUE_ENDPOINTS' from dual union all
  select 'EDGE_TRANSITION_LOG' from dual union all
  select 'CACHE_LOADER_CONNECTIONS' from dual union all
  select 'CACHE_LOADER_JOBS' from dual union all
  select 'CACHE_LOADER_RUNS' from dual
)
select e.table_name,
       case when t.table_name is not null then 'OK' else 'MISSING' end as status
from expected e
left join user_tables t on t.table_name = e.table_name
order by e.table_name;

prompt [2] required indexes
with expected(index_name) as (
  select 'IDX_ACTION_LOG_CUSTOMER_DATE' from dual union all
  select 'IDX_EDGE_TRANSITION_DAILY' from dual union all
  select 'IDX_EVENTS_CUSTOMER_TYPE_TS' from dual union all
  select 'IDX_JI_STATE_DUE' from dual union all
  select 'IDX_TRANSITIONS_INSTANCE_DATE' from dual
)
select e.index_name,
       case when i.index_name is not null then 'OK' else 'MISSING' end as status
from expected e
left join user_indexes i on i.index_name = e.index_name
order by e.index_name;

prompt [3] runtime controls seed row
select key, value_json, updated_at
from runtime_controls
where key = 'global_pause';

prompt [4] core table row counts
select 'journeys' as table_name, count(*) as row_count from journeys
union all
select 'journey_instances', count(*) from journey_instances
union all
select 'events', count(*) from events
union all
select 'customer_profiles', count(*) from customer_profiles
union all
select 'catalogue_event_types', count(*) from catalogue_event_types
union all
select 'catalogue_segments', count(*) from catalogue_segments
union all
select 'catalogue_templates', count(*) from catalogue_templates
union all
select 'catalogue_endpoints', count(*) from catalogue_endpoints
union all
select 'cache_loader_connections', count(*) from cache_loader_connections
union all
select 'cache_loader_jobs', count(*) from cache_loader_jobs
union all
select 'cache_loader_runs', count(*) from cache_loader_runs;

prompt [5] sample read checks
select journey_id, version, status, updated_at
from journeys
fetch first 5 rows only;

select customer_id, segment, updated_at
from customer_profiles
fetch first 5 rows only;

select dataset_key, last_status, last_run_at
from cache_loader_jobs
fetch first 5 rows only;
