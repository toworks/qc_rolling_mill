--
-- PostgreSQL database cluster dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE "QCRollingMill";
ALTER ROLE "QCRollingMill" WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION PASSWORD 'md51b73ac45787260c6e0c84189d6437f32' VALID UNTIL 'infinity';
CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION PASSWORD 'md5c66a64714934f2ccd5909c1936254dcc';






--
-- Database creation
--

CREATE DATABASE "QCRollingMill" WITH TEMPLATE = template0 OWNER = "QCRollingMill";
REVOKE ALL ON DATABASE template1 FROM PUBLIC;
REVOKE ALL ON DATABASE template1 FROM postgres;
GRANT ALL ON DATABASE template1 TO postgres;
GRANT CONNECT ON DATABASE template1 TO PUBLIC;


\connect "QCRollingMill"

--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: fn_alarm(); Type: FUNCTION; Schema: public; Owner: QCRollingMill
--

CREATE FUNCTION fn_alarm() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
	IF (SELECT count(side) FROM alarm) = 0 THEN
		INSERT INTO alarm (aid,side,count,alarm) VALUES(0,0,0,0);
		INSERT INTO alarm (aid,side,count,alarm) VALUES(0,1,0,0);
        END IF;

	IF OLD.tid = NEW.tid  THEN
		IF (NEW.temperature < 
		   (select case when low is null then 0 else low end from calculated_data where cid=NEW.tid and step=0) or
		   NEW.temperature > 
		   (select case when high is null then 0 else high end from calculated_data where cid=NEW.tid and step=1))
		   and NEW.temperature > 270 THEN
			UPDATE alarm SET aid=NEW.tid, count=count+1 where side=NEW.side;
		ELSE
			UPDATE alarm SET aid=NEW.tid, count=0 where side=NEW.side;
		END IF;

		IF (select count from alarm where side=NEW.side) > 3 THEN
			UPDATE alarm SET alarm=1 where aid=NEW.tid and side=NEW.side;
		ELSE
			UPDATE alarm SET alarm=0 where aid=NEW.tid and side=NEW.side;
		END IF;
        END IF;
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION public.fn_alarm() OWNER TO "QCRollingMill";

--
-- Name: fn_bad_to_calculate(); Type: FUNCTION; Schema: public; Owner: QCRollingMill
--

CREATE FUNCTION fn_bad_to_calculate() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
	IF OLD.tid = NEW.tid AND OLD.strength_class <> NEW.strength_class THEN
		UPDATE temperature_current SET bad_to_calculate=1 where tid=NEW.tid;
        END IF;
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION public.fn_bad_to_calculate() OWNER TO "QCRollingMill";

--
-- Name: fn_temperature_historical(); Type: FUNCTION; Schema: public; Owner: QCRollingMill
--

CREATE FUNCTION fn_temperature_historical() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF  TG_OP = 'INSERT' THEN
	IF NEW.temperature > 260 THEN
		INSERT INTO temperature_historical(tid, timestamp, temperature, rolling_scheme) values (NEW.tid, NEW.timestamp, NEW.temperature, get_another_section(NEW.side));
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
	IF OLD.tid = NEW.tid AND OLD.temperature <> NEW.temperature AND NEW.temperature > 260 THEN
		INSERT INTO temperature_historical(tid, timestamp, temperature, rolling_scheme) values (NEW.tid, NEW.timestamp, NEW.temperature, get_another_section(NEW.side));
        END IF;
        RETURN NEW;        
    ELSIF TG_OP = 'DELETE' THEN
        DELETE FROM temperature_historical where temperature_historical.tid=OLD.tid;
        DELETE FROM calculated_data where calculated_data.cid=OLD.tid;
        RETURN OLD;        
    END IF;
END;
$$;


ALTER FUNCTION public.fn_temperature_historical() OWNER TO "QCRollingMill";

--
-- Name: get_another_section(integer); Type: FUNCTION; Schema: public; Owner: QCRollingMill
--

