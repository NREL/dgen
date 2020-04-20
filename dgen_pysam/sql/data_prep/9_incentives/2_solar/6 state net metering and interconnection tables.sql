CREATE TABLE diffusion_shared."nem_scenario_bau_2017"
(
    state_abbr char(2),
    sector_abbr char(3),
    pv_kw_limit double precision,
    pv_pctload_limit double precision,
    rec_ownership char(25),
    compensation_style varchar(50),
    sell_value double precision,
    first_year int,
    sunset_year int
);

ALTER TABLE diffusion_template.nem_scenario_bau_2017
    OWNER TO "diffusion-writers";

CREATE TABLE diffusion_shared."nem_state_limits_2017"
(
    state_abbr char(2),
    max_cum_capacity_mw double precision,
    max_pct_cum_capacity double precision,
    max_reference_year varchar(25),
    first_year int,
    sunset_year int
);

ALTER TABLE diffusion_template.nem_state_limits_2017
    OWNER TO "diffusion-writers";

CREATE TABLE diffusion_template."input_main_nem_user_defined_state_limits_2017"
(
    state_abbr char(2),
    max_cum_capacity_mw double precision,
    max_pct_cum_capacity double precision,
    max_reference_year varchar(25),
    first_year int,
    sunset_year int
);

ALTER TABLE diffusion_template.input_main_nem_user_defined_state_limits_2017
    OWNER TO "diffusion-writers";


CREATE TABLE diffusion_shared."state_interconnection_grades"
(
    year int,
    state_abbr char(2),
    grade char(2)
);

ALTER TABLE diffusion_template.state_interconnection_grades
    OWNER TO "diffusion-writers";


CREATE TABLE diffusion_shared."state_nem_grades"
(
    year int,
    state_abbr char(2),
    grade char(2)
);

ALTER TABLE diffusion_template.state_nem_grades
    OWNER TO "diffusion-writers";

CREATE TABLE diffusion_template."input_main_nem_user_defined_res"
(
    state_abbr char(2),
    pv_kw_limit double precision,
    pv_pctload_limit double precision,
    compensation_style varchar(50),
    sell_value double precision,
    first_year int,
    sunset_year int
);

ALTER TABLE diffusion_template.input_main_nem_user_defined_res
    OWNER TO "diffusion-writers";

CREATE TABLE diffusion_template."input_main_nem_user_defined_com"
(
    state_abbr char(2),
    pv_kw_limit double precision,
    pv_pctload_limit double precision,
    compensation_style varchar(50),
    sell_value double precision,
    first_year int,
    sunset_year int
);

ALTER TABLE diffusion_template.input_main_nem_user_defined_com
    OWNER TO "diffusion-writers";


CREATE TABLE diffusion_template."input_main_nem_user_defined_ind"
(
    state_abbr char(2),
    pv_kw_limit double precision,
    pv_pctload_limit double precision,
    compensation_style varchar(50),
    sell_value double precision,
    first_year int,
    sunset_year int
);

ALTER TABLE diffusion_template.input_main_nem_user_defined_ind
    OWNER TO "diffusion-writers";

CREATE OR REPLACE VIEW diffusion_template.input_main_nem_user_defined_scenario_2017 AS
 WITH b AS (
         SELECT input_main_nem_user_defined_res.state_abbr,
            'res'::text AS sector_abbr,
            input_main_nem_user_defined_res.pv_kw_limit,
            input_main_nem_user_defined_res.compensation_style,
            input_main_nem_user_defined_res.sell_value,
            input_main_nem_user_defined_res.first_year,
            input_main_nem_user_defined_res.sunset_year
           FROM diffusion_template.input_main_nem_user_defined_res
        UNION ALL
         SELECT input_main_nem_user_defined_com.state_abbr,
            'com'::text AS sector_abbr,
            input_main_nem_user_defined_com.pv_kw_limit,
            input_main_nem_user_defined_com.compensation_style,
            input_main_nem_user_defined_com.sell_value,
            input_main_nem_user_defined_com.first_year,
            input_main_nem_user_defined_com.sunset_year
           FROM diffusion_template.input_main_nem_user_defined_com
        UNION ALL
         SELECT input_main_nem_user_defined_ind.state_abbr,
            'ind'::text AS sector_abbr,
            input_main_nem_user_defined_ind.pv_kw_limit,
            input_main_nem_user_defined_ind.compensation_style,
            input_main_nem_user_defined_ind.sell_value,
            input_main_nem_user_defined_ind.first_year,
            input_main_nem_user_defined_ind.sunset_year
           FROM diffusion_template.input_main_nem_user_defined_ind
        )
 SELECT b.state_abbr,
    b.sector_abbr,
    b.pv_kw_limit,
    b.compensation_style,
    b.sell_value,
    b.first_year,
    b.sunset_year
   FROM b;

