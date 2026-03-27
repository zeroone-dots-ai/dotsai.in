\set ON_ERROR_STOP on

CREATE SCHEMA IF NOT EXISTS calcom;
CREATE SCHEMA IF NOT EXISTS analytics;

DO $$
BEGIN
  ASSERT (SELECT COUNT(*) FROM information_schema.schemata
          WHERE schema_name IN ('calcom', 'analytics')) = 2,
         'Expected both calcom and analytics schemas to exist';
END $$;
