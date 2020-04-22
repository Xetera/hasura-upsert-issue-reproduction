CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- fuzzy search for hasura graphql function
CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- query analytics extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
--
-- PostgreSQL database dump
--

-- Dumped from database version 12.2 (Debian 12.2-2.pgdg100+1)
-- Dumped by pg_dump version 12.2 (Debian 12.2-2.pgdg100+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: hdb_catalog; Type: SCHEMA; Schema: -; Owner: test
--

CREATE SCHEMA hdb_catalog;


ALTER SCHEMA hdb_catalog OWNER TO test;

--
-- Name: hdb_views; Type: SCHEMA; Schema: -; Owner: test
--

CREATE SCHEMA hdb_views;


ALTER SCHEMA hdb_views OWNER TO test;

--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: check_violation(text); Type: FUNCTION; Schema: hdb_catalog; Owner: test
--

CREATE FUNCTION hdb_catalog.check_violation(msg text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
  BEGIN
    RAISE check_violation USING message=msg;
  END;
$$;


ALTER FUNCTION hdb_catalog.check_violation(msg text) OWNER TO test;

--
-- Name: hdb_schema_update_event_notifier(); Type: FUNCTION; Schema: hdb_catalog; Owner: test
--

CREATE FUNCTION hdb_catalog.hdb_schema_update_event_notifier() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    instance_id uuid;
    occurred_at timestamptz;
    invalidations json;
    curr_rec record;
  BEGIN
    instance_id = NEW.instance_id;
    occurred_at = NEW.occurred_at;
    invalidations = NEW.invalidations;
    PERFORM pg_notify('hasura_schema_update', json_build_object(
      'instance_id', instance_id,
      'occurred_at', occurred_at,
      'invalidations', invalidations
      )::text);
    RETURN curr_rec;
  END;
$$;


ALTER FUNCTION hdb_catalog.hdb_schema_update_event_notifier() OWNER TO test;

--
-- Name: inject_table_defaults(text, text, text, text); Type: FUNCTION; Schema: hdb_catalog; Owner: test
--

CREATE FUNCTION hdb_catalog.inject_table_defaults(view_schema text, view_name text, tab_schema text, tab_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE
        r RECORD;
    BEGIN
      FOR r IN SELECT column_name, column_default FROM information_schema.columns WHERE table_schema = tab_schema AND table_name = tab_name AND column_default IS NOT NULL LOOP
          EXECUTE format('ALTER VIEW %I.%I ALTER COLUMN %I SET DEFAULT %s;', view_schema, view_name, r.column_name, r.column_default);
      END LOOP;
    END;
$$;


ALTER FUNCTION hdb_catalog.inject_table_defaults(view_schema text, view_name text, tab_schema text, tab_name text) OWNER TO test;

--
-- Name: insert_event_log(text, text, text, text, json); Type: FUNCTION; Schema: hdb_catalog; Owner: test
--

CREATE FUNCTION hdb_catalog.insert_event_log(schema_name text, table_name text, trigger_name text, op text, row_data json) RETURNS text
    LANGUAGE plpgsql
    AS $$
  DECLARE
    id text;
    payload json;
    session_variables json;
    server_version_num int;
  BEGIN
    id := gen_random_uuid();
    server_version_num := current_setting('server_version_num');
    IF server_version_num >= 90600 THEN
      session_variables := current_setting('hasura.user', 't');
    ELSE
      BEGIN
        session_variables := current_setting('hasura.user');
      EXCEPTION WHEN OTHERS THEN
                  session_variables := NULL;
      END;
    END IF;
    payload := json_build_object(
      'op', op,
      'data', row_data,
      'session_variables', session_variables
    );
    INSERT INTO hdb_catalog.event_log
                (id, schema_name, table_name, trigger_name, payload)
    VALUES
    (id, schema_name, table_name, trigger_name, payload);
    RETURN id;
  END;
$$;


ALTER FUNCTION hdb_catalog.insert_event_log(schema_name text, table_name text, trigger_name text, op text, row_data json) OWNER TO test;

--
-- Name: group_member_status(date, date); Type: FUNCTION; Schema: public; Owner: test
--

CREATE FUNCTION public.group_member_status(date, date) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
DECLARE
  today DATE := CURRENT_DATE;
  is_leaving BOOLEAN := $2 IS NOT NULL;
BEGIN
  CASE
    WHEN is_leaving AND ($2 > today)  THEN RETURN 'DEPARTING';
    WHEN is_leaving AND ($2 <= today) THEN RETURN 'DEPARTED';
    WHEN $1 <= today THEN RETURN 'ACTIVE';
    WHEN $1 > today  THEN RETURN 'PRE_DEBUT';
    ELSE RETURN 'PRE_DEBUT';
  END CASE;
END;
$_$;


ALTER FUNCTION public.group_member_status(date, date) OWNER TO test;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: idols; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.idols (
    full_name text,
    native_name text,
    birth_date date,
    gender text,
    country_of_origin text,
    stage_name text,
    id integer NOT NULL,
    twitter text,
    instagram text,
    height integer,
    image text,
    banner text,
    melon_id integer,
    description text,
    zodiac_sign text,
    korean_stage_name text,
    birth_city text,
    weight integer,
    thumbnail text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.idols OWNER TO test;

--
-- Name: TABLE idols; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TABLE public.idols IS 'An artist who is or has been a part of a group or solo project';


--
-- Name: idol_age(public.idols); Type: FUNCTION; Schema: public; Owner: test
--

CREATE FUNCTION public.idol_age(i public.idols) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
        BEGIN
                RETURN DATE_PART('year', AGE(NOW()::date, i.birth_date));
        END;
$$;


ALTER FUNCTION public.idol_age(i public.idols) OWNER TO test;

--
-- Name: groups; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.groups (
    name text NOT NULL,
    korean_name text NOT NULL,
    debut date NOT NULL,
    original_member_count integer,
    company_name text NOT NULL,
    fandom_name text,
    status text NOT NULL,
    image text,
    banner text,
    id integer NOT NULL,
    parent_group_id integer,
    spotify_id text,
    youtube_id text,
    vlive_id text,
    twitter_handle text,
    instagram_username text,
    fan_cafe_id text,
    melon_id integer,
    type text,
    description text,
    discord_server_id text,
    banner_text text,
    gender text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.groups OWNER TO test;

--
-- Name: is_subunit(public.groups); Type: FUNCTION; Schema: public; Owner: test
--

CREATE FUNCTION public.is_subunit(public.groups) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT $1.parent_group_id IS NOT NULL;
$_$;


ALTER FUNCTION public.is_subunit(public.groups) OWNER TO test;

--
-- Name: search_group(text); Type: FUNCTION; Schema: public; Owner: test
--

CREATE FUNCTION public.search_group(search text) RETURNS SETOF public.groups
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT groups.*
  FROM groups
  JOIN group_aliases ON groups.id = group_aliases.group_id
  ORDER BY (
    search <-> concat_ws(' ', groups.name, groups.fandom_name, group_aliases.alias)
  ) ASC;
$$;


ALTER FUNCTION public.search_group(search text) OWNER TO test;

--
-- Name: set_current_timestamp_updated_at(); Type: FUNCTION; Schema: public; Owner: test
--

CREATE FUNCTION public.set_current_timestamp_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _new record;
BEGIN
  _new := NEW;
  _new."updated_at" = NOW();
  RETURN _new;
END;
$$;


ALTER FUNCTION public.set_current_timestamp_updated_at() OWNER TO test;

--
-- Name: years_since(date); Type: FUNCTION; Schema: public; Owner: test
--

CREATE FUNCTION public.years_since(d date) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
        BEGIN
                RETURN DATE_PART('year', AGE(NOW()::date, d));
        END;
$$;


ALTER FUNCTION public.years_since(d date) OWNER TO test;

--
-- Name: event_invocation_logs; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.event_invocation_logs (
    id text DEFAULT public.gen_random_uuid() NOT NULL,
    event_id text,
    status integer,
    request json,
    response json,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE hdb_catalog.event_invocation_logs OWNER TO test;

--
-- Name: event_log; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.event_log (
    id text DEFAULT public.gen_random_uuid() NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    trigger_name text NOT NULL,
    payload jsonb NOT NULL,
    delivered boolean DEFAULT false NOT NULL,
    error boolean DEFAULT false NOT NULL,
    tries integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    locked boolean DEFAULT false NOT NULL,
    next_retry_at timestamp without time zone,
    archived boolean DEFAULT false NOT NULL
);


ALTER TABLE hdb_catalog.event_log OWNER TO test;

--
-- Name: event_triggers; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.event_triggers (
    name text NOT NULL,
    type text NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    configuration json,
    comment text
);


ALTER TABLE hdb_catalog.event_triggers OWNER TO test;

--
-- Name: hdb_action; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.hdb_action (
    action_name text NOT NULL,
    action_defn jsonb NOT NULL,
    comment text,
    is_system_defined boolean DEFAULT false
);


ALTER TABLE hdb_catalog.hdb_action OWNER TO test;

--
-- Name: hdb_action_log; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.hdb_action_log (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    action_name text,
    input_payload jsonb NOT NULL,
    request_headers jsonb NOT NULL,
    session_variables jsonb NOT NULL,
    response_payload jsonb,
    errors jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    response_received_at timestamp with time zone,
    status text NOT NULL,
    CONSTRAINT hdb_action_log_status_check CHECK ((status = ANY (ARRAY['created'::text, 'processing'::text, 'completed'::text, 'error'::text])))
);


ALTER TABLE hdb_catalog.hdb_action_log OWNER TO test;

--
-- Name: hdb_action_permission; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.hdb_action_permission (
    action_name text NOT NULL,
    role_name text NOT NULL,
    definition jsonb DEFAULT '{}'::jsonb NOT NULL,
    comment text
);


ALTER TABLE hdb_catalog.hdb_action_permission OWNER TO test;

--
-- Name: hdb_allowlist; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.hdb_allowlist (
    collection_name text
);


ALTER TABLE hdb_catalog.hdb_allowlist OWNER TO test;

--
-- Name: hdb_check_constraint; Type: VIEW; Schema: hdb_catalog; Owner: test
--

CREATE VIEW hdb_catalog.hdb_check_constraint AS
 SELECT (n.nspname)::text AS table_schema,
    (ct.relname)::text AS table_name,
    (r.conname)::text AS constraint_name,
    pg_get_constraintdef(r.oid, true) AS "check"
   FROM ((pg_constraint r
     JOIN pg_class ct ON ((r.conrelid = ct.oid)))
     JOIN pg_namespace n ON ((ct.relnamespace = n.oid)))
  WHERE (r.contype = 'c'::"char");


ALTER TABLE hdb_catalog.hdb_check_constraint OWNER TO test;

--
-- Name: hdb_computed_field; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.hdb_computed_field (
    table_schema text NOT NULL,
    table_name text NOT NULL,
    computed_field_name text NOT NULL,
    definition jsonb NOT NULL,
    comment text
);


ALTER TABLE hdb_catalog.hdb_computed_field OWNER TO test;

--
-- Name: hdb_computed_field_function; Type: VIEW; Schema: hdb_catalog; Owner: test
--

CREATE VIEW hdb_catalog.hdb_computed_field_function AS
 SELECT hdb_computed_field.table_schema,
    hdb_computed_field.table_name,
    hdb_computed_field.computed_field_name,
        CASE
            WHEN (((hdb_computed_field.definition -> 'function'::text) ->> 'name'::text) IS NULL) THEN (hdb_computed_field.definition ->> 'function'::text)
            ELSE ((hdb_computed_field.definition -> 'function'::text) ->> 'name'::text)
        END AS function_name,
        CASE
            WHEN (((hdb_computed_field.definition -> 'function'::text) ->> 'schema'::text) IS NULL) THEN 'public'::text
            ELSE ((hdb_computed_field.definition -> 'function'::text) ->> 'schema'::text)
        END AS function_schema
   FROM hdb_catalog.hdb_computed_field;


ALTER TABLE hdb_catalog.hdb_computed_field_function OWNER TO test;

--
-- Name: hdb_custom_types; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.hdb_custom_types (
    custom_types jsonb NOT NULL
);


ALTER TABLE hdb_catalog.hdb_custom_types OWNER TO test;

--
-- Name: hdb_foreign_key_constraint; Type: VIEW; Schema: hdb_catalog; Owner: test
--

CREATE VIEW hdb_catalog.hdb_foreign_key_constraint AS
 SELECT (q.table_schema)::text AS table_schema,
    (q.table_name)::text AS table_name,
    (q.constraint_name)::text AS constraint_name,
    (min(q.constraint_oid))::integer AS constraint_oid,
    min((q.ref_table_table_schema)::text) AS ref_table_table_schema,
    min((q.ref_table)::text) AS ref_table,
    json_object_agg(ac.attname, afc.attname) AS column_mapping,
    min((q.confupdtype)::text) AS on_update,
    min((q.confdeltype)::text) AS on_delete,
    json_agg(ac.attname) AS columns,
    json_agg(afc.attname) AS ref_columns
   FROM ((( SELECT ctn.nspname AS table_schema,
            ct.relname AS table_name,
            r.conrelid AS table_id,
            r.conname AS constraint_name,
            r.oid AS constraint_oid,
            cftn.nspname AS ref_table_table_schema,
            cft.relname AS ref_table,
            r.confrelid AS ref_table_id,
            r.confupdtype,
            r.confdeltype,
            unnest(r.conkey) AS column_id,
            unnest(r.confkey) AS ref_column_id
           FROM ((((pg_constraint r
             JOIN pg_class ct ON ((r.conrelid = ct.oid)))
             JOIN pg_namespace ctn ON ((ct.relnamespace = ctn.oid)))
             JOIN pg_class cft ON ((r.confrelid = cft.oid)))
             JOIN pg_namespace cftn ON ((cft.relnamespace = cftn.oid)))
          WHERE (r.contype = 'f'::"char")) q
     JOIN pg_attribute ac ON (((q.column_id = ac.attnum) AND (q.table_id = ac.attrelid))))
     JOIN pg_attribute afc ON (((q.ref_column_id = afc.attnum) AND (q.ref_table_id = afc.attrelid))))
  GROUP BY q.table_schema, q.table_name, q.constraint_name;


ALTER TABLE hdb_catalog.hdb_foreign_key_constraint OWNER TO test;

--
-- Name: hdb_function; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.hdb_function (
    function_schema text NOT NULL,
    function_name text NOT NULL,
    configuration jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_system_defined boolean DEFAULT false
);


ALTER TABLE hdb_catalog.hdb_function OWNER TO test;

--
-- Name: hdb_function_agg; Type: VIEW; Schema: hdb_catalog; Owner: test
--

CREATE VIEW hdb_catalog.hdb_function_agg AS
 SELECT (p.proname)::text AS function_name,
    (pn.nspname)::text AS function_schema,
    pd.description,
        CASE
            WHEN (p.provariadic = (0)::oid) THEN false
            ELSE true
        END AS has_variadic,
        CASE
            WHEN ((p.provolatile)::text = ('i'::character(1))::text) THEN 'IMMUTABLE'::text
            WHEN ((p.provolatile)::text = ('s'::character(1))::text) THEN 'STABLE'::text
            WHEN ((p.provolatile)::text = ('v'::character(1))::text) THEN 'VOLATILE'::text
            ELSE NULL::text
        END AS function_type,
    pg_get_functiondef(p.oid) AS function_definition,
    (rtn.nspname)::text AS return_type_schema,
    (rt.typname)::text AS return_type_name,
    (rt.typtype)::text AS return_type_type,
    p.proretset AS returns_set,
    ( SELECT COALESCE(json_agg(json_build_object('schema', q.schema, 'name', q.name, 'type', q.type)), '[]'::json) AS "coalesce"
           FROM ( SELECT pt.typname AS name,
                    pns.nspname AS schema,
                    pt.typtype AS type,
                    pat.ordinality
                   FROM ((unnest(COALESCE(p.proallargtypes, (p.proargtypes)::oid[])) WITH ORDINALITY pat(oid, ordinality)
                     LEFT JOIN pg_type pt ON ((pt.oid = pat.oid)))
                     LEFT JOIN pg_namespace pns ON ((pt.typnamespace = pns.oid)))
                  ORDER BY pat.ordinality) q) AS input_arg_types,
    to_json(COALESCE(p.proargnames, ARRAY[]::text[])) AS input_arg_names,
    p.pronargdefaults AS default_args,
    (p.oid)::integer AS function_oid
   FROM ((((pg_proc p
     JOIN pg_namespace pn ON ((pn.oid = p.pronamespace)))
     JOIN pg_type rt ON ((rt.oid = p.prorettype)))
     JOIN pg_namespace rtn ON ((rtn.oid = rt.typnamespace)))
     LEFT JOIN pg_description pd ON ((p.oid = pd.objoid)))
  WHERE (((pn.nspname)::text !~~ 'pg_%'::text) AND ((pn.nspname)::text <> ALL (ARRAY['information_schema'::text, 'hdb_catalog'::text, 'hdb_views'::text])) AND (NOT (EXISTS ( SELECT 1
           FROM pg_aggregate
          WHERE ((pg_aggregate.aggfnoid)::oid = p.oid)))));


ALTER TABLE hdb_catalog.hdb_function_agg OWNER TO test;

--
-- Name: hdb_function_info_agg; Type: VIEW; Schema: hdb_catalog; Owner: test
--

CREATE VIEW hdb_catalog.hdb_function_info_agg AS
 SELECT hdb_function_agg.function_name,
    hdb_function_agg.function_schema,
    row_to_json(( SELECT e.*::record AS e
           FROM ( SELECT hdb_function_agg.description,
                    hdb_function_agg.has_variadic,
                    hdb_function_agg.function_type,
                    hdb_function_agg.return_type_schema,
                    hdb_function_agg.return_type_name,
                    hdb_function_agg.return_type_type,
                    hdb_function_agg.returns_set,
                    hdb_function_agg.input_arg_types,
                    hdb_function_agg.input_arg_names,
                    hdb_function_agg.default_args,
                    (EXISTS ( SELECT 1
                           FROM information_schema.tables
                          WHERE (((tables.table_schema)::name = hdb_function_agg.return_type_schema) AND ((tables.table_name)::name = hdb_function_agg.return_type_name)))) AS returns_table) e)) AS function_info
   FROM hdb_catalog.hdb_function_agg;


ALTER TABLE hdb_catalog.hdb_function_info_agg OWNER TO test;

--
-- Name: hdb_permission; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.hdb_permission (
    table_schema name NOT NULL,
    table_name name NOT NULL,
    role_name text NOT NULL,
    perm_type text NOT NULL,
    perm_def jsonb NOT NULL,
    comment text,
    is_system_defined boolean DEFAULT false,
    CONSTRAINT hdb_permission_perm_type_check CHECK ((perm_type = ANY (ARRAY['insert'::text, 'select'::text, 'update'::text, 'delete'::text])))
);


ALTER TABLE hdb_catalog.hdb_permission OWNER TO test;

--
-- Name: hdb_permission_agg; Type: VIEW; Schema: hdb_catalog; Owner: test
--

CREATE VIEW hdb_catalog.hdb_permission_agg AS
 SELECT hdb_permission.table_schema,
    hdb_permission.table_name,
    hdb_permission.role_name,
    json_object_agg(hdb_permission.perm_type, hdb_permission.perm_def) AS permissions
   FROM hdb_catalog.hdb_permission
  GROUP BY hdb_permission.table_schema, hdb_permission.table_name, hdb_permission.role_name;


ALTER TABLE hdb_catalog.hdb_permission_agg OWNER TO test;

--
-- Name: hdb_primary_key; Type: VIEW; Schema: hdb_catalog; Owner: test
--

CREATE VIEW hdb_catalog.hdb_primary_key AS
 SELECT tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    json_agg(constraint_column_usage.column_name) AS columns
   FROM (information_schema.table_constraints tc
     JOIN ( SELECT x.tblschema AS table_schema,
            x.tblname AS table_name,
            x.colname AS column_name,
            x.cstrname AS constraint_name
           FROM ( SELECT DISTINCT nr.nspname,
                    r.relname,
                    a.attname,
                    c.conname
                   FROM pg_namespace nr,
                    pg_class r,
                    pg_attribute a,
                    pg_depend d,
                    pg_namespace nc,
                    pg_constraint c
                  WHERE ((nr.oid = r.relnamespace) AND (r.oid = a.attrelid) AND (d.refclassid = ('pg_class'::regclass)::oid) AND (d.refobjid = r.oid) AND (d.refobjsubid = a.attnum) AND (d.classid = ('pg_constraint'::regclass)::oid) AND (d.objid = c.oid) AND (c.connamespace = nc.oid) AND (c.contype = 'c'::"char") AND (r.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])) AND (NOT a.attisdropped))
                UNION ALL
                 SELECT nr.nspname,
                    r.relname,
                    a.attname,
                    c.conname
                   FROM pg_namespace nr,
                    pg_class r,
                    pg_attribute a,
                    pg_namespace nc,
                    pg_constraint c
                  WHERE ((nr.oid = r.relnamespace) AND (r.oid = a.attrelid) AND (nc.oid = c.connamespace) AND (r.oid =
                        CASE c.contype
                            WHEN 'f'::"char" THEN c.confrelid
                            ELSE c.conrelid
                        END) AND (a.attnum = ANY (
                        CASE c.contype
                            WHEN 'f'::"char" THEN c.confkey
                            ELSE c.conkey
                        END)) AND (NOT a.attisdropped) AND (c.contype = ANY (ARRAY['p'::"char", 'u'::"char", 'f'::"char"])) AND (r.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])))) x(tblschema, tblname, colname, cstrname)) constraint_column_usage ON ((((tc.constraint_name)::text = (constraint_column_usage.constraint_name)::text) AND ((tc.table_schema)::text = (constraint_column_usage.table_schema)::text) AND ((tc.table_name)::text = (constraint_column_usage.table_name)::text))))
  WHERE ((tc.constraint_type)::text = 'PRIMARY KEY'::text)
  GROUP BY tc.table_schema, tc.table_name, tc.constraint_name;


ALTER TABLE hdb_catalog.hdb_primary_key OWNER TO test;

--
-- Name: hdb_query_collection; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.hdb_query_collection (
    collection_name text NOT NULL,
    collection_defn jsonb NOT NULL,
    comment text,
    is_system_defined boolean DEFAULT false
);


ALTER TABLE hdb_catalog.hdb_query_collection OWNER TO test;

--
-- Name: hdb_relationship; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.hdb_relationship (
    table_schema name NOT NULL,
    table_name name NOT NULL,
    rel_name text NOT NULL,
    rel_type text,
    rel_def jsonb NOT NULL,
    comment text,
    is_system_defined boolean DEFAULT false,
    CONSTRAINT hdb_relationship_rel_type_check CHECK ((rel_type = ANY (ARRAY['object'::text, 'array'::text])))
);


ALTER TABLE hdb_catalog.hdb_relationship OWNER TO test;

--
-- Name: hdb_role; Type: VIEW; Schema: hdb_catalog; Owner: test
--

CREATE VIEW hdb_catalog.hdb_role AS
 SELECT DISTINCT q.role_name
   FROM ( SELECT hdb_permission.role_name
           FROM hdb_catalog.hdb_permission
        UNION ALL
         SELECT hdb_action_permission.role_name
           FROM hdb_catalog.hdb_action_permission) q;


ALTER TABLE hdb_catalog.hdb_role OWNER TO test;

--
-- Name: hdb_schema_update_event; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.hdb_schema_update_event (
    instance_id uuid NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    invalidations json NOT NULL
);


ALTER TABLE hdb_catalog.hdb_schema_update_event OWNER TO test;

--
-- Name: hdb_table; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.hdb_table (
    table_schema name NOT NULL,
    table_name name NOT NULL,
    configuration jsonb,
    is_system_defined boolean DEFAULT false,
    is_enum boolean DEFAULT false NOT NULL
);


ALTER TABLE hdb_catalog.hdb_table OWNER TO test;

--
-- Name: hdb_table_info_agg; Type: VIEW; Schema: hdb_catalog; Owner: test
--

CREATE VIEW hdb_catalog.hdb_table_info_agg AS
 SELECT schema.nspname AS table_schema,
    "table".relname AS table_name,
    jsonb_build_object('oid', ("table".oid)::integer, 'columns', COALESCE(columns.info, '[]'::jsonb), 'primary_key', primary_key.info, 'unique_constraints', COALESCE(unique_constraints.info, '[]'::jsonb), 'foreign_keys', COALESCE(foreign_key_constraints.info, '[]'::jsonb), 'view_info',
        CASE "table".relkind
            WHEN 'v'::"char" THEN jsonb_build_object('is_updatable', ((pg_relation_is_updatable(("table".oid)::regclass, true) & 4) = 4), 'is_insertable', ((pg_relation_is_updatable(("table".oid)::regclass, true) & 8) = 8), 'is_deletable', ((pg_relation_is_updatable(("table".oid)::regclass, true) & 16) = 16))
            ELSE NULL::jsonb
        END, 'description', description.description) AS info
   FROM ((((((pg_class "table"
     JOIN pg_namespace schema ON ((schema.oid = "table".relnamespace)))
     LEFT JOIN pg_description description ON (((description.classoid = ('pg_class'::regclass)::oid) AND (description.objoid = "table".oid) AND (description.objsubid = 0))))
     LEFT JOIN LATERAL ( SELECT jsonb_agg(jsonb_build_object('name', "column".attname, 'position', "column".attnum, 'type', COALESCE(base_type.typname, type.typname), 'is_nullable', (NOT "column".attnotnull), 'description', col_description("table".oid, ("column".attnum)::integer))) AS info
           FROM ((pg_attribute "column"
             LEFT JOIN pg_type type ON ((type.oid = "column".atttypid)))
             LEFT JOIN pg_type base_type ON (((type.typtype = 'd'::"char") AND (base_type.oid = type.typbasetype))))
          WHERE (("column".attrelid = "table".oid) AND ("column".attnum > 0) AND (NOT "column".attisdropped))) columns ON (true))
     LEFT JOIN LATERAL ( SELECT jsonb_build_object('constraint', jsonb_build_object('name', class.relname, 'oid', (class.oid)::integer), 'columns', COALESCE(columns_1.info, '[]'::jsonb)) AS info
           FROM ((pg_index index
             JOIN pg_class class ON ((class.oid = index.indexrelid)))
             LEFT JOIN LATERAL ( SELECT jsonb_agg("column".attname) AS info
                   FROM pg_attribute "column"
                  WHERE (("column".attrelid = "table".oid) AND ("column".attnum = ANY ((index.indkey)::smallint[])))) columns_1 ON (true))
          WHERE ((index.indrelid = "table".oid) AND index.indisprimary)) primary_key ON (true))
     LEFT JOIN LATERAL ( SELECT jsonb_agg(jsonb_build_object('name', class.relname, 'oid', (class.oid)::integer)) AS info
           FROM (pg_index index
             JOIN pg_class class ON ((class.oid = index.indexrelid)))
          WHERE ((index.indrelid = "table".oid) AND index.indisunique AND (NOT index.indisprimary))) unique_constraints ON (true))
     LEFT JOIN LATERAL ( SELECT jsonb_agg(jsonb_build_object('constraint', jsonb_build_object('name', foreign_key.constraint_name, 'oid', foreign_key.constraint_oid), 'columns', foreign_key.columns, 'foreign_table', jsonb_build_object('schema', foreign_key.ref_table_table_schema, 'name', foreign_key.ref_table), 'foreign_columns', foreign_key.ref_columns)) AS info
           FROM hdb_catalog.hdb_foreign_key_constraint foreign_key
          WHERE ((foreign_key.table_schema = schema.nspname) AND (foreign_key.table_name = "table".relname))) foreign_key_constraints ON (true))
  WHERE ("table".relkind = ANY (ARRAY['r'::"char", 't'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"]));


ALTER TABLE hdb_catalog.hdb_table_info_agg OWNER TO test;

--
-- Name: hdb_unique_constraint; Type: VIEW; Schema: hdb_catalog; Owner: test
--

CREATE VIEW hdb_catalog.hdb_unique_constraint AS
 SELECT tc.table_name,
    tc.constraint_schema AS table_schema,
    tc.constraint_name,
    json_agg(kcu.column_name) AS columns
   FROM (information_schema.table_constraints tc
     JOIN information_schema.key_column_usage kcu USING (constraint_schema, constraint_name))
  WHERE ((tc.constraint_type)::text = 'UNIQUE'::text)
  GROUP BY tc.table_name, tc.constraint_schema, tc.constraint_name;


ALTER TABLE hdb_catalog.hdb_unique_constraint OWNER TO test;

--
-- Name: hdb_version; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.hdb_version (
    hasura_uuid uuid DEFAULT public.gen_random_uuid() NOT NULL,
    version text NOT NULL,
    upgraded_on timestamp with time zone NOT NULL,
    cli_state jsonb DEFAULT '{}'::jsonb NOT NULL,
    console_state jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE hdb_catalog.hdb_version OWNER TO test;

--
-- Name: migration_settings; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.migration_settings (
    setting text NOT NULL,
    value text NOT NULL
);


ALTER TABLE hdb_catalog.migration_settings OWNER TO test;

--
-- Name: remote_schemas; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.remote_schemas (
    id bigint NOT NULL,
    name text,
    definition json,
    comment text
);


ALTER TABLE hdb_catalog.remote_schemas OWNER TO test;

--
-- Name: remote_schemas_id_seq; Type: SEQUENCE; Schema: hdb_catalog; Owner: test
--

CREATE SEQUENCE hdb_catalog.remote_schemas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hdb_catalog.remote_schemas_id_seq OWNER TO test;

--
-- Name: remote_schemas_id_seq; Type: SEQUENCE OWNED BY; Schema: hdb_catalog; Owner: test
--

ALTER SEQUENCE hdb_catalog.remote_schemas_id_seq OWNED BY hdb_catalog.remote_schemas.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: hdb_catalog; Owner: test
--

CREATE TABLE hdb_catalog.schema_migrations (
    version bigint NOT NULL,
    dirty boolean NOT NULL
);


ALTER TABLE hdb_catalog.schema_migrations OWNER TO test;

--
-- Name: companies; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.companies (
    name text NOT NULL,
    logo text,
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.companies OWNER TO test;

--
-- Name: group_aliases; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.group_aliases (
    alias text NOT NULL,
    group_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.group_aliases OWNER TO test;

--
-- Name: group_member_roles; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.group_member_roles (
    id integer NOT NULL,
    member_id integer NOT NULL,
    role_name text NOT NULL
);


ALTER TABLE public.group_member_roles OWNER TO test;

--
-- Name: group_member_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.group_member_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.group_member_roles_id_seq OWNER TO test;

--
-- Name: group_member_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.group_member_roles_id_seq OWNED BY public.group_member_roles.id;


--
-- Name: group_member_status; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.group_member_status (
    status text NOT NULL,
    comment text NOT NULL
);


ALTER TABLE public.group_member_status OWNER TO test;

--
-- Name: group_members; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.group_members (
    idol_id integer NOT NULL,
    role text,
    group_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    join_date date,
    departure_date date,
    status text GENERATED ALWAYS AS (public.group_member_status(join_date, departure_date)) STORED,
    id integer NOT NULL
);


ALTER TABLE public.group_members OWNER TO test;

--
-- Name: group_members_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.group_members_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.group_members_id_seq OWNER TO test;

--
-- Name: group_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.group_members_id_seq OWNED BY public.group_members.id;


--
-- Name: group_status; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.group_status (
    status text NOT NULL,
    comment text NOT NULL
);


ALTER TABLE public.group_status OWNER TO test;

--
-- Name: group_types; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.group_types (
    type text DEFAULT 'GROUP'::text NOT NULL,
    comment text NOT NULL
);


ALTER TABLE public.group_types OWNER TO test;

--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.groups_id_seq OWNER TO test;

--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: idols_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.idols_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.idols_id_seq OWNER TO test;

--
-- Name: idols_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.idols_id_seq OWNED BY public.idols.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.users (
    username text NOT NULL,
    registered_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    discord_user_id text,
    discord_username text,
    role text DEFAULT 'USER'::text,
    twitter_user_id text,
    bio text,
    avatar text,
    banner text,
    email text NOT NULL,
    locale text,
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    banned boolean DEFAULT false NOT NULL
);


ALTER TABLE public.users OWNER TO test;

--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TABLE public.users IS 'A registered MytestList user';


--
-- Name: me; Type: VIEW; Schema: public; Owner: test
--

CREATE VIEW public.me AS
 SELECT users.username,
    users.registered_at,
    users.updated_at,
    users.discord_user_id,
    users.discord_username,
    users.role,
    users.twitter_user_id,
    users.bio,
    users.avatar,
    users.banner,
    users.email,
    users.locale,
    users.id
   FROM public.users
 LIMIT 1;


ALTER TABLE public.me OWNER TO test;

--
-- Name: VIEW me; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON VIEW public.me IS 'The currently logged in user, empty if not logged in';


--
-- Name: release_songs; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.release_songs (
    date_added date,
    is_title_track boolean DEFAULT false NOT NULL,
    group_id integer NOT NULL,
    song_id integer NOT NULL,
    release_id integer NOT NULL,
    updated_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.release_songs OWNER TO test;

--
-- Name: release_types; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.release_types (
    type text NOT NULL,
    comment text NOT NULL
);


ALTER TABLE public.release_types OWNER TO test;

--
-- Name: releases; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.releases (
    name text NOT NULL,
    release_date date,
    album_cover text,
    type text DEFAULT 'STUDIO'::text NOT NULL,
    description text,
    melon_id integer,
    genre text,
    group_id integer NOT NULL,
    id integer NOT NULL,
    spotify_id text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.releases OWNER TO test;

--
-- Name: TABLE releases; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TABLE public.releases IS 'A media release of either an album, mini album or a single';


--
-- Name: releases_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.releases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.releases_id_seq OWNER TO test;

--
-- Name: releases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.releases_id_seq OWNED BY public.releases.id;


--
-- Name: songs; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.songs (
    name text,
    length integer,
    mv_link text,
    spotify_link text,
    language text DEFAULT 'KR'::text NOT NULL,
    group_id integer NOT NULL,
    id integer NOT NULL,
    release_id integer NOT NULL,
    melon_id integer,
    korean_name text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.songs OWNER TO test;

--
-- Name: songs_song_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.songs_song_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.songs_song_id_seq OWNER TO test;

--
-- Name: songs_song_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.songs_song_id_seq OWNED BY public.songs.id;


--
-- Name: submissions; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.submissions (
    id integer NOT NULL,
    user_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    comment text
);


ALTER TABLE public.submissions OWNER TO test;

--
-- Name: submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.submissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.submissions_id_seq OWNER TO test;

--
-- Name: submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.submissions_id_seq OWNED BY public.submissions.id;


--
-- Name: user_refresh_tokens; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.user_refresh_tokens (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_valid boolean DEFAULT true NOT NULL,
    expires_in timestamp with time zone NOT NULL,
    user_id uuid NOT NULL,
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.user_refresh_tokens OWNER TO test;

--
-- Name: TABLE user_refresh_tokens; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TABLE public.user_refresh_tokens IS 'Issued refresh tokens for users [INTERNAL USE ONLY DO NOT ALLOW PERMISSIONS]';


--
-- Name: user_refresh_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.user_refresh_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_refresh_tokens_id_seq OWNER TO test;

--
-- Name: user_refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.user_refresh_tokens_id_seq OWNED BY public.user_refresh_tokens.id;


--
-- Name: user_types; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.user_types (
    type text NOT NULL,
    comment text NOT NULL
);


ALTER TABLE public.user_types OWNER TO test;

--
-- Name: TABLE user_types; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TABLE public.user_types IS 'Different types of users, regular user, admin etc.';


--
-- Name: remote_schemas id; Type: DEFAULT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.remote_schemas ALTER COLUMN id SET DEFAULT nextval('hdb_catalog.remote_schemas_id_seq'::regclass);


--
-- Name: group_member_roles id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_member_roles ALTER COLUMN id SET DEFAULT nextval('public.group_member_roles_id_seq'::regclass);


--
-- Name: group_members id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_members ALTER COLUMN id SET DEFAULT nextval('public.group_members_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: idols id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.idols ALTER COLUMN id SET DEFAULT nextval('public.idols_id_seq'::regclass);


--
-- Name: releases id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.releases ALTER COLUMN id SET DEFAULT nextval('public.releases_id_seq'::regclass);


--
-- Name: songs id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.songs ALTER COLUMN id SET DEFAULT nextval('public.songs_song_id_seq'::regclass);


--
-- Name: submissions id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.submissions ALTER COLUMN id SET DEFAULT nextval('public.submissions_id_seq'::regclass);


--
-- Name: user_refresh_tokens id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.user_refresh_tokens ALTER COLUMN id SET DEFAULT nextval('public.user_refresh_tokens_id_seq'::regclass);


--
-- Data for Name: event_invocation_logs; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.event_invocation_logs (id, event_id, status, request, response, created_at) FROM stdin;
\.


--
-- Data for Name: event_log; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.event_log (id, schema_name, table_name, trigger_name, payload, delivered, error, tries, created_at, locked, next_retry_at, archived) FROM stdin;
\.


--
-- Data for Name: event_triggers; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.event_triggers (name, type, schema_name, table_name, configuration, comment) FROM stdin;
\.


--
-- Data for Name: hdb_action; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.hdb_action (action_name, action_defn, comment, is_system_defined) FROM stdin;
\.


--
-- Data for Name: hdb_action_log; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.hdb_action_log (id, action_name, input_payload, request_headers, session_variables, response_payload, errors, created_at, response_received_at, status) FROM stdin;
\.


--
-- Data for Name: hdb_action_permission; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.hdb_action_permission (action_name, role_name, definition, comment) FROM stdin;
\.


--
-- Data for Name: hdb_allowlist; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.hdb_allowlist (collection_name) FROM stdin;
\.


--
-- Data for Name: hdb_computed_field; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.hdb_computed_field (table_schema, table_name, computed_field_name, definition, comment) FROM stdin;
public	idols	age	{"function": {"name": "idol_age", "schema": "public"}, "table_argument": null}	
public	groups	is_subunit	{"function": {"name": "is_subunit", "schema": "public"}, "table_argument": null}	Whether or not the group is a subunit (ex: loona odd eye circle or NCT 127)
\.


--
-- Data for Name: hdb_custom_types; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.hdb_custom_types (custom_types) FROM stdin;
{"enums": null, "objects": null, "scalars": null, "input_objects": null}
\.


--
-- Data for Name: hdb_function; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.hdb_function (function_schema, function_name, configuration, is_system_defined) FROM stdin;
public	search_group	{}	f
\.


--
-- Data for Name: hdb_permission; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.hdb_permission (table_schema, table_name, role_name, perm_type, perm_def, comment, is_system_defined) FROM stdin;
public	companies	public	select	{"filter": {}, "columns": ["logo", "name"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	release_songs	public	select	{"filter": {}, "columns": ["date_added", "is_title_track", "group_id", "song_id", "release_id"], "computed_fields": [], "allow_aggregations": true}	\N	f
public	release_songs	data_moderator	select	{"filter": {}, "columns": ["date_added", "is_title_track", "group_id", "song_id", "release_id"], "computed_fields": [], "allow_aggregations": true}	\N	f
public	group_status	public	select	{"filter": {}, "columns": ["status", "comment"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	group_members	data_moderator	insert	{"set": {}, "check": {"_exists": {"_table": {"name": "users", "schema": "public"}, "_where": {"_and": [{"id": {"_eq": "X-Hasura-User-Id"}}, {"role": {"_eq": "DATA_MODERATOR"}}]}}}, "columns": ["created_at", "departure_date", "group_id", "id", "idol_id", "join_date", "role", "status", "updated_at"]}	\N	f
public	release_songs	user	select	{"filter": {}, "columns": ["date_added", "is_title_track", "group_id", "song_id", "release_id"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	songs	public	select	{"filter": {}, "columns": ["group_id", "id", "length", "melon_id", "release_id", "korean_name", "language", "mv_link", "name", "spotify_link"], "computed_fields": [], "allow_aggregations": true}	\N	f
public	songs	user	select	{"filter": {}, "columns": ["name", "length", "mv_link", "spotify_link", "language", "group_id", "id", "release_id", "melon_id", "korean_name"], "computed_fields": [], "allow_aggregations": true}	\N	f
public	releases	public	select	{"filter": {}, "columns": ["name", "release_date", "album_cover", "type", "description", "melon_id", "genre", "group_id", "id", "spotify_id"], "computed_fields": [], "allow_aggregations": true}	\N	f
public	users	public	select	{"filter": {}, "columns": ["avatar", "banner", "bio", "discord_username", "id", "locale", "registered_at", "role", "updated_at", "username"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	me	user	select	{"filter": {"id": {"_eq": "X-Hasura-User-Id"}}, "columns": ["username", "registered_at", "updated_at", "discord_user_id", "discord_username", "role", "twitter_user_id", "bio", "avatar", "banner", "email", "locale", "id"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	me	public	select	{"filter": {"_not": {}}, "columns": ["username", "registered_at", "updated_at", "discord_user_id", "discord_username", "role", "twitter_user_id", "bio", "avatar", "banner", "email", "locale", "id"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	group_status	data_moderator	select	{"filter": {}, "columns": ["comment", "status"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	group_status	user	select	{"filter": {}, "columns": ["comment", "status"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	idols	data_moderator	select	{"filter": {}, "columns": ["banner", "birth_city", "birth_date", "country_of_origin", "description", "full_name", "gender", "height", "id", "image", "instagram", "native_name", "korean_stage_name", "melon_id", "stage_name", "thumbnail", "twitter", "weight", "zodiac_sign"], "computed_fields": ["age"], "allow_aggregations": false}	\N	f
public	idols	user	select	{"filter": {}, "columns": ["banner", "birth_city", "birth_date", "country_of_origin", "description", "full_name", "gender", "height", "id", "image", "instagram", "native_name", "korean_stage_name", "melon_id", "stage_name", "thumbnail", "twitter", "weight", "zodiac_sign"], "computed_fields": ["age"], "allow_aggregations": false}	\N	f
public	songs	data_moderator	select	{"filter": {}, "columns": ["group_id", "id", "length", "melon_id", "release_id", "korean_name", "language", "mv_link", "name", "spotify_link"], "computed_fields": [], "allow_aggregations": true}	\N	f
public	group_aliases	user	select	{"limit": 100, "filter": {}, "columns": ["alias", "group_id"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	groups	public	select	{"filter": {}, "columns": ["banner", "banner_text", "company_name", "debut", "description", "discord_server_id", "fan_cafe_id", "fandom_name", "gender", "id", "image", "instagram_username", "korean_name", "melon_id", "name", "original_member_count", "parent_group_id", "spotify_id", "status", "twitter_handle", "type", "vlive_id", "youtube_id"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	users	user	select	{"filter": {}, "columns": ["avatar", "banned", "banner", "bio", "discord_username", "id", "locale", "registered_at", "role", "updated_at", "username"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	companies	data_moderator	select	{"filter": {}, "columns": ["logo", "name"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	companies	user	select	{"filter": {}, "columns": ["logo", "name"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	groups	data_moderator	select	{"filter": {}, "columns": ["banner", "banner_text", "company_name", "debut", "description", "discord_server_id", "fan_cafe_id", "fandom_name", "gender", "id", "image", "instagram_username", "korean_name", "melon_id", "name", "original_member_count", "parent_group_id", "spotify_id", "status", "twitter_handle", "type", "vlive_id", "youtube_id"], "computed_fields": ["is_subunit"], "allow_aggregations": false}	\N	f
public	groups	user	select	{"filter": {}, "columns": ["banner", "banner_text", "company_name", "debut", "description", "discord_server_id", "fan_cafe_id", "fandom_name", "gender", "id", "image", "instagram_username", "korean_name", "melon_id", "name", "original_member_count", "parent_group_id", "spotify_id", "status", "twitter_handle", "type", "vlive_id", "youtube_id"], "computed_fields": ["is_subunit"], "allow_aggregations": false}	\N	f
public	releases	data_moderator	select	{"filter": {}, "columns": ["name", "release_date", "album_cover", "type", "description", "melon_id", "genre", "group_id", "id", "spotify_id"], "computed_fields": [], "allow_aggregations": true}	\N	f
public	releases	user	select	{"filter": {}, "columns": ["name", "release_date", "album_cover", "type", "description", "melon_id", "genre", "group_id", "id", "spotify_id"], "computed_fields": [], "allow_aggregations": true}	\N	f
public	group_members	data_moderator	delete	{"filter": {"_exists": {"_table": {"name": "users", "schema": "public"}, "_where": {"_and": [{"id": {"_eq": "X-Hasura-User-Id"}}, {"role": {"_eq": "DATA_MODERATOR"}}]}}}}	\N	f
public	idols	public	select	{"filter": {}, "columns": ["full_name", "native_name", "birth_date", "gender", "country_of_origin", "stage_name", "id", "twitter", "instagram", "height", "image", "banner", "melon_id", "description", "zodiac_sign", "korean_stage_name", "birth_city", "weight", "thumbnail"], "computed_fields": ["age"], "allow_aggregations": false}	\N	f
public	group_aliases	data_moderator	select	{"limit": 100, "filter": {}, "columns": ["alias", "group_id"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	group_aliases	public	select	{"limit": 100, "filter": {}, "columns": ["alias", "group_id"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	groups	data_moderator	insert	{"set": {}, "check": {"_exists": {"_table": {"name": "users", "schema": "public"}, "_where": {"_and": [{"id": {"_eq": "X-Hasura-User-Id"}}, {"role": {"_eq": "DATA_MODERATOR"}}]}}}, "columns": ["banner", "banner_text", "company_name", "debut", "description", "discord_server_id", "fan_cafe_id", "fandom_name", "gender", "id", "image", "instagram_username", "korean_name", "melon_id", "name", "original_member_count", "parent_group_id", "spotify_id", "status", "twitter_handle", "type", "vlive_id", "youtube_id"]}	\N	f
public	groups	data_moderator	update	{"set": {}, "filter": {"_exists": {"_table": {"name": "users", "schema": "public"}, "_where": {"_and": [{"id": {"_eq": "X-Hasura-User-Id"}}, {"role": {"_eq": "DATA_MODERATOR"}}]}}}, "columns": ["banner", "banner_text", "company_name", "debut", "description", "discord_server_id", "fan_cafe_id", "fandom_name", "gender", "id", "image", "instagram_username", "korean_name", "melon_id", "name", "original_member_count", "parent_group_id", "spotify_id", "status", "twitter_handle", "type", "vlive_id", "youtube_id"]}	\N	f
public	group_member_roles	data_moderator	delete	{"filter": {"_exists": {"_table": {"name": "users", "schema": "public"}, "_where": {"_and": [{"id": {"_eq": "X-Hasura-User-Id"}}, {"role": {"_eq": "DATA_MODERATOR"}}]}}}}	\N	f
public	group_member_roles	public	select	{"limit": 100, "filter": {}, "columns": ["id", "member_id", "role_name"], "computed_fields": [], "allow_aggregations": true}	\N	f
public	group_member_roles	data_moderator	select	{"filter": {"_exists": {"_table": {"name": "users", "schema": "public"}, "_where": {"_and": [{"id": {"_eq": "X-Hasura-User-Id"}}, {"role": {"_eq": "DATA_MODERATOR"}}]}}}, "columns": ["id", "member_id", "role_name"], "computed_fields": [], "allow_aggregations": true}	\N	f
public	idols	data_moderator	insert	{"set": {}, "check": {"_exists": {"_table": {"name": "users", "schema": "public"}, "_where": {"_and": [{"id": {"_eq": "X-Hasura-User-Id"}}, {"role": {"_eq": "DATA_MODERATOR"}}]}}}, "columns": ["banner", "birth_city", "birth_date", "country_of_origin", "description", "full_name", "gender", "height", "id", "image", "instagram", "native_name", "korean_stage_name", "melon_id", "stage_name", "thumbnail", "twitter", "weight", "zodiac_sign"]}	\N	f
public	idols	data_moderator	update	{"set": {}, "filter": {"_exists": {"_table": {"name": "users", "schema": "public"}, "_where": {"_and": [{"id": {"_eq": "X-Hasura-User-Id"}}, {"role": {"_eq": "DATA_MODERATOR"}}]}}}, "columns": ["banner", "birth_city", "birth_date", "country_of_origin", "description", "full_name", "gender", "height", "id", "image", "instagram", "native_name", "korean_stage_name", "melon_id", "stage_name", "thumbnail", "twitter", "weight", "zodiac_sign"]}	\N	f
public	group_members	data_moderator	select	{"filter": {}, "columns": ["created_at", "departure_date", "group_id", "id", "idol_id", "join_date", "role", "status", "updated_at"], "computed_fields": [], "allow_aggregations": true}	\N	f
public	group_members	public	select	{"filter": {}, "columns": ["departure_date", "group_id", "id", "idol_id", "join_date", "role", "status"], "computed_fields": [], "allow_aggregations": true}	\N	f
public	group_members	user	select	{"filter": {}, "columns": ["departure_date", "group_id", "id", "idol_id", "join_date", "role", "status"], "computed_fields": [], "allow_aggregations": true}	\N	f
public	group_members	data_moderator	update	{"set": {}, "filter": {"_exists": {"_table": {"name": "users", "schema": "public"}, "_where": {"_and": [{"id": {"_eq": "X-Hasura-User-Id"}}, {"role": {"_eq": "DATA_MODERATOR"}}]}}}, "columns": ["created_at", "departure_date", "group_id", "id", "idol_id", "join_date", "role", "status", "updated_at"]}	\N	f
public	group_member_roles	data_moderator	update	{"set": {}, "filter": {"_exists": {"_table": {"name": "users", "schema": "public"}, "_where": {"_and": [{"id": {"_eq": "X-Hasura-User-Id"}}, {"role": {"_eq": "DATA_MODERATOR"}}]}}}, "columns": ["id", "member_id", "role_name"]}	\N	f
public	group_member_roles	data_moderator	insert	{"set": {}, "check": {"_exists": {"_table": {"name": "users", "schema": "public"}, "_where": {"_and": [{"id": {"_eq": "X-Hasura-User-Id"}}, {"role": {"_eq": "DATA_MODERATOR"}}]}}}, "columns": ["id", "member_id", "role_name"]}	\N	f
\.


--
-- Data for Name: hdb_query_collection; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.hdb_query_collection (collection_name, collection_defn, comment, is_system_defined) FROM stdin;
\.


--
-- Data for Name: hdb_relationship; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.hdb_relationship (table_schema, table_name, rel_name, rel_type, rel_def, comment, is_system_defined) FROM stdin;
hdb_catalog	hdb_table	detail	object	{"manual_configuration": {"remote_table": {"name": "tables", "schema": "information_schema"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	primary_key	object	{"manual_configuration": {"remote_table": {"name": "hdb_primary_key", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	columns	array	{"manual_configuration": {"remote_table": {"name": "columns", "schema": "information_schema"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	foreign_key_constraints	array	{"manual_configuration": {"remote_table": {"name": "hdb_foreign_key_constraint", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	relationships	array	{"manual_configuration": {"remote_table": {"name": "hdb_relationship", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	permissions	array	{"manual_configuration": {"remote_table": {"name": "hdb_permission_agg", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	computed_fields	array	{"manual_configuration": {"remote_table": {"name": "hdb_computed_field", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	check_constraints	array	{"manual_configuration": {"remote_table": {"name": "hdb_check_constraint", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	unique_constraints	array	{"manual_configuration": {"remote_table": {"name": "hdb_unique_constraint", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	event_triggers	events	array	{"manual_configuration": {"remote_table": {"name": "event_log", "schema": "hdb_catalog"}, "column_mapping": {"name": "trigger_name"}}}	\N	t
hdb_catalog	event_log	trigger	object	{"manual_configuration": {"remote_table": {"name": "event_triggers", "schema": "hdb_catalog"}, "column_mapping": {"trigger_name": "name"}}}	\N	t
hdb_catalog	event_log	logs	array	{"foreign_key_constraint_on": {"table": {"name": "event_invocation_logs", "schema": "hdb_catalog"}, "column": "event_id"}}	\N	t
hdb_catalog	event_invocation_logs	event	object	{"foreign_key_constraint_on": "event_id"}	\N	t
hdb_catalog	hdb_function_agg	return_table_info	object	{"manual_configuration": {"remote_table": {"name": "hdb_table", "schema": "hdb_catalog"}, "column_mapping": {"return_type_name": "table_name", "return_type_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_action	permissions	array	{"manual_configuration": {"remote_table": {"name": "hdb_action_permission", "schema": "hdb_catalog"}, "column_mapping": {"action_name": "action_name"}}}	\N	t
hdb_catalog	hdb_role	action_permissions	array	{"manual_configuration": {"remote_table": {"name": "hdb_action_permission", "schema": "hdb_catalog"}, "column_mapping": {"role_name": "role_name"}}}	\N	t
hdb_catalog	hdb_role	permissions	array	{"manual_configuration": {"remote_table": {"name": "hdb_permission_agg", "schema": "hdb_catalog"}, "column_mapping": {"role_name": "role_name"}}}	\N	t
public	companies	groups	array	{"foreign_key_constraint_on": {"table": {"name": "groups", "schema": "public"}, "column": "company_name"}}	\N	f
public	group_aliases	group	object	{"foreign_key_constraint_on": "group_id"}	\N	f
public	groups	company	object	{"foreign_key_constraint_on": "company_name"}	\N	f
public	groups	group_status	object	{"foreign_key_constraint_on": "status"}	\N	f
public	groups	parent_group	object	{"foreign_key_constraint_on": "parent_group_id"}	\N	f
public	groups	aliases	array	{"foreign_key_constraint_on": {"table": {"name": "group_aliases", "schema": "public"}, "column": "group_id"}}	\N	f
public	groups	releases	array	{"foreign_key_constraint_on": {"table": {"name": "releases", "schema": "public"}, "column": "group_id"}}	\N	f
public	groups	songs	array	{"foreign_key_constraint_on": {"table": {"name": "songs", "schema": "public"}, "column": "group_id"}}	\N	f
public	group_status	groups	array	{"foreign_key_constraint_on": {"table": {"name": "groups", "schema": "public"}, "column": "status"}}	\N	f
public	releases	group	object	{"foreign_key_constraint_on": "group_id"}	\N	f
public	releases	release_type	object	{"foreign_key_constraint_on": "type"}	\N	f
public	releases	release_songs	array	{"foreign_key_constraint_on": {"table": {"name": "release_songs", "schema": "public"}, "column": "release_id"}}	\N	f
public	releases	songs	array	{"foreign_key_constraint_on": {"table": {"name": "songs", "schema": "public"}, "column": "release_id"}}	\N	f
public	release_songs	release	object	{"foreign_key_constraint_on": "release_id"}	\N	f
public	release_songs	song	object	{"foreign_key_constraint_on": "song_id"}	\N	f
public	songs	group	object	{"foreign_key_constraint_on": "group_id"}	\N	f
public	songs	release	object	{"foreign_key_constraint_on": "release_id"}	\N	f
public	songs	releases	array	{"foreign_key_constraint_on": {"table": {"name": "release_songs", "schema": "public"}, "column": "song_id"}}	\N	f
public	users	refresh_tokens	array	{"foreign_key_constraint_on": {"table": {"name": "user_refresh_tokens", "schema": "public"}, "column": "user_id"}}	\N	f
public	idols	idol_groups	array	{"foreign_key_constraint_on": {"table": {"name": "group_members", "schema": "public"}, "column": "idol_id"}}	\N	f
public	groups	members	array	{"foreign_key_constraint_on": {"table": {"name": "group_members", "schema": "public"}, "column": "group_id"}}	\N	f
public	group_members	group	object	{"foreign_key_constraint_on": "group_id"}	\N	f
public	group_members	idol	object	{"foreign_key_constraint_on": "idol_id"}	\N	f
public	groups	subunits	array	{"foreign_key_constraint_on": {"table": {"name": "groups", "schema": "public"}, "column": "parent_group_id"}}	\N	f
public	group_member_roles	member	object	{"foreign_key_constraint_on": "member_id"}	\N	f
public	group_members	roles	array	{"foreign_key_constraint_on": {"table": {"name": "group_member_roles", "schema": "public"}, "column": "member_id"}}	\N	f
\.


--
-- Data for Name: hdb_schema_update_event; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.hdb_schema_update_event (instance_id, occurred_at, invalidations) FROM stdin;
87d007a6-2a2e-4ecc-99b7-59be93b3426c	2020-04-21 23:38:28.555981+00	{"metadata":false,"remote_schemas":[]}
\.


--
-- Data for Name: hdb_table; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.hdb_table (table_schema, table_name, configuration, is_system_defined, is_enum) FROM stdin;
information_schema	tables	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
information_schema	schemata	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
information_schema	views	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
information_schema	columns	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_table	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_primary_key	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_foreign_key_constraint	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_relationship	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_permission_agg	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_computed_field	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_check_constraint	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_unique_constraint	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	event_triggers	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	event_log	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	event_invocation_logs	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_function	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_function_agg	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	remote_schemas	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_version	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_query_collection	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_allowlist	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_custom_types	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_action_permission	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_action	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_action_log	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_role	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
public	companies	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	group_aliases	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	groups	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	group_status	{"custom_root_fields": {}, "custom_column_names": {}}	f	t
public	group_types	{"custom_root_fields": {}, "custom_column_names": {}}	f	t
public	idols	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	releases	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	release_songs	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	release_types	{"custom_root_fields": {}, "custom_column_names": {}}	f	t
public	songs	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	user_refresh_tokens	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	users	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	user_types	{"custom_root_fields": {}, "custom_column_names": {}}	f	t
public	me	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	group_members	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	submissions	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	group_member_status	{"custom_root_fields": {}, "custom_column_names": {}}	f	t
public	group_member_roles	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
\.


--
-- Data for Name: hdb_version; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.hdb_version (hasura_uuid, version, upgraded_on, cli_state, console_state) FROM stdin;
3fdc93f2-66c5-4764-b3f1-453ccc723c38	32	2020-04-12 22:26:23.069422+00	{}	{"telemetryNotificationShown": true}
\.


--
-- Data for Name: migration_settings; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.migration_settings (setting, value) FROM stdin;
migration_mode	true
\.


--
-- Data for Name: remote_schemas; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.remote_schemas (id, name, definition, comment) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: hdb_catalog; Owner: test
--

COPY hdb_catalog.schema_migrations (version, dirty) FROM stdin;
1577886737954	f
1578228905419	f
1578229173735	f
1578229180652	f
1578229184795	f
1578229206271	f
1578229241429	f
1578229251010	f
1578229263123	f
1578229278602	f
1578229286796	f
1578229322525	f
1578230182080	f
1578230237076	f
1578230854761	f
1578231100217	f
1582516119746	f
1582516152593	f
1582516173013	f
1582516364901	f
1582516962811	f
1582516962856	f
1582516987790	f
1582522694240	f
1582522802388	f
1582532082033	f
1582862781996	f
1583720764977	f
1583739163162	f
1584254716854	f
1584667103004	f
1584667112836	f
1584904077942	f
1584904085690	f
1585122535524	f
1585122568512	f
1585393219684	f
1585393235590	f
1585532616774	f
1585606001462	f
1585606610422	f
1585606634912	f
1585606708587	f
1585622545741	f
1585622574960	f
1585622586561	f
1585622589589	f
1585622595691	f
1585622598036	f
1585622614242	f
1585622616919	f
1585622629787	f
1585622632773	f
1585622645799	f
1585622666019	f
1585622672735	f
1585622674911	f
1585622682030	f
1585622686018	f
1585622704433	f
1586392785009	f
1586392834077	f
1586397535989	f
1586397724319	f
1586398003424	f
1586398024705	f
1586398186201	f
1586398189881	f
1586398200047	f
1586401394056	f
1586402869261	f
1586402886530	f
1586402917241	f
1586408286086	f
1586408293696	f
1586420732100	f
1586842406009	f
1586851677944	f
1586852208116	f
1586852241130	f
1586852436579	f
1586852459505	f
1586852487049	f
1586852515766	f
1586852539934	f
1586852564303	f
1586852582811	f
1586852605343	f
1586852683467	f
1586852693597	f
1586852805346	f
1586852889207	f
1586852909708	f
1586855166255	f
1586864276030	f
1586864285118	f
1586864288694	f
1586864304757	f
1586864312764	f
1586864318554	f
1586980166386	f
1586980255064	f
1586980277514	f
1586980297502	f
1586980361634	f
1586980372415	f
1586980379132	f
1586980417528	f
1586980433855	f
1586980442521	f
1586980453311	f
1586981223875	f
1586981228383	f
1586981589911	f
1586986384843	f
1586986388593	f
1586986393075	f
1586986418832	f
1586992700418	f
1587001607644	f
1587001633464	f
1587002886577	f
1587037325730	f
1587037329476	f
1587110275380	f
1587179642021	f
1587258323890	f
1587258333851	f
1587258512330	f
1587440866378	f
\.


--
-- Data for Name: companies; Type: TABLE DATA; Schema: public; Owner: test
--


--
-- Data for Name: group_aliases; Type: TABLE DATA; Schema: public; Owner: test
--


--
-- Data for Name: group_member_roles; Type: TABLE DATA; Schema: public; Owner: test
--


--
-- Data for Name: group_member_status; Type: TABLE DATA; Schema: public; Owner: test
--

COPY public.group_member_status (status, comment) FROM stdin;
PRE_DEBUT	This idol was announced as a group member, but has not officially joined
ACTIVE	This idol is actively performing with the group
DEPARTING	This idol is departing, but has not yet left the group
DEPARTED	This idol is no longer a member of the group
\.


--
-- Data for Name: group_members; Type: TABLE DATA; Schema: public; Owner: test
--

--
-- Data for Name: group_status; Type: TABLE DATA; Schema: public; Owner: test
--

COPY public.group_status (status, comment) FROM stdin;
ACTIVE	 Group is currently active
DISBANDED	Group is no longer active
HIATUS	Group has stopped creating content without disbanding
\.


--
-- Data for Name: group_types; Type: TABLE DATA; Schema: public; Owner: test
--

COPY public.group_types (type, comment) FROM stdin;
GROUP	A group with more than one member
SOLO	A solo project with a single member (ex. Sunmi)
\.


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: test
--

--
-- Data for Name: idols; Type: TABLE DATA; Schema: public; Owner: test
--

--
-- Data for Name: release_songs; Type: TABLE DATA; Schema: public; Owner: test
--

--
-- Data for Name: release_types; Type: TABLE DATA; Schema: public; Owner: test
--

COPY public.release_types (type, comment) FROM stdin;
STUDIO	A standard release album
MINI	A mini album with more songs than a single but not as many as a full album
SINGLE	A release containing one or two songs
OST	Official Soundtrack
OTHER	Miscellaneous releases
\.


--
-- Data for Name: releases; Type: TABLE DATA; Schema: public; Owner: test
--

--
-- Data for Name: songs; Type: TABLE DATA; Schema: public; Owner: test
--

--
-- Data for Name: submissions; Type: TABLE DATA; Schema: public; Owner: test
--

COPY public.submissions (id, user_id, created_at, updated_at, comment) FROM stdin;
\.


--
-- Data for Name: user_refresh_tokens; Type: TABLE DATA; Schema: public; Owner: test
--

--
-- Data for Name: user_types; Type: TABLE DATA; Schema: public; Owner: test
--

COPY public.user_types (type, comment) FROM stdin;
USER	A regular user with default privileges
DATA_MODERATOR	A user who is responsible for moderating changes to site data
ADMIN	Administrator responsible for user management and more
DONATOR	A user that has donator privileges active
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: test
--

--
-- Name: remote_schemas_id_seq; Type: SEQUENCE SET; Schema: hdb_catalog; Owner: test
--

SELECT pg_catalog.setval('hdb_catalog.remote_schemas_id_seq', 1, false);


--
-- Name: group_member_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.group_member_roles_id_seq', 18, true);


--
-- Name: group_members_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.group_members_id_seq', 596, true);


--
-- Name: groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.groups_id_seq', 109, true);


--
-- Name: idols_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.idols_id_seq', 575, true);


--
-- Name: releases_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.releases_id_seq', 1510, true);


--
-- Name: songs_song_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.songs_song_id_seq', 5226, true);


--
-- Name: submissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.submissions_id_seq', 1, false);


--
-- Name: user_refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.user_refresh_tokens_id_seq', 7, true);


--
-- Name: event_invocation_logs event_invocation_logs_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.event_invocation_logs
    ADD CONSTRAINT event_invocation_logs_pkey PRIMARY KEY (id);


--
-- Name: event_log event_log_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.event_log
    ADD CONSTRAINT event_log_pkey PRIMARY KEY (id);


--
-- Name: event_triggers event_triggers_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.event_triggers
    ADD CONSTRAINT event_triggers_pkey PRIMARY KEY (name);


--
-- Name: hdb_action_log hdb_action_log_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_action_log
    ADD CONSTRAINT hdb_action_log_pkey PRIMARY KEY (id);


--
-- Name: hdb_action_permission hdb_action_permission_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_action_permission
    ADD CONSTRAINT hdb_action_permission_pkey PRIMARY KEY (action_name, role_name);


--
-- Name: hdb_action hdb_action_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_action
    ADD CONSTRAINT hdb_action_pkey PRIMARY KEY (action_name);


--
-- Name: hdb_allowlist hdb_allowlist_collection_name_key; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_allowlist
    ADD CONSTRAINT hdb_allowlist_collection_name_key UNIQUE (collection_name);


--
-- Name: hdb_computed_field hdb_computed_field_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_computed_field
    ADD CONSTRAINT hdb_computed_field_pkey PRIMARY KEY (table_schema, table_name, computed_field_name);


--
-- Name: hdb_function hdb_function_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_function
    ADD CONSTRAINT hdb_function_pkey PRIMARY KEY (function_schema, function_name);


--
-- Name: hdb_permission hdb_permission_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_permission
    ADD CONSTRAINT hdb_permission_pkey PRIMARY KEY (table_schema, table_name, role_name, perm_type);


--
-- Name: hdb_query_collection hdb_query_collection_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_query_collection
    ADD CONSTRAINT hdb_query_collection_pkey PRIMARY KEY (collection_name);


--
-- Name: hdb_relationship hdb_relationship_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_relationship
    ADD CONSTRAINT hdb_relationship_pkey PRIMARY KEY (table_schema, table_name, rel_name);


--
-- Name: hdb_table hdb_table_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_table
    ADD CONSTRAINT hdb_table_pkey PRIMARY KEY (table_schema, table_name);


--
-- Name: hdb_version hdb_version_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_version
    ADD CONSTRAINT hdb_version_pkey PRIMARY KEY (hasura_uuid);


--
-- Name: migration_settings migration_settings_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.migration_settings
    ADD CONSTRAINT migration_settings_pkey PRIMARY KEY (setting);


--
-- Name: remote_schemas remote_schemas_name_key; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.remote_schemas
    ADD CONSTRAINT remote_schemas_name_key UNIQUE (name);


--
-- Name: remote_schemas remote_schemas_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.remote_schemas
    ADD CONSTRAINT remote_schemas_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: companies company_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT company_pkey PRIMARY KEY (name);


--
-- Name: group_aliases group_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_aliases
    ADD CONSTRAINT group_aliases_pkey PRIMARY KEY (alias, group_id);


--
-- Name: group_member_roles group_member_roles_member_id_role_name_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_member_roles
    ADD CONSTRAINT group_member_roles_member_id_role_name_key UNIQUE (member_id, role_name);


--
-- Name: group_member_roles group_member_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_member_roles
    ADD CONSTRAINT group_member_roles_pkey PRIMARY KEY (id);


--
-- Name: group_member_status group_member_status_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_member_status
    ADD CONSTRAINT group_member_status_pkey PRIMARY KEY (status);


--
-- Name: group_members group_members_group_id_idol_id_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_group_id_idol_id_key UNIQUE (group_id, idol_id);


--
-- Name: group_members group_members_id_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_id_key UNIQUE (id);


--
-- Name: group_members group_members_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_pkey PRIMARY KEY (id);


--
-- Name: group_status group_status_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_status
    ADD CONSTRAINT group_status_pkey PRIMARY KEY (status);


--
-- Name: group_types group_types_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_types
    ADD CONSTRAINT group_types_pkey PRIMARY KEY (type);


--
-- Name: groups groups_id_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_id_key UNIQUE (id);


--
-- Name: groups groups_melon_id_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_melon_id_key UNIQUE (melon_id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: idols idols_melon_id_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.idols
    ADD CONSTRAINT idols_melon_id_key UNIQUE (melon_id);


--
-- Name: idols idols_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.idols
    ADD CONSTRAINT idols_pkey PRIMARY KEY (id);


--
-- Name: release_songs release_songs_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.release_songs
    ADD CONSTRAINT release_songs_pkey PRIMARY KEY (release_id, group_id, song_id);


--
-- Name: release_types release_types_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.release_types
    ADD CONSTRAINT release_types_pkey PRIMARY KEY (type);


--
-- Name: releases releases_id_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT releases_id_key UNIQUE (id);


--
-- Name: releases releases_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT releases_pkey PRIMARY KEY (id);


--
-- Name: songs songs_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_pkey PRIMARY KEY (id, group_id);


--
-- Name: songs songs_song_id_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_song_id_key UNIQUE (id);


--
-- Name: submissions submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);


--
-- Name: user_refresh_tokens user_refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.user_refresh_tokens
    ADD CONSTRAINT user_refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: user_types user_types_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.user_types
    ADD CONSTRAINT user_types_pkey PRIMARY KEY (type);


--
-- Name: users users__id_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users__id_key UNIQUE (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: event_invocation_logs_event_id_idx; Type: INDEX; Schema: hdb_catalog; Owner: test
--

CREATE INDEX event_invocation_logs_event_id_idx ON hdb_catalog.event_invocation_logs USING btree (event_id);


--
-- Name: event_log_delivered_idx; Type: INDEX; Schema: hdb_catalog; Owner: test
--

CREATE INDEX event_log_delivered_idx ON hdb_catalog.event_log USING btree (delivered);


--
-- Name: event_log_locked_idx; Type: INDEX; Schema: hdb_catalog; Owner: test
--

CREATE INDEX event_log_locked_idx ON hdb_catalog.event_log USING btree (locked);


--
-- Name: event_log_trigger_name_idx; Type: INDEX; Schema: hdb_catalog; Owner: test
--

CREATE INDEX event_log_trigger_name_idx ON hdb_catalog.event_log USING btree (trigger_name);


--
-- Name: hdb_schema_update_event_one_row; Type: INDEX; Schema: hdb_catalog; Owner: test
--

CREATE UNIQUE INDEX hdb_schema_update_event_one_row ON hdb_catalog.hdb_schema_update_event USING btree (((occurred_at IS NOT NULL)));


--
-- Name: hdb_version_one_row; Type: INDEX; Schema: hdb_catalog; Owner: test
--

CREATE UNIQUE INDEX hdb_version_one_row ON hdb_catalog.hdb_version USING btree (((version IS NOT NULL)));


--
-- Name: hdb_schema_update_event hdb_schema_update_event_notifier; Type: TRIGGER; Schema: hdb_catalog; Owner: test
--

CREATE TRIGGER hdb_schema_update_event_notifier AFTER INSERT OR UPDATE ON hdb_catalog.hdb_schema_update_event FOR EACH ROW EXECUTE FUNCTION hdb_catalog.hdb_schema_update_event_notifier();


--
-- Name: companies set_public_companies_updated_at; Type: TRIGGER; Schema: public; Owner: test
--

CREATE TRIGGER set_public_companies_updated_at BEFORE UPDATE ON public.companies FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER set_public_companies_updated_at ON companies; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TRIGGER set_public_companies_updated_at ON public.companies IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: group_aliases set_public_group_aliases_updated_at; Type: TRIGGER; Schema: public; Owner: test
--

CREATE TRIGGER set_public_group_aliases_updated_at BEFORE UPDATE ON public.group_aliases FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER set_public_group_aliases_updated_at ON group_aliases; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TRIGGER set_public_group_aliases_updated_at ON public.group_aliases IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: group_members set_public_group_members_updated_at; Type: TRIGGER; Schema: public; Owner: test
--

CREATE TRIGGER set_public_group_members_updated_at BEFORE UPDATE ON public.group_members FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER set_public_group_members_updated_at ON group_members; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TRIGGER set_public_group_members_updated_at ON public.group_members IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: groups set_public_groups_updated_at; Type: TRIGGER; Schema: public; Owner: test
--

CREATE TRIGGER set_public_groups_updated_at BEFORE UPDATE ON public.groups FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER set_public_groups_updated_at ON groups; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TRIGGER set_public_groups_updated_at ON public.groups IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: idols set_public_idols_updated_at; Type: TRIGGER; Schema: public; Owner: test
--

CREATE TRIGGER set_public_idols_updated_at BEFORE UPDATE ON public.idols FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER set_public_idols_updated_at ON idols; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TRIGGER set_public_idols_updated_at ON public.idols IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: release_songs set_public_release_songs_updated_at; Type: TRIGGER; Schema: public; Owner: test
--

CREATE TRIGGER set_public_release_songs_updated_at BEFORE UPDATE ON public.release_songs FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER set_public_release_songs_updated_at ON release_songs; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TRIGGER set_public_release_songs_updated_at ON public.release_songs IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: releases set_public_releases_updated_at; Type: TRIGGER; Schema: public; Owner: test
--

CREATE TRIGGER set_public_releases_updated_at BEFORE UPDATE ON public.releases FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER set_public_releases_updated_at ON releases; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TRIGGER set_public_releases_updated_at ON public.releases IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: songs set_public_songs_updated_at; Type: TRIGGER; Schema: public; Owner: test
--

CREATE TRIGGER set_public_songs_updated_at BEFORE UPDATE ON public.songs FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER set_public_songs_updated_at ON songs; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TRIGGER set_public_songs_updated_at ON public.songs IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: submissions set_public_submissions_updated_at; Type: TRIGGER; Schema: public; Owner: test
--

CREATE TRIGGER set_public_submissions_updated_at BEFORE UPDATE ON public.submissions FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER set_public_submissions_updated_at ON submissions; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TRIGGER set_public_submissions_updated_at ON public.submissions IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: user_refresh_tokens set_public_user_refresh_tokens_updated_at; Type: TRIGGER; Schema: public; Owner: test
--

CREATE TRIGGER set_public_user_refresh_tokens_updated_at BEFORE UPDATE ON public.user_refresh_tokens FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER set_public_user_refresh_tokens_updated_at ON user_refresh_tokens; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TRIGGER set_public_user_refresh_tokens_updated_at ON public.user_refresh_tokens IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: users set_public_users_updated_at; Type: TRIGGER; Schema: public; Owner: test
--

CREATE TRIGGER set_public_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: TRIGGER set_public_users_updated_at ON users; Type: COMMENT; Schema: public; Owner: test
--

COMMENT ON TRIGGER set_public_users_updated_at ON public.users IS 'trigger to set value of column "updated_at" to current timestamp on row update';


--
-- Name: event_invocation_logs event_invocation_logs_event_id_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.event_invocation_logs
    ADD CONSTRAINT event_invocation_logs_event_id_fkey FOREIGN KEY (event_id) REFERENCES hdb_catalog.event_log(id);


--
-- Name: event_triggers event_triggers_schema_name_table_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.event_triggers
    ADD CONSTRAINT event_triggers_schema_name_table_name_fkey FOREIGN KEY (schema_name, table_name) REFERENCES hdb_catalog.hdb_table(table_schema, table_name) ON UPDATE CASCADE;


--
-- Name: hdb_action_permission hdb_action_permission_action_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_action_permission
    ADD CONSTRAINT hdb_action_permission_action_name_fkey FOREIGN KEY (action_name) REFERENCES hdb_catalog.hdb_action(action_name) ON UPDATE CASCADE;


--
-- Name: hdb_allowlist hdb_allowlist_collection_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_allowlist
    ADD CONSTRAINT hdb_allowlist_collection_name_fkey FOREIGN KEY (collection_name) REFERENCES hdb_catalog.hdb_query_collection(collection_name);


--
-- Name: hdb_computed_field hdb_computed_field_table_schema_table_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_computed_field
    ADD CONSTRAINT hdb_computed_field_table_schema_table_name_fkey FOREIGN KEY (table_schema, table_name) REFERENCES hdb_catalog.hdb_table(table_schema, table_name) ON UPDATE CASCADE;


--
-- Name: hdb_permission hdb_permission_table_schema_table_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_permission
    ADD CONSTRAINT hdb_permission_table_schema_table_name_fkey FOREIGN KEY (table_schema, table_name) REFERENCES hdb_catalog.hdb_table(table_schema, table_name) ON UPDATE CASCADE;


--
-- Name: hdb_relationship hdb_relationship_table_schema_table_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: test
--

ALTER TABLE ONLY hdb_catalog.hdb_relationship
    ADD CONSTRAINT hdb_relationship_table_schema_table_name_fkey FOREIGN KEY (table_schema, table_name) REFERENCES hdb_catalog.hdb_table(table_schema, table_name) ON UPDATE CASCADE;


--
-- Name: group_aliases group_aliases_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_aliases
    ADD CONSTRAINT group_aliases_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: group_member_roles group_member_roles_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_member_roles
    ADD CONSTRAINT group_member_roles_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.group_members(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: group_members group_members_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_status_fkey FOREIGN KEY (status) REFERENCES public.group_member_status(status) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: groups groups_company_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_company_fkey FOREIGN KEY (company_name) REFERENCES public.companies(name) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: groups groups_parent_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_parent_group_id_fkey FOREIGN KEY (parent_group_id) REFERENCES public.groups(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: groups groups_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_status_fkey FOREIGN KEY (status) REFERENCES public.group_status(status) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: group_members idol_groups_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT idol_groups_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON UPDATE SET NULL ON DELETE SET NULL;


--
-- Name: group_members idol_groups_idol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT idol_groups_idol_id_fkey FOREIGN KEY (idol_id) REFERENCES public.idols(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: release_songs release_songs_release_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.release_songs
    ADD CONSTRAINT release_songs_release_id_fkey FOREIGN KEY (release_id) REFERENCES public.releases(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: release_songs release_songs_song_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.release_songs
    ADD CONSTRAINT release_songs_song_id_fkey FOREIGN KEY (song_id) REFERENCES public.songs(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: releases releases_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT releases_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: releases releases_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT releases_type_fkey FOREIGN KEY (type) REFERENCES public.release_types(type) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: songs songs_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: songs songs_release_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_release_id_fkey FOREIGN KEY (release_id) REFERENCES public.releases(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: submissions submissions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT submissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: user_refresh_tokens user_refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.user_refresh_tokens
    ADD CONSTRAINT user_refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users users_role_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_fkey FOREIGN KEY (role) REFERENCES public.user_types(type) ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- PostgreSQL database dump complete
--