ALTER TABLE diffusion_template.input_main_nem_state_by_sector_2017
    OWNER TO "diffusion-writers";

CREATE OR REPLACE VIEW diffusion_template.nem_state_limits_2017 AS
 SELECT nem_state_limits_2017.state_abbr,
    nem_state_limits_2017.max_cum_capacity_mw,
    nem_state_limits_2017.max_pct_cum_capacity,
    nem_state_limits_2017.max_reference_year,
    nem_state_limits_2017.first_year,
    nem_state_limits_2017.sunset_year
   FROM diffusion_shared.nem_state_limits_2017;

ALTER TABLE diffusion_template.nem_state_limits_2017
    OWNER TO "diffusion-writers";

CREATE OR REPLACE VIEW diffusion_template.input_main_nem_state_limits_2017 AS
  WITH a AS (
         SELECT
                nem_state_limits_2017.state_abbr,
                nem_state_limits_2017.max_cum_capacity_mw,
                nem_state_limits_2017.max_pct_cum_capacity,
                nem_state_limits_2017.max_reference_year,
                nem_state_limits_2017.first_year,
                nem_state_limits_2017.sunset_year,
                'BAU'::text AS scenario
           FROM diffusion_shared.nem_state_limits_2017
        UNION ALL
         SELECT
                nem_state_limits_2017.state_abbr,
                nem_state_limits_2017.max_cum_capacity_mw,
                nem_state_limits_2017.max_pct_cum_capacity,
                nem_state_limits_2017.max_reference_year,
                nem_state_limits_2017.first_year,
                nem_state_limits_2017.sunset_year,
                'Full Everywhere'::text AS scenario
           FROM diffusion_shared.nem_state_limits_2017
        UNION ALL
         SELECT
                nem_state_limits_2017.state_abbr,
                nem_state_limits_2017.max_cum_capacity_mw,
                nem_state_limits_2017.max_pct_cum_capacity,
                nem_state_limits_2017.max_reference_year,
                nem_state_limits_2017.first_year,
                nem_state_limits_2017.sunset_year,
                'None Everywhere'::text AS scenario
           FROM diffusion_shared.nem_state_limits_2017
        UNION ALL
         SELECT
                input_main_nem_user_defined_state_limits_2017.state_abbr,
                input_main_nem_user_defined_state_limits_2017.max_cum_capacity_mw,
                input_main_nem_user_defined_state_limits_2017.max_pct_cum_capacity,
                input_main_nem_user_defined_state_limits_2017.max_reference_year,
                input_main_nem_user_defined_state_limits_2017.first_year,
                input_main_nem_user_defined_state_limits_2017.sunset_year,
                'User-Defined'::text AS scenario
           FROM diffusion_template.input_main_nem_user_defined_state_limits_2017
        )
 SELECT
            a.state_abbr,
            a.max_cum_capacity_mw,
            a.max_pct_cum_capacity,
            a.max_reference_year,
            a.first_year,
            a.sunset_year
   FROM a
     JOIN diffusion_template.input_main_nem_selected_scenario b ON a.scenario = b.val;

ALTER TABLE diffusion_template.input_main_nem_state_limits_2017
    OWNER TO "diffusion-writers";



