-- Eventra Oracle schema bootstrap
-- Bu dosya, uygulamanin Oracle ana veritabani uzerinde ihtiyac duydugu tablolarin
-- ilk kurulum iskeletini icerir. Uygulama tarafinda Oracle icin otomatik schema
-- bootstrap kapatilidir; bu script kontrollu sekilde DBA/ops tarafindan uygulanmalidir.

create table events (
  event_id varchar2(255) primary key,
  customer_id varchar2(255) not null,
  event_type varchar2(255) not null,
  ts timestamp not null,
  payload clob not null,
  source varchar2(255) not null
);

create index idx_events_customer_type_ts on events (customer_id, event_type, ts desc);
create index idx_events_customer_ts on events (customer_id, ts desc);

create table customer_profiles (
  customer_id varchar2(255) primary key,
  segment varchar2(255),
  attributes clob default '{}' not null,
  updated_at timestamp default current_timestamp not null
);

create table action_log (
  action_id varchar2(255) primary key,
  event_id varchar2(255) not null,
  customer_id varchar2(255) not null,
  journey_id varchar2(255),
  journey_version number(10),
  journey_node_id varchar2(255),
  channel varchar2(50) not null,
  status varchar2(50) not null,
  message clob not null,
  created_at timestamp default current_timestamp not null
);

create table external_call_log (
  id varchar2(255) primary key,
  instance_id varchar2(255) not null,
  journey_id varchar2(255) not null,
  journey_version number(10) not null,
  customer_id varchar2(255) not null,
  journey_node_id varchar2(255) not null,
  method varchar2(20) not null,
  url varchar2(2000) not null,
  status_code number(10) default 0 not null,
  result_type varchar2(100) not null,
  reason varchar2(4000) not null,
  response_json clob,
  created_at timestamp default current_timestamp not null
);

create index idx_external_call_log_lookup
  on external_call_log (journey_id, journey_version, customer_id, created_at desc);

create table journey_folders (
  folder_path varchar2(1000) primary key,
  created_at timestamp default current_timestamp not null
);

create table journeys (
  journey_id varchar2(255) not null,
  version number(10) not null,
  name varchar2(500) not null,
  status varchar2(50) default 'published' not null,
  folder_path varchar2(1000) default 'Workspace' not null,
  graph_json clob not null,
  created_at timestamp default current_timestamp not null,
  updated_at timestamp default current_timestamp not null,
  constraint pk_journeys primary key (journey_id, version)
);

create table journey_instances (
  instance_id varchar2(255) primary key,
  journey_id varchar2(255) not null,
  journey_version number(10) not null,
  customer_id varchar2(255) not null,
  state varchar2(50) not null,
  current_node varchar2(255) not null,
  started_at timestamp not null,
  due_at timestamp,
  completed_at timestamp,
  last_event_id varchar2(255),
  context_json clob default '{}' not null,
  created_at timestamp default current_timestamp not null,
  updated_at timestamp default current_timestamp not null
);

create unique index uq_journey_instance_active
  on journey_instances (
    case when state in ('waiting', 'waiting_manual', 'active', 'processing') then journey_id end,
    case when state in ('waiting', 'waiting_manual', 'active', 'processing') then customer_id end
  );

create index idx_journey_instances_due on journey_instances (state, due_at);
create index idx_journey_instances_journey_state_due
  on journey_instances (journey_id, state, due_at);
create index idx_journey_instances_customer_updated
  on journey_instances (customer_id, updated_at desc);
create index idx_journey_instances_updated on journey_instances (updated_at desc);

create table event_dlq (
  id varchar2(255) primary key,
  event_id varchar2(255),
  customer_id varchar2(255),
  event_type varchar2(255),
  source_topic varchar2(255) not null,
  error_message varchar2(4000) not null,
  raw_payload clob,
  created_at timestamp default current_timestamp not null
);

create index idx_event_dlq_created on event_dlq (created_at desc);

create table journey_instance_transitions (
  id varchar2(255) primary key,
  instance_id varchar2(255) not null,
  journey_id varchar2(255) not null,
  journey_version number(10) not null,
  customer_id varchar2(255) not null,
  from_state varchar2(50),
  to_state varchar2(50) not null,
  from_node varchar2(255),
  to_node varchar2(255),
  reason varchar2(255),
  event_id varchar2(255),
  metadata_json clob default '{}' not null,
  created_at timestamp default current_timestamp not null
);

create index idx_instance_transitions_lookup
  on journey_instance_transitions (instance_id, created_at desc);
create index idx_instance_transitions_customer
  on journey_instance_transitions (customer_id, created_at desc);

create table consumed_events (
  consumer_group varchar2(255) not null,
  event_id varchar2(255) not null,
  consumed_at timestamp default current_timestamp not null,
  constraint pk_consumed_events primary key (consumer_group, event_id)
);

create table edge_capacity_usage (
  journey_id varchar2(255) not null,
  journey_version number(10) not null,
  edge_id varchar2(255) not null,
  window_type varchar2(50) not null,
  window_start timestamp not null,
  used_count number(10) default 0 not null,
  updated_at timestamp default current_timestamp not null,
  constraint pk_edge_capacity_usage primary key (
    journey_id, journey_version, edge_id, window_type, window_start
  )
);

