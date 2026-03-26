CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS crm;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS analytics.user_agents (
  user_agent_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  raw_user_agent TEXT NOT NULL,
  browser_name TEXT,
  browser_version TEXT,
  os_name TEXT,
  os_version TEXT,
  device_type TEXT,
  device_vendor TEXT,
  device_model TEXT,
  is_bot BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (raw_user_agent)
);

CREATE TABLE IF NOT EXISTS analytics.geos (
  geo_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  country_code TEXT,
  country_name TEXT,
  region_name TEXT,
  city_name TEXT,
  timezone TEXT,
  asn TEXT,
  org_name TEXT,
  latitude NUMERIC(9, 6),
  longitude NUMERIC(9, 6),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (country_code, region_name, city_name, timezone, asn, org_name)
);

CREATE TABLE IF NOT EXISTS analytics.visitors (
  visitor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  anonymous_id TEXT NOT NULL UNIQUE,
  first_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  first_touch_id BIGINT,
  latest_touch_id BIGINT,
  latest_geo_id BIGINT REFERENCES analytics.geos (geo_id),
  latest_user_agent_id BIGINT REFERENCES analytics.user_agents (user_agent_id),
  is_known BOOLEAN NOT NULL DEFAULT FALSE,
  contact_id UUID,
  gpc BOOLEAN,
  do_not_track BOOLEAN,
  analytics_consent BOOLEAN,
  marketing_consent BOOLEAN,
  consent_updated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_visitors_last_seen_at
  ON analytics.visitors (last_seen_at DESC);

CREATE TABLE IF NOT EXISTS analytics.attribution_touches (
  touch_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  visitor_id UUID NOT NULL REFERENCES analytics.visitors (visitor_id) ON DELETE CASCADE,
  session_id UUID,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  touch_role TEXT NOT NULL DEFAULT 'session',
  landing_url TEXT,
  landing_path TEXT,
  referrer_url TEXT,
  referrer_domain TEXT,
  source TEXT,
  medium TEXT,
  campaign TEXT,
  term TEXT,
  content TEXT,
  gclid TEXT,
  gbraid TEXT,
  wbraid TEXT,
  fbclid TEXT,
  msclkid TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_attribution_touches_visitor
  ON analytics.attribution_touches (visitor_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_attribution_touches_campaign
  ON analytics.attribution_touches (source, medium, campaign, occurred_at DESC);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_visitors_first_touch'
      AND conrelid = 'analytics.visitors'::regclass
  ) THEN
    ALTER TABLE analytics.visitors
      ADD CONSTRAINT fk_visitors_first_touch
      FOREIGN KEY (first_touch_id) REFERENCES analytics.attribution_touches (touch_id)
      DEFERRABLE INITIALLY DEFERRED;
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_visitors_latest_touch'
      AND conrelid = 'analytics.visitors'::regclass
  ) THEN
    ALTER TABLE analytics.visitors
      ADD CONSTRAINT fk_visitors_latest_touch
      FOREIGN KEY (latest_touch_id) REFERENCES analytics.attribution_touches (touch_id)
      DEFERRABLE INITIALLY DEFERRED;
  END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS analytics.sessions (
  session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  visitor_id UUID NOT NULL REFERENCES analytics.visitors (visitor_id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at TIMESTAMPTZ,
  last_activity_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  entry_pageview_id BIGINT,
  exit_pageview_id BIGINT,
  entry_path TEXT,
  exit_path TEXT,
  landing_touch_id BIGINT REFERENCES analytics.attribution_touches (touch_id),
  geo_id BIGINT REFERENCES analytics.geos (geo_id),
  user_agent_id BIGINT REFERENCES analytics.user_agents (user_agent_id),
  ip_hash TEXT,
  ip_trunc INET,
  is_bot BOOLEAN NOT NULL DEFAULT FALSE,
  bot_classification TEXT,
  pageviews_count INTEGER NOT NULL DEFAULT 0,
  events_count INTEGER NOT NULL DEFAULT 0,
  engaged_seconds INTEGER NOT NULL DEFAULT 0,
  is_bounce BOOLEAN NOT NULL DEFAULT FALSE,
  converted BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sessions_visitor_started
  ON analytics.sessions (visitor_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_sessions_started_at
  ON analytics.sessions (started_at DESC);

CREATE INDEX IF NOT EXISTS idx_sessions_landing_touch
  ON analytics.sessions (landing_touch_id);

CREATE TABLE IF NOT EXISTS analytics.pageviews (
  pageview_id BIGINT GENERATED ALWAYS AS IDENTITY,
  session_id UUID NOT NULL REFERENCES analytics.sessions (session_id) ON DELETE CASCADE,
  visitor_id UUID NOT NULL REFERENCES analytics.visitors (visitor_id) ON DELETE CASCADE,
  request_id TEXT,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  page_url TEXT NOT NULL,
  path TEXT NOT NULL,
  query_string TEXT,
  title TEXT,
  referrer_url TEXT,
  referrer_domain TEXT,
  route_name TEXT,
  status_code INTEGER,
  is_entry BOOLEAN NOT NULL DEFAULT FALSE,
  is_exit BOOLEAN NOT NULL DEFAULT FALSE,
  scroll_max_pct SMALLINT,
  time_on_page_ms INTEGER,
  viewport_w INTEGER,
  viewport_h INTEGER,
  screen_w INTEGER,
  screen_h INTEGER,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (pageview_id, occurred_at)
) PARTITION BY RANGE (occurred_at);

CREATE TABLE IF NOT EXISTS analytics.pageviews_default
  PARTITION OF analytics.pageviews DEFAULT;

CREATE INDEX IF NOT EXISTS idx_pageviews_session_occurred
  ON analytics.pageviews_default (session_id, occurred_at);

CREATE INDEX IF NOT EXISTS idx_pageviews_path_occurred
  ON analytics.pageviews_default (path, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_pageviews_visitor_occurred
  ON analytics.pageviews_default (visitor_id, occurred_at DESC);

CREATE TABLE IF NOT EXISTS analytics.events (
  event_id BIGINT GENERATED ALWAYS AS IDENTITY,
  session_id UUID NOT NULL REFERENCES analytics.sessions (session_id) ON DELETE CASCADE,
  visitor_id UUID NOT NULL REFERENCES analytics.visitors (visitor_id) ON DELETE CASCADE,
  pageview_id BIGINT,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  event_name TEXT NOT NULL,
  event_category TEXT,
  path TEXT,
  element_type TEXT,
  element_label TEXT,
  element_id TEXT,
  element_href TEXT,
  section_name TEXT,
  value_numeric NUMERIC,
  value_text TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (event_id, occurred_at)
) PARTITION BY RANGE (occurred_at);

CREATE TABLE IF NOT EXISTS analytics.events_default
  PARTITION OF analytics.events DEFAULT;

CREATE INDEX IF NOT EXISTS idx_events_name_occurred
  ON analytics.events_default (event_name, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_events_session_occurred
  ON analytics.events_default (session_id, occurred_at);

CREATE INDEX IF NOT EXISTS idx_events_path_name_occurred
  ON analytics.events_default (path, event_name, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_events_payload_gin
  ON analytics.events_default USING GIN (payload);

CREATE TABLE IF NOT EXISTS analytics.web_vitals (
  web_vital_id BIGINT GENERATED ALWAYS AS IDENTITY,
  session_id UUID REFERENCES analytics.sessions (session_id) ON DELETE CASCADE,
  visitor_id UUID REFERENCES analytics.visitors (visitor_id) ON DELETE CASCADE,
  pageview_id BIGINT,
  measured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  path TEXT,
  metric_name TEXT NOT NULL,
  metric_value NUMERIC NOT NULL,
  metric_rating TEXT,
  navigation_type TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (web_vital_id, measured_at)
) PARTITION BY RANGE (measured_at);

CREATE TABLE IF NOT EXISTS analytics.web_vitals_default
  PARTITION OF analytics.web_vitals DEFAULT;

CREATE INDEX IF NOT EXISTS idx_web_vitals_path_metric
  ON analytics.web_vitals_default (path, metric_name, measured_at DESC);

CREATE TABLE IF NOT EXISTS analytics.js_errors (
  js_error_id BIGINT GENERATED ALWAYS AS IDENTITY,
  session_id UUID REFERENCES analytics.sessions (session_id) ON DELETE CASCADE,
  visitor_id UUID REFERENCES analytics.visitors (visitor_id) ON DELETE CASCADE,
  pageview_id BIGINT,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  path TEXT,
  message TEXT NOT NULL,
  source TEXT,
  line_no INTEGER,
  col_no INTEGER,
  stack TEXT,
  is_network_error BOOLEAN NOT NULL DEFAULT FALSE,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (js_error_id, occurred_at)
) PARTITION BY RANGE (occurred_at);

CREATE TABLE IF NOT EXISTS analytics.js_errors_default
  PARTITION OF analytics.js_errors DEFAULT;

CREATE INDEX IF NOT EXISTS idx_js_errors_path_occurred
  ON analytics.js_errors_default (path, occurred_at DESC);

CREATE TABLE IF NOT EXISTS analytics.consent_events (
  consent_event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  visitor_id UUID NOT NULL REFERENCES analytics.visitors (visitor_id) ON DELETE CASCADE,
  session_id UUID REFERENCES analytics.sessions (session_id) ON DELETE SET NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  consent_version TEXT NOT NULL,
  analytics_consent BOOLEAN,
  marketing_consent BOOLEAN,
  preferences_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  source TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_consent_events_visitor_occurred
  ON analytics.consent_events (visitor_id, occurred_at DESC);

CREATE TABLE IF NOT EXISTS crm.contact_identities (
  contact_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  visitor_id UUID REFERENCES analytics.visitors (visitor_id) ON DELETE SET NULL,
  session_id UUID REFERENCES analytics.sessions (session_id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  email TEXT,
  email_sha256 TEXT,
  phone TEXT,
  phone_sha256 TEXT,
  full_name TEXT,
  company_name TEXT,
  job_title TEXT,
  source_form TEXT,
  consent_version TEXT,
  notes JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_contact_identities_visitor
  ON crm.contact_identities (visitor_id);

CREATE INDEX IF NOT EXISTS idx_contact_identities_email_sha256
  ON crm.contact_identities (email_sha256);

CREATE INDEX IF NOT EXISTS idx_contact_identities_phone_sha256
  ON crm.contact_identities (phone_sha256);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_visitors_contact'
      AND conrelid = 'analytics.visitors'::regclass
  ) THEN
    ALTER TABLE analytics.visitors
      ADD CONSTRAINT fk_visitors_contact
      FOREIGN KEY (contact_id) REFERENCES crm.contact_identities (contact_id)
      DEFERRABLE INITIALLY DEFERRED;
  END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS analytics.request_logs (
  request_log_id BIGINT GENERATED ALWAYS AS IDENTITY,
  request_id TEXT,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  remote_addr INET,
  ip_hash TEXT,
  host TEXT NOT NULL,
  method TEXT NOT NULL,
  scheme TEXT NOT NULL,
  path TEXT NOT NULL,
  query_string TEXT,
  status_code INTEGER NOT NULL,
  request_time_ms INTEGER,
  bytes_sent BIGINT,
  referer TEXT,
  user_agent TEXT,
  accept_language TEXT,
  server_protocol TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (request_log_id, requested_at)
) PARTITION BY RANGE (requested_at);

CREATE TABLE IF NOT EXISTS analytics.request_logs_default
  PARTITION OF analytics.request_logs DEFAULT;

CREATE INDEX IF NOT EXISTS idx_request_logs_requested_at
  ON analytics.request_logs_default (requested_at DESC);

CREATE INDEX IF NOT EXISTS idx_request_logs_path_status
  ON analytics.request_logs_default (path, status_code, requested_at DESC);

CREATE OR REPLACE FUNCTION analytics.touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_visitors_updated_at ON analytics.visitors;
CREATE TRIGGER trg_visitors_updated_at
BEFORE UPDATE ON analytics.visitors
FOR EACH ROW
EXECUTE FUNCTION analytics.touch_updated_at();

DROP TRIGGER IF EXISTS trg_sessions_updated_at ON analytics.sessions;
CREATE TRIGGER trg_sessions_updated_at
BEFORE UPDATE ON analytics.sessions
FOR EACH ROW
EXECUTE FUNCTION analytics.touch_updated_at();

DROP TRIGGER IF EXISTS trg_contact_identities_updated_at ON crm.contact_identities;
CREATE TRIGGER trg_contact_identities_updated_at
BEFORE UPDATE ON crm.contact_identities
FOR EACH ROW
EXECUTE FUNCTION analytics.touch_updated_at();

CREATE OR REPLACE FUNCTION analytics.ensure_monthly_partition(
  parent_table TEXT,
  month_start DATE
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  parent_schema TEXT;
  parent_name TEXT;
  partition_name TEXT;
  range_start TIMESTAMPTZ;
  range_end TIMESTAMPTZ;
BEGIN
  parent_schema := split_part(parent_table, '.', 1);
  parent_name := split_part(parent_table, '.', 2);

  IF parent_schema = '' OR parent_name = '' THEN
    RAISE EXCEPTION 'parent_table must be schema-qualified, got %', parent_table;
  END IF;

  range_start := date_trunc('month', month_start::timestamp);
  range_end := range_start + INTERVAL '1 month';
  partition_name := format('%s_%s', parent_name, to_char(range_start, 'YYYY_MM'));

  EXECUTE format(
    'CREATE TABLE IF NOT EXISTS %I.%I PARTITION OF %I.%I FOR VALUES FROM (%L) TO (%L)',
    parent_schema,
    partition_name,
    parent_schema,
    parent_name,
    range_start,
    range_end
  );

  IF parent_name = 'pageviews' THEN
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS %I ON %I.%I (session_id, occurred_at)',
      partition_name || '_session_occurred_idx',
      parent_schema,
      partition_name
    );
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS %I ON %I.%I (path, occurred_at DESC)',
      partition_name || '_path_occurred_idx',
      parent_schema,
      partition_name
    );
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS %I ON %I.%I (visitor_id, occurred_at DESC)',
      partition_name || '_visitor_occurred_idx',
      parent_schema,
      partition_name
    );
  ELSIF parent_name = 'events' THEN
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS %I ON %I.%I (event_name, occurred_at DESC)',
      partition_name || '_name_occurred_idx',
      parent_schema,
      partition_name
    );
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS %I ON %I.%I (session_id, occurred_at)',
      partition_name || '_session_occurred_idx',
      parent_schema,
      partition_name
    );
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS %I ON %I.%I (path, event_name, occurred_at DESC)',
      partition_name || '_path_name_occurred_idx',
      parent_schema,
      partition_name
    );
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS %I ON %I.%I USING GIN (payload)',
      partition_name || '_payload_gin_idx',
      parent_schema,
      partition_name
    );
  ELSIF parent_name = 'web_vitals' THEN
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS %I ON %I.%I (path, metric_name, measured_at DESC)',
      partition_name || '_path_metric_idx',
      parent_schema,
      partition_name
    );
  ELSIF parent_name = 'js_errors' THEN
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS %I ON %I.%I (path, occurred_at DESC)',
      partition_name || '_path_occurred_idx',
      parent_schema,
      partition_name
    );
  ELSIF parent_name = 'request_logs' THEN
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS %I ON %I.%I (requested_at DESC)',
      partition_name || '_requested_at_idx',
      parent_schema,
      partition_name
    );
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS %I ON %I.%I (path, status_code, requested_at DESC)',
      partition_name || '_path_status_idx',
      parent_schema,
      partition_name
    );
  END IF;
END;
$$;

SELECT analytics.ensure_monthly_partition(
  'analytics.pageviews',
  (date_trunc('month', now()) + make_interval(months => month_offset))::date
)
FROM generate_series(-1, 2) AS month_offsets(month_offset);

SELECT analytics.ensure_monthly_partition(
  'analytics.events',
  (date_trunc('month', now()) + make_interval(months => month_offset))::date
)
FROM generate_series(-1, 2) AS month_offsets(month_offset);

SELECT analytics.ensure_monthly_partition(
  'analytics.web_vitals',
  (date_trunc('month', now()) + make_interval(months => month_offset))::date
)
FROM generate_series(-1, 2) AS month_offsets(month_offset);

SELECT analytics.ensure_monthly_partition(
  'analytics.js_errors',
  (date_trunc('month', now()) + make_interval(months => month_offset))::date
)
FROM generate_series(-1, 2) AS month_offsets(month_offset);

SELECT analytics.ensure_monthly_partition(
  'analytics.request_logs',
  (date_trunc('month', now()) + make_interval(months => month_offset))::date
)
FROM generate_series(-1, 2) AS month_offsets(month_offset);