CREATE OR REPLACE VIEW diffusion_template.input_main_nem_state_by_sector_2017 AS
 WITH a AS (
         SELECT nem_scenario_bau_2017.state_abbr,
            nem_scenario_bau_2017.sector_abbr,
            nem_scenario_bau_2017.pv_kw_limit,
            nem_scenario_bau_2017.compensation_style,
            nem_scenario_bau_2017.sell_rate,
            nem_scenario_bau_2017.first_year,
            nem_scenario_bau_2017.sunset_year,
            'BAU'::text AS scenario
           FROM diffusion_shared.nem_scenario_bau_2017
        UNION ALL
         SELECT nem_scenario_bau_2017.state_abbr,
            nem_scenario_bau_2017.sector_abbr,
            'Infinity'::double precision AS pv_kw_limit,
            nem_scenario_bau_2017.compensation_style,
            nem_scenario_bau_2017.sell_rate,
            nem_scenario_bau_2017.first_year,
            nem_scenario_bau_2017.sunset_year,
            'Full Everywhere'::text AS scenario
           FROM diffusion_shared.nem_scenario_bau_2017
        UNION ALL
         SELECT nem_scenario_bau_2017.state_abbr,
            nem_scenario_bau_2017.sector_abbr,
            0::double precision AS pv_kw_limit,
            nem_scenario_bau_2017.compensation_style,
            nem_scenario_bau_2017.sell_rate,
            nem_scenario_bau_2017.first_year,
            nem_scenario_bau_2017.sunset_year,
            'None Everywhere'::text AS scenario
           FROM diffusion_shared.nem_scenario_bau_2017
        UNION ALL
         SELECT input_main_nem_user_defined_scenario_2017.state_abbr,
            input_main_nem_user_defined_scenario_2017.sector_abbr,
            input_main_nem_user_defined_scenario_2017.pv_kw_limit,
            input_main_nem_user_defined_scenario_2017.compensation_style,
            input_main_nem_user_defined_scenario_2017.sell_rate,
            input_main_nem_user_defined_scenario_2017.first_year,
            input_main_nem_user_defined_scenario_2017.sunset_year,
            'User-Defined'::text AS scenario
           FROM diffusion_template.input_main_nem_user_defined_scenario_2017
        )
 SELECT a.state_abbr,
    a.sector_abbr,
    a.pv_kw_limit,
    a.compensation_style,
    a.sell_rate,
    a.first_year,
    a.sunset_year,
    a.scenario
   FROM a

ALTER TABLE diffusion_template.input_main_nem_state_by_sector_2017
    OWNER TO "diffusion-writers";

CREATE TABLE diffusion_shared.state_incentives_2017
(
    state_abbr varchar,
    sector_abbr varchar,
    tech varchar,
    incentive_type varchar,
    min_kw double precision,
    max_kw double precision,
    pbi_usd_p_kwh double precision,
    min_incentive_usd double precision,
    max_incentive_usd double precision,
    cbi_usd_p_w double precision,
    ibi_pct double precision,
    budget_annual_usd double precision,
    budget_total_usd double precision,
    incentive_cap_annual_mw double precision,
    incentive_cap_total_mw double precision,
    incentive_duration_yrs double precision,
    start_date date,
    end_date date,
    cbi_usd_p_kwh double precision,
    max_incentive_pct double precision,
    min_incentive_pct double precision,
    max_kwh double precision,
    min_kwh double precision 
);

ALTER TABLE diffusion_shared.state_incentives_2017
    OWNER TO "diffusion-writers";


psql -c "\copy diffusion_shared.nem_scenario_bau_2017 FROM '~/Desktop/nem_2017.csv' delimiter ',' csv" -h atlas.nrel.gov -d dgen_db_fy17q2_merge
psql -c "\copy diffusion_shared.nem_state_limits_2017 FROM '~/Desktop/nem_state_limits_2017.csv' delimiter ',' csv" -h atlas.nrel.gov -d dgen_db_fy17q2_merge
psql -c "\copy diffusion_shared.state_nem_grades FROM '~/Desktop/NMGrades.csv' delimiter ',' csv" -h atlas.nrel.gov -d dgen_db_fy17q2_merge
psql -c "\copy diffusion_shared.state_interconnection_grades FROM '~/Desktop/ICGrades.csv' delimiter ',' csv" -h atlas.nrel.gov -d dgen_db_fy17q2_merge