create index idx_edge_capacity_lookup
  on edge_capacity_usage (journey_id, journey_version, edge_id, window_type, window_start desc);

create table journey_release_controls (
  journey_id varchar2(255) not null,
  journey_version number(10) not null,
  rollout_percent number(10) default 100 not null,
  release_paused number(1) default 0 not null,
  updated_at timestamp default current_timestamp not null,
  constraint pk_journey_release_controls primary key (journey_id, journey_version)
);

create table journey_approvals (
  journey_id varchar2(255) not null,
  journey_version number(10) not null,
  state varchar2(50) not null,
  requested_by varchar2(255),
  requested_note clob default '',
  requested_at timestamp,
  reviewed_by varchar2(255),
  reviewed_note clob default '',
  reviewed_at timestamp,
  created_at timestamp default current_timestamp not null,
  updated_at timestamp default current_timestamp not null,
  constraint pk_journey_approvals primary key (journey_id, journey_version)
);

create index idx_journey_approvals_state_updated
  on journey_approvals (state, updated_at desc);

create table runtime_controls (
  key varchar2(255) primary key,
  value_json clob default '{}' not null,
  updated_at timestamp default current_timestamp not null
);

create table catalogue_event_types (
  event_type varchar2(255) primary key,
  description clob default '' not null,
  owner varchar2(255) default '' not null,
  version number(10) default 1 not null,
  required_fields clob default '[]' not null,
  schema_json clob default '{}' not null,
  sample_payload clob default '{}' not null,
  is_active number(1) default 1 not null,
  created_at timestamp default current_timestamp not null,
  updated_at timestamp default current_timestamp not null
);

create table catalogue_segments (
  segment_key varchar2(255) primary key,
  display_name varchar2(500) default '' not null,
  rule_expression clob default '' not null,
  description clob default '' not null,
  is_active number(1) default 1 not null,
  created_at timestamp default current_timestamp not null,
  updated_at timestamp default current_timestamp not null
);

create table catalogue_templates (
  template_id varchar2(255) primary key,
  channel varchar2(50) not null,
  subject varchar2(1000) default '' not null,
  body clob default '' not null,
  variables clob default '[]' not null,
  is_active number(1) default 1 not null,
  created_at timestamp default current_timestamp not null,
  updated_at timestamp default current_timestamp not null
);

create table catalogue_endpoints (
  endpoint_id varchar2(255) primary key,
  method varchar2(20) not null,
  url varchar2(2000) not null,
  headers clob default '{}' not null,
  timeout_ms number(10) default 5000 not null,
  description clob default '' not null,
  is_active number(1) default 1 not null,
  created_at timestamp default current_timestamp not null,
  updated_at timestamp default current_timestamp not null
);

create table edge_transition_log (
  id varchar2(255) primary key,
  journey_id varchar2(255) not null,
  journey_version number(10) not null,
  edge_id varchar2(255) not null,
  customer_id varchar2(255) not null,
  triggered_at timestamp default current_timestamp not null
);

create index idx_edge_transition_daily
  on edge_transition_log (journey_id, journey_version, edge_id, customer_id, triggered_at desc);

create table cache_loader_connections (
  id varchar2(255) primary key,
  name varchar2(255) not null,
  host varchar2(255) not null,
  port number(10) not null,
  database_name varchar2(255) not null,
  username varchar2(255) not null,
  password varchar2(1000) not null,
  ssl_enabled number(1) default 0 not null,
  driver varchar2(50) default 'oracle' not null,
  created_at timestamp default current_timestamp not null,
  updated_at timestamp default current_timestamp not null
);

create table cache_loader_jobs (
  id varchar2(255) primary key,
  name varchar2(255) not null,
  connection_id varchar2(255) not null,
  dataset_key varchar2(255) not null,
  sql_query clob not null,
  key_column varchar2(255) not null,
  run_time varchar2(20) not null,
  timezone varchar2(100) not null,
  enabled number(1) default 1 not null,
  last_run_at timestamp,
  last_status varchar2(50),
  last_error clob,
  created_at timestamp default current_timestamp not null,
  updated_at timestamp default current_timestamp not null,
  constraint fk_cache_loader_jobs_connection
    foreign key (connection_id) references cache_loader_connections(id)
);

create table cache_loader_runs (
  id varchar2(255) primary key,
  job_id varchar2(255) not null,
  started_at timestamp not null,
  finished_at timestamp,
  status varchar2(50) not null,
  row_count number(10) default 0 not null,
  error_text clob,
  constraint fk_cache_loader_runs_job
    foreign key (job_id) references cache_loader_jobs(id)
);

merge into runtime_controls rc
using (select 'global_pause' as key, '{"enabled": false}' as value_json from dual) src
on (rc.key = src.key)
when not matched then
  insert (key, value_json, updated_at)
  values (src.key, src.value_json, current_timestamp);