CREATE FUNCTION get_another_section(integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$
DECLARE
    GetSection numeric(3,1);
BEGIN
    RETURN (select section from temperature_current where side = $1 order by tid desc limit 1);
END;
$_$;


ALTER FUNCTION public.get_another_section(integer) OWNER TO "QCRollingMill";

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: alarm; Type: TABLE; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE TABLE alarm (
    count integer,
    alarm integer,
    aid integer,
    side integer
);


ALTER TABLE public.alarm OWNER TO "QCRollingMill";

--
-- Name: calculated_data; Type: TABLE; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE TABLE calculated_data (
    cid integer NOT NULL,
    "timestamp" integer,
    step smallint,
    coefficient_count integer,
    coefficient_yield_point_value numeric(3,2),
    coefficient_rupture_strength_value numeric(3,2),
    heat_to_work text,
    limit_rolled_products_min numeric(12,4),
    limit_rolled_products_max numeric(12,4),
    type_rolled_products character varying(26),
    mechanics_avg numeric(12,4),
    mechanics_std_dev numeric(12,4),
    mechanics_min numeric(12,4),
    mechanics_max numeric(12,4),
    mechanics_diff numeric(12,4),
    coefficient_min numeric(12,4),
    coefficient_max numeric(12,4),
    temp_avg numeric(12,4),
    temp_std_dev numeric(12,4),
    temp_min numeric(12,4),
    temp_max numeric(12,4),
    temp_diff numeric(12,4),
    r numeric(12,4),
    adjustment_min numeric(12,4),
    adjustment_max numeric(12,4),
    low smallint,
    high smallint,
    ce_min_down numeric(12,4),
    ce_min_up numeric(12,4),
    ce_max_down numeric(12,4),
    ce_max_up numeric(12,4),
    ce_avg numeric(12,4),
    ce_avg_down numeric(12,4),
    ce_avg_up numeric(12,4),
    ce_category character varying(26)
);


ALTER TABLE public.calculated_data OWNER TO "QCRollingMill";

--
-- Name: chemical_analysis; Type: TABLE; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE TABLE chemical_analysis (
    id bigint NOT NULL,
    "timestamp" integer NOT NULL,
    heat character varying(26) NOT NULL,
    date_external date NOT NULL,
    grade character varying(50),
    standard character varying(50),
    c numeric(6,4),
    mn numeric(6,4),
    si numeric(6,4),
    s numeric(6,4),
    cr numeric(6,4),
    b numeric(6,4)
);


ALTER TABLE public.chemical_analysis OWNER TO "QCRollingMill";

--
-- Name: chemical_analysis_id_seq; Type: SEQUENCE; Schema: public; Owner: QCRollingMill
--

CREATE SEQUENCE chemical_analysis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chemical_analysis_id_seq OWNER TO "QCRollingMill";

--
-- Name: chemical_analysis_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: QCRollingMill
--

ALTER SEQUENCE chemical_analysis_id_seq OWNED BY chemical_analysis.id;


--
-- Name: coefficient; Type: TABLE; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE TABLE coefficient (
    n integer NOT NULL,
    k_yield_point numeric(3,2) NOT NULL,
    k_rupture_strength numeric(3,2)
);


ALTER TABLE public.coefficient OWNER TO "QCRollingMill";

--
-- Name: technological_sample; Type: TABLE; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE TABLE technological_sample (
    id integer NOT NULL,
    grade character varying(50) NOT NULL,
    standard character varying(50) NOT NULL,
    strength_class character varying(50) NOT NULL,
    c_min numeric(3,2) NOT NULL,
    c_max numeric(3,2) NOT NULL,
    mn_min numeric(3,2) NOT NULL,
    mn_max numeric(3,2) NOT NULL,
    si_min numeric(3,2) NOT NULL,
    si_max numeric(3,2) NOT NULL,
    diameter_min integer NOT NULL,
    diameter_max integer NOT NULL,
    limit_min integer NOT NULL,
    limit_max integer NOT NULL,
    type character varying(50) NOT NULL
);


ALTER TABLE public.technological_sample OWNER TO "QCRollingMill";

--
-- Name: technological_sample_id_seq; Type: SEQUENCE; Schema: public; Owner: QCRollingMill
--

CREATE SEQUENCE technological_sample_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.technological_sample_id_seq OWNER TO "QCRollingMill";

--
-- Name: technological_sample_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: QCRollingMill
--

ALTER SEQUENCE technological_sample_id_seq OWNED BY technological_sample.id;


--
-- Name: temperature_current; Type: TABLE; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE TABLE temperature_current (
    tid integer NOT NULL,
    "timestamp" integer,
    heat character varying(26) NOT NULL,
    grade character varying(50),
    strength_class character varying(50),
    section numeric(3,1),
    standard character varying(50),
    side integer NOT NULL,
    temperature integer,
    bad_to_calculate smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.temperature_current OWNER TO "QCRollingMill";

--
-- Name: temperature_historical; Type: TABLE; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE TABLE temperature_historical (
    tid integer NOT NULL,
    "timestamp" integer,
    temperature integer,
    rolling_scheme integer
);


ALTER TABLE public.temperature_historical OWNER TO "QCRollingMill";

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: QCRollingMill
--

ALTER TABLE ONLY chemical_analysis ALTER COLUMN id SET DEFAULT nextval('chemical_analysis_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: QCRollingMill
--

ALTER TABLE ONLY technological_sample ALTER COLUMN id SET DEFAULT nextval('technological_sample_id_seq'::regclass);


--
-- Name: pk_chemical_analysis; Type: CONSTRAINT; Schema: public; Owner: QCRollingMill; Tablespace: 
--

ALTER TABLE ONLY chemical_analysis
    ADD CONSTRAINT pk_chemical_analysis PRIMARY KEY (id);


--
-- Name: pk_coefficient; Type: CONSTRAINT; Schema: public; Owner: QCRollingMill; Tablespace: 
--

ALTER TABLE ONLY coefficient
    ADD CONSTRAINT pk_coefficient PRIMARY KEY (n);


--
-- Name: pk_technological_sample; Type: CONSTRAINT; Schema: public; Owner: QCRollingMill; Tablespace: 
--

ALTER TABLE ONLY technological_sample
    ADD CONSTRAINT pk_technological_sample PRIMARY KEY (id);


--
-- Name: pk_temperature_current; Type: CONSTRAINT; Schema: public; Owner: QCRollingMill; Tablespace: 
--

ALTER TABLE ONLY temperature_current
    ADD CONSTRAINT pk_temperature_current PRIMARY KEY (tid);


--
-- Name: ik_asc_calculated_data; Type: INDEX; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE INDEX ik_asc_calculated_data ON calculated_data USING btree (cid, "timestamp", step);


--
-- Name: ik_asc_chemical_analysis; Type: INDEX; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE UNIQUE INDEX ik_asc_chemical_analysis ON chemical_analysis USING btree (id, heat, grade, standard, c, mn, si, s, cr, b);


--
-- Name: ik_asc_technological_sample; Type: INDEX; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE INDEX ik_asc_technological_sample ON technological_sample USING btree (id, grade, standard, strength_class, c_min, c_max, mn_min, mn_max, si_min, si_max, diameter_min, diameter_max, limit_min, limit_max, type);


--
-- Name: ik_asc_temperature_current; Type: INDEX; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE UNIQUE INDEX ik_asc_temperature_current ON temperature_current USING btree (tid, heat, "timestamp", strength_class, standard, side, grade);

ALTER TABLE temperature_current CLUSTER ON ik_asc_temperature_current;


--
-- Name: ik_asc_temperature_historical; Type: INDEX; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE INDEX ik_asc_temperature_historical ON temperature_historical USING btree (tid, "timestamp", rolling_scheme);


--
-- Name: ik_desc_calculated_data; Type: INDEX; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE INDEX ik_desc_calculated_data ON calculated_data USING btree (cid DESC, "timestamp" DESC, step DESC);


--
-- Name: ik_desc_chemical_analysis; Type: INDEX; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE UNIQUE INDEX ik_desc_chemical_analysis ON chemical_analysis USING btree (id DESC, heat DESC, grade DESC, standard DESC, c DESC, mn DESC, si DESC, s DESC, cr DESC, b DESC);


--
-- Name: ik_desc_technological_sample; Type: INDEX; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE INDEX ik_desc_technological_sample ON technological_sample USING btree (id DESC, grade DESC, standard DESC, strength_class DESC, c_min DESC, c_max DESC, mn_min DESC, mn_max DESC, si_min DESC, si_max DESC, diameter_min DESC, diameter_max DESC, limit_min DESC, limit_max DESC, type DESC);


--
-- Name: ik_desc_temperature_current; Type: INDEX; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE UNIQUE INDEX ik_desc_temperature_current ON temperature_current USING btree (tid DESC, heat DESC, grade DESC, "timestamp" DESC, strength_class DESC, standard DESC, side DESC);


--
-- Name: ik_desc_temperature_historical; Type: INDEX; Schema: public; Owner: QCRollingMill; Tablespace: 
--

CREATE INDEX ik_desc_temperature_historical ON temperature_historical USING btree (tid DESC, "timestamp" DESC, rolling_scheme DESC);

ALTER TABLE temperature_historical CLUSTER ON ik_desc_temperature_historical;


--
-- Name: tr_alarm; Type: TRIGGER; Schema: public; Owner: QCRollingMill
--

CREATE TRIGGER tr_alarm AFTER UPDATE ON temperature_current FOR EACH ROW EXECUTE PROCEDURE fn_alarm();


--
-- Name: tr_bad_to_calculate; Type: TRIGGER; Schema: public; Owner: QCRollingMill
--

CREATE TRIGGER tr_bad_to_calculate AFTER UPDATE ON temperature_current FOR EACH ROW EXECUTE PROCEDURE fn_bad_to_calculate();


--
-- Name: tr_temperature_historical; Type: TRIGGER; Schema: public; Owner: QCRollingMill
--

CREATE TRIGGER tr_temperature_historical AFTER INSERT OR DELETE OR UPDATE ON temperature_current FOR EACH ROW EXECUTE PROCEDURE fn_temperature_historical();


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

\connect postgres

--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: postgres; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

\connect template1

--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: template1; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE template1 IS 'default template for new databases';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database cluster dump complete
--

