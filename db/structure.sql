--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE actions (
    id integer NOT NULL,
    name character varying NOT NULL,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    succeeded boolean,
    error_id integer,
    trigger character varying,
    params text,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE actions_id_seq OWNED BY actions.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: authorizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE authorizations (
    id integer NOT NULL,
    scope character varying,
    access_token character varying,
    refresh_token character varying,
    secret character varying,
    expires_in integer,
    expires_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    provider_name character varying NOT NULL,
    user_id integer NOT NULL,
    props jsonb DEFAULT '{}'::jsonb
);


--
-- Name: authorizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE authorizations_id_seq OWNED BY authorizations.id;


--
-- Name: consumer_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE consumer_tokens (
    id integer NOT NULL,
    user_id integer,
    type character varying(30),
    token character varying(1024),
    refresh_token character varying,
    secret character varying,
    expires_at integer,
    expires_in character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: consumer_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE consumer_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consumer_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE consumer_tokens_id_seq OWNED BY consumer_tokens.id;


--
-- Name: errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE errors (
    id integer NOT NULL,
    sha character varying NOT NULL,
    message text NOT NULL,
    backtrace text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    type character varying
);


--
-- Name: errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE errors_id_seq OWNED BY errors.id;


--
-- Name: follows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE follows (
    id integer NOT NULL,
    user_id integer,
    project_id integer
);


--
-- Name: follows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE follows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: follows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE follows_id_seq OWNED BY follows.id;


--
-- Name: measurements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE measurements (
    id integer NOT NULL,
    subject_type character varying,
    subject_id integer,
    name character varying NOT NULL,
    value character varying NOT NULL,
    taken_at timestamp without time zone NOT NULL,
    taken_on date NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: measurements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE measurements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: measurements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE measurements_id_seq OWNED BY measurements.id;


--
-- Name: persistent_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE persistent_triggers (
    id integer NOT NULL,
    type character varying NOT NULL,
    value text NOT NULL,
    params text DEFAULT '{}'::text NOT NULL,
    action character varying NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: persistent_triggers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE persistent_triggers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: persistent_triggers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE persistent_triggers_id_seq OWNED BY persistent_triggers.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE projects (
    id integer NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    color_name character varying DEFAULT 'default'::character varying NOT NULL,
    retired_at timestamp without time zone,
    category character varying,
    version_control_name character varying DEFAULT 'None'::character varying NOT NULL,
    ticket_tracker_name character varying DEFAULT 'None'::character varying NOT NULL,
    ci_server_name character varying DEFAULT 'None'::character varying NOT NULL,
    error_tracker_name character varying DEFAULT 'None'::character varying,
    last_ticket_tracker_sync_at timestamp without time zone,
    ticket_tracker_sync_started_at timestamp without time zone,
    selected_features text[],
    head_sha character varying,
    props jsonb DEFAULT '{}'::jsonb,
    team_id integer
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE roles (
    id integer NOT NULL,
    user_id integer,
    project_id integer,
    name character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE teams (
    id integer NOT NULL,
    name character varying,
    props jsonb DEFAULT '{}'::jsonb
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE teams_id_seq OWNED BY teams.id;


--
-- Name: teams_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE teams_users (
    id integer NOT NULL,
    team_id integer,
    user_id integer,
    roles character varying[],
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: teams_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE teams_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE teams_users_id_seq OWNED BY teams_users.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    invitation_token character varying,
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_type character varying,
    invited_by_id integer,
    authentication_token character varying,
    first_name character varying,
    last_name character varying,
    retired_at timestamp without time zone,
    email_addresses text[],
    invitation_created_at timestamp without time zone,
    current_project_id integer,
    nickname character varying,
    username character varying,
    props jsonb DEFAULT '{}'::jsonb,
    role character varying DEFAULT 'Member'::character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE versions (
    id integer NOT NULL,
    versioned_type character varying,
    versioned_id integer,
    user_type character varying,
    user_id integer,
    user_name character varying,
    modifications text,
    number integer,
    reverted_from integer,
    tag character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE versions_id_seq OWNED BY versions.id;


--
-- Name: actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY actions ALTER COLUMN id SET DEFAULT nextval('actions_id_seq'::regclass);


--
-- Name: authorizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY authorizations ALTER COLUMN id SET DEFAULT nextval('authorizations_id_seq'::regclass);


--
-- Name: consumer_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY consumer_tokens ALTER COLUMN id SET DEFAULT nextval('consumer_tokens_id_seq'::regclass);


--
-- Name: errors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY errors ALTER COLUMN id SET DEFAULT nextval('errors_id_seq'::regclass);


--
-- Name: follows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY follows ALTER COLUMN id SET DEFAULT nextval('follows_id_seq'::regclass);


--
-- Name: measurements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY measurements ALTER COLUMN id SET DEFAULT nextval('measurements_id_seq'::regclass);


--
-- Name: persistent_triggers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY persistent_triggers ALTER COLUMN id SET DEFAULT nextval('persistent_triggers_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams ALTER COLUMN id SET DEFAULT nextval('teams_id_seq'::regclass);


--
-- Name: teams_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams_users ALTER COLUMN id SET DEFAULT nextval('teams_users_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: actions actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY actions
    ADD CONSTRAINT actions_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: authorizations authorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT authorizations_pkey PRIMARY KEY (id);


--
-- Name: consumer_tokens consumer_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY consumer_tokens
    ADD CONSTRAINT consumer_tokens_pkey PRIMARY KEY (id);


--
-- Name: errors errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY errors
    ADD CONSTRAINT errors_pkey PRIMARY KEY (id);


--
-- Name: follows follows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY follows
    ADD CONSTRAINT follows_pkey PRIMARY KEY (id);


--
-- Name: measurements measurements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY measurements
    ADD CONSTRAINT measurements_pkey PRIMARY KEY (id);


--
-- Name: persistent_triggers persistent_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY persistent_triggers
    ADD CONSTRAINT persistent_triggers_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: teams_users teams_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams_users
    ADD CONSTRAINT teams_users_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: index_actions_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_actions_on_name ON actions USING btree (name);


--
-- Name: index_authorizations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authorizations_on_user_id ON authorizations USING btree (user_id);


--
-- Name: index_consumer_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_consumer_tokens_on_token ON consumer_tokens USING btree (token);


--
-- Name: index_errors_on_sha; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_errors_on_sha ON errors USING btree (sha);


--
-- Name: index_follows_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_follows_on_project_id ON follows USING btree (project_id);


--
-- Name: index_follows_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_follows_on_user_id ON follows USING btree (user_id);


--
-- Name: index_measurements_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_measurements_on_name ON measurements USING btree (name);


--
-- Name: index_measurements_on_subject_type_and_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_measurements_on_subject_type_and_subject_id ON measurements USING btree (subject_type, subject_id);


--
-- Name: index_measurements_on_taken_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_measurements_on_taken_at ON measurements USING btree (taken_at);


--
-- Name: index_measurements_on_taken_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_measurements_on_taken_on ON measurements USING btree (taken_on);


--
-- Name: index_projects_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_projects_on_slug ON projects USING btree (slug);


--
-- Name: index_roles_on_user_id_and_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_user_id_and_project_id ON roles USING btree (user_id, project_id);


--
-- Name: index_roles_on_user_id_and_project_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_user_id_and_project_id_and_name ON roles USING btree (user_id, project_id, name);


--
-- Name: index_teams_users_on_team_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_teams_users_on_team_id_and_user_id ON teams_users USING btree (team_id, user_id);


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_authentication_token ON users USING btree (authentication_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_email_addresses; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_email_addresses ON users USING btree (email_addresses);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invitation_token ON users USING btree (invitation_token);


--
-- Name: index_users_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invited_by_id ON users USING btree (invited_by_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_versions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_created_at ON versions USING btree (created_at);


--
-- Name: index_versions_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_number ON versions USING btree (number);


--
-- Name: index_versions_on_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_tag ON versions USING btree (tag);


--
-- Name: index_versions_on_user_id_and_user_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_user_id_and_user_type ON versions USING btree (user_id, user_type);


--
-- Name: index_versions_on_user_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_user_name ON versions USING btree (user_name);


--
-- Name: index_versions_on_versioned_id_and_versioned_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_versioned_id_and_versioned_type ON versions USING btree (versioned_id, versioned_type);


--
-- Name: follows fk_rails_32479bd030; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY follows
    ADD CONSTRAINT fk_rails_32479bd030 FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: authorizations fk_rails_4ecef5b8c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT fk_rails_4ecef5b8c5 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: follows fk_rails_572bf69092; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY follows
    ADD CONSTRAINT fk_rails_572bf69092 FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20120324185914'),
('20120408155047'),
('20120417175450'),
('20120417175841'),
('20120417190504'),
('20120504143615'),
('20120525013703'),
('20120607124115'),
('20120715230922'),
('20120726231754'),
('20120823025935'),
('20120826022643'),
('20120827190634'),
('20120913020218'),
('20120920023251'),
('20120922010212'),
('20121026014457'),
('20121126005019'),
('20121219202734'),
('20121222170917'),
('20121222223325'),
('20121222223635'),
('20121230173644'),
('20130105200429'),
('20130119203853'),
('20130302205014'),
('20130312224911'),
('20130407195450'),
('20130407200624'),
('20130416020627'),
('20130420151334'),
('20130420155332'),
('20130420172322'),
('20130420174002'),
('20130420174126'),
('20130428005808'),
('20130504014802'),
('20130518224406'),
('20130518224722'),
('20130706141443'),
('20130728191005'),
('20130914155044'),
('20131002005512'),
('20131002015547'),
('20131216014505'),
('20140106212047'),
('20140106212305'),
('20140217150735'),
('20140217160450'),
('20140406183224'),
('20140411214022'),
('20140419152214'),
('20140429000919'),
('20140516005310'),
('20140517012626'),
('20140606232907'),
('20140907013836'),
('20140921201441'),
('20141027194819'),
('20141226171730'),
('20150116153233'),
('20150222205616'),
('20150222214124'),
('20150223013721'),
('20150302153319'),
('20151201042126'),
('20151202005557'),
('20151202011812'),
('20151205204922'),
('20151228183704'),
('20160317140151'),
('20160419230411'),
('20160420000616'),
('20160507135209'),
('20160507135846'),
('20160625203412'),
('20160625221840'),
('20160625230420'),
('20160711170921'),
('20160713204605'),
('20160715173039'),
('20160812233255'),
('20160813001242'),
('20160814024129'),
('20160916191300'),
('20161102012059'),
('20161102012231'),
('20170115150643'),
('20170116002818'),
('20170116210225'),
('20170118005958'),
('20170130011016'),
('20170205004452'),
('20170206002030'),
('20170206002732'),
('20170209022159'),
('20170213001453'),
('20170215012012'),
('20170216041034'),
('20170226201504'),
('20170301014051'),
('20170307032041'),
('20170307035755');


