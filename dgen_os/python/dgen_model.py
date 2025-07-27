"""
Distributed Generation Market Demand Model (dGen) - Open Source Release
National Renewable Energy Lab

This is the main module of the dGen Model. 
Running this module requires a properly installed environment with applicable scenario files. 
"""

import time
import os
import pandas as pd
import psycopg2.extras as pgx
import psycopg2.extensions
import pg8000.native
import numpy as np
import data_functions as datfunc
import utility_functions as utilfunc
import settings
import agent_mutation
import diffusion_functions_elec
import financial_functions
from functools import partial
import input_data_functions as iFuncs
import PySAM
import multiprocessing
from financial_functions import size_chunk, _init_worker
import logging
from sqlalchemy import event
from sqlalchemy.engine import Engine

# raise numpy and pandas warnings as exceptions
pd.set_option('mode.chained_assignment', None)
# Suppress pandas warnings
import warnings
warnings.simplefilter("ignore")

def main(mode=None, resume_year=None, endyear=None, ReEDS_inputs=None):
    model_settings = settings.init_model_settings()
    os.makedirs(model_settings.out_dir, exist_ok=True)
    logger = utilfunc.get_logger(os.path.join(model_settings.out_dir, 'dg_model.log'))
    print(f"Detected CPUs = {os.cpu_count()}, multiprocessing.cpu_count() = {multiprocessing.cpu_count()}", flush=True)
    print(f"model_settings.local_cores = {model_settings.local_cores}")

    con, cur = utilfunc.make_con(model_settings.pg_conn_string, model_settings.role)
    engine = utilfunc.make_engine(model_settings.pg_engine_string)

    if isinstance(con, psycopg2.extensions.connection):
        pgx.register_hstore(con)
    logger.info(f"Connected to Postgres with: {model_settings.pg_params_log}")
    owner = model_settings.role

    scenario_names = []
    dup_n = 1
    out_subfolders = {'wind': [], 'solar': []}

    for i, scenario_file in enumerate(model_settings.input_scenarios, start=1):
        scenario_start_time = round(time.time())
        logger.info('============================================')
        logger.info(f"Running Scenario {i} of {len(model_settings.input_scenarios)}")

        scenario_settings = settings.init_scenario_settings(scenario_file, model_settings, con, cur, i-1)
        scenario_settings.input_data_dir = model_settings.input_data_dir
        datfunc.summarize_scenario(scenario_settings, model_settings)

        input_scenario = scenario_settings.input_scenario
        scen_name = scenario_settings.scen_name
        out_scen_path, scenario_names, dup_n = datfunc.create_scenario_results_folder(
            input_scenario, scen_name, scenario_names, model_settings.out_dir, dup_n
        )
        scenario_settings.dir_to_write_input_data = os.path.join(out_scen_path, 'input_data')
        scenario_settings.scen_output_dir = out_scen_path
        os.makedirs(scenario_settings.dir_to_write_input_data, exist_ok=True)

        schema = scenario_settings.schema
        max_market_share = datfunc.get_max_market_share(con, schema)
        inflation_rate = datfunc.get_annual_inflation(con, schema)
        bass_params = datfunc.get_bass_params(con, schema)
        agent_file_status = scenario_settings.agent_file_status

        logger.info("--------------Creating Agents---------------")
        if scenario_settings.techs in [['wind'], ['solar']]:
            solar_agents = iFuncs.import_agent_file(
                scenario_settings, con, cur, engine, model_settings,
                agent_file_status, input_name='agent_file'
            )
            cols_base = list(solar_agents.df.columns)

        if scenario_settings.techs == ['solar']:
            # load all static inputs
            state_incentives = datfunc.get_state_incentives(con)
            itc_options = datfunc.get_itc_incentives(con, schema)
            nem_state_capacity_limits = datfunc.get_nem_state(con, schema)
            nem_state_and_sector_attributes = datfunc.get_nem_state_by_sector(con, schema)
            nem_utility_and_sector_attributes = datfunc.get_nem_utility_by_sector(con, schema)
            nem_selected_scenario = datfunc.get_selected_scenario(con, schema)
            rate_switch_table = agent_mutation.elec.get_rate_switch_table(con)

            if os.environ.get('PG_CONN_STRING'):
                deprec_sch = pd.read_sql_table(
                    "deprec_sch_FY19",
                    con=engine,
                    schema="diffusion_shared"
                )

                carbon_intensities = pd.read_sql_table(
                    "carbon_intensities_FY19",
                    con=engine,
                    schema="diffusion_shared"
                )

                wholesale_elec_prices = pd.read_sql_table(
                    "ATB23_Mid_Case_wholesale",
                    con=engine,
                    schema="diffusion_shared"
                )

                pv_tech_traj = pd.read_sql_table(
                    "pv_tech_performance_defaultFY19",
                    con=engine,
                    schema="diffusion_shared"
                )

                elec_price_change_traj = pd.read_sql_table(
                    "ATB23_Mid_Case_retail",
                    con=engine,
                    schema="diffusion_shared"
                )

                load_growth = pd.read_sql_table(
                    "load_growth_to_model_adjusted",
                    con=engine,
                    schema="diffusion_shared"
                )

                pv_price_traj = pd.read_sql_table(
                    "pv_price_atb23_mid",
                    con=engine,
                    schema="diffusion_shared"
                )

                batt_price_traj = pd.read_sql_table(
                    "batt_prices_FY23_mid",
                    con=engine,
                    schema="diffusion_shared"
                )

                pv_plus_batt_price_traj = pd.read_sql_table(
                    "pv_plus_batt_prices_FY23_mid",
                    con=engine,
                    schema="diffusion_shared"
                )

                financing_terms = pd.read_sql_table(
                    "financing_atb_FY23",
                    con=engine,
                    schema="diffusion_shared"
                )

                batt_tech_traj = pd.read_sql_table(
                    "batt_tech_performance_SunLamp17",
                    con=engine,
                    schema="diffusion_shared"
                )

                value_of_resiliency = pd.read_sql_table(
                    "vor_FY20_mid",
                    con=engine,
                    schema="diffusion_shared"
                )

            else:
                # ingest static tables once
                deprec_sch = iFuncs.import_table(scenario_settings, con, engine, owner,
                                                input_name='depreciation_schedules', csv_import_function=iFuncs.deprec_schedule)
                carbon_intensities = iFuncs.import_table(scenario_settings, con, engine, owner,
                                                        input_name='carbon_intensities', csv_import_function=iFuncs.melt_year('grid_carbon_intensity_tco2_per_kwh'))
                wholesale_elec_prices = iFuncs.import_table(scenario_settings, con, engine, owner,
                                                        input_name='wholesale_electricity_prices', csv_import_function=iFuncs.process_wholesale_elec_prices)
                pv_tech_traj = iFuncs.import_table(scenario_settings, con, engine, owner,
                                                input_name='pv_tech_performance', csv_import_function=iFuncs.stacked_sectors)
                elec_price_change_traj = iFuncs.import_table(scenario_settings, con, engine, owner,
                                                            input_name='elec_prices', csv_import_function=iFuncs.process_elec_price_trajectories)
                load_growth = iFuncs.import_table(scenario_settings, con, engine, owner,
                                                input_name='load_growth', csv_import_function=iFuncs.stacked_sectors)
                pv_price_traj = iFuncs.import_table(scenario_settings, con, engine, owner,
                                                input_name='pv_prices', csv_import_function=iFuncs.stacked_sectors)
                batt_price_traj = iFuncs.import_table(scenario_settings, con, engine, owner,
                                                    input_name='batt_prices', csv_import_function=iFuncs.stacked_sectors)
                pv_plus_batt_price_traj = iFuncs.import_table(scenario_settings, con, engine, owner,
                                                            input_name='pv_plus_batt_prices', csv_import_function=iFuncs.stacked_sectors)
                financing_terms = iFuncs.import_table(scenario_settings, con, engine, owner,
                                                    input_name='financing_terms', csv_import_function=iFuncs.stacked_sectors)
                batt_tech_traj = iFuncs.import_table(scenario_settings, con, engine, owner,
                                                    input_name='batt_tech_performance', csv_import_function=iFuncs.stacked_sectors)
                value_of_resiliency = iFuncs.import_table(scenario_settings, con, engine, owner,
                                                        input_name='value_of_resiliency', csv_import_function=None)

            # per-year loop
            for year in scenario_settings.model_years:
                logger.info(f'\tWorking on {year}')
                # reset new-year columns
                cols = list(solar_agents.df.columns)
                drop_cols = [c for c in cols if c not in cols_base]
                solar_agents.df.drop(drop_cols, axis=1, inplace=True)
                solar_agents.df['year'] = year
                is_first_year = (year == model_settings.start_year)

                # apply growth, rates, profiles, incentives…
                solar_agents.on_frame(agent_mutation.elec.apply_load_growth, [load_growth])
                cf_during_peak_demand = pd.read_csv('cf_during_peak_demand.csv')
                peak_demand_mw = pd.read_csv('peak_demand_mw.csv')
                if is_first_year:
                    last_year_installed_capacity = agent_mutation.elec.get_state_starting_capacities(con, schema)

                state_capacity_by_year = agent_mutation.elec.calc_state_capacity_by_year(
                    con, schema, load_growth, peak_demand_mw,
                    is_first_year, year, solar_agents, last_year_installed_capacity
                )
                net_metering_state_df, net_metering_utility_df = agent_mutation.elec.get_nem_settings(
                    nem_state_capacity_limits, nem_state_and_sector_attributes,
                    nem_utility_and_sector_attributes, nem_selected_scenario,
                    year, state_capacity_by_year, cf_during_peak_demand
                )
                solar_agents.on_frame(agent_mutation.elec.apply_export_tariff_params,
                                       [net_metering_state_df, net_metering_utility_df])
                solar_agents.on_frame(agent_mutation.elec.apply_elec_price_multiplier_and_escalator,
                                       [year, elec_price_change_traj])
                solar_agents.on_frame(agent_mutation.elec.apply_batt_tech_performance,
                                       [batt_tech_traj])
                solar_agents.on_frame(agent_mutation.elec.apply_pv_tech_performance,
                                       [pv_tech_traj])
                solar_agents.on_frame(agent_mutation.elec.apply_pv_prices,
                                       [pv_price_traj])
                solar_agents.on_frame(agent_mutation.elec.apply_batt_prices,
                                       [batt_price_traj, batt_tech_traj, year])
                solar_agents.on_frame(agent_mutation.elec.apply_pv_plus_batt_prices,
                                       [pv_plus_batt_price_traj, batt_tech_traj, year])
                solar_agents.on_frame(agent_mutation.elec.apply_value_of_resiliency,
                                       [value_of_resiliency])
                solar_agents.on_frame(agent_mutation.elec.apply_depreciation_schedule,
                                       [deprec_sch])
                solar_agents.on_frame(agent_mutation.elec.apply_carbon_intensities,
                                       [carbon_intensities])
                solar_agents.on_frame(agent_mutation.elec.apply_wholesale_elec_prices,
                                       [wholesale_elec_prices])
                solar_agents.on_frame(agent_mutation.elec.apply_financial_params,
                                       [financing_terms, itc_options, inflation_rate])
                solar_agents.on_frame(agent_mutation.elec.apply_state_incentives,
                                       [state_incentives, year, model_settings.start_year, state_capacity_by_year])

                # ── parallel system‐sizing ──
                if os.name == 'posix':
                    cores = model_settings.local_cores
                else:
                    cores = None
                print(f"Using {cores} cores for parallel processing", flush=True)

                if cores is None:
                    solar_agents.chunk_on_row(
                        financial_functions.calc_system_size_and_performance,
                        sectors=scenario_settings.sectors,
                        cores=None,
                        rate_switch_table=rate_switch_table
                    )
                else:
                    from multiprocessing import get_context, Manager

                    # build a spawn‐based Pool with a DB connection in each worker
                    ctx = get_context('spawn')
                    pool = ctx.Pool(
                        processes=cores,
                        initializer=_init_worker,
                        initargs=(model_settings.pg_conn_string, model_settings.role)
                    )

                    worker_pids = [p.pid for p in pool._pool]
                    logger.info(f"Spawned {len(worker_pids)} workers, PIDs={worker_pids}")

                    # drop any large or per‐hour columns before splitting
                    drop_cols = [c for c in solar_agents.df.columns if c.endswith('_hourly')]
                    static_df = solar_agents.df.drop(columns=drop_cols).copy()

                    # split by agent ID
                    all_ids      = static_df.index.tolist()
                    chunks       = np.array_split(all_ids, cores)
                    total_agents = len(all_ids)

                    tasks = [
                        (static_df.loc[chunk_ids], scenario_settings.sectors, rate_switch_table)
                        for chunk_ids in chunks
                    ]

                    logger.info(f"Sizing {total_agents} agents in {len(tasks)} chunks with {cores} workers")

                    # set up shared counters for progress tracking
                    manager          = Manager()
                    completed_chunks = manager.Value('i', 0)
                    processed_agents = manager.Value('i', 0)
                    lock             = manager.Lock()

                    def on_done(df_chunk):
                        # Update counters
                        with lock:
                            completed_chunks.value += 1
                            processed_agents.value += len(df_chunk)
                            pct = processed_agents.value / total_agents

                        print(
                            f"Processed {processed_agents.value}/{total_agents}, ({pct:.0%})",
                            flush=True
                        )
                        return df_chunk

                    # dispatch each chunk asynchronously
                    results = []
                    for args in tasks:
                        results.append(
                            pool.apply_async(size_chunk, args=args, callback=on_done)
                        )

                    pool.close()
                    pool.join()

                    # collect results and re‐assemble into one DataFrame
                    sized_chunks = [r.get() for r in results]
                    solar_agents.df = pd.concat(sized_chunks, axis=0)


                # downstream: max market share, developable load, market last year, diffusion…
                solar_agents.on_frame(financial_functions.calc_max_market_share, [max_market_share])
                solar_agents.on_frame(agent_mutation.elec.calculate_developable_customers_and_load)
                if is_first_year:
                    state_starting_capacities_df = agent_mutation.elec.get_state_starting_capacities(con, schema)
                    solar_agents.on_frame(agent_mutation.elec.estimate_initial_market_shares,
                                           [state_starting_capacities_df])
                    market_last_year_df = None
                else:
                    solar_agents.on_frame(agent_mutation.elec.apply_market_last_year,
                                           [market_last_year_df])

                solar_agents.df, market_last_year_df = diffusion_functions_elec.calc_diffusion_solar(
                    solar_agents.df, is_first_year, bass_params, year
                )
                solar_agents.on_frame(agent_mutation.elec.estimate_total_generation)

                last_year_installed_capacity = solar_agents.df[['state_abbr','system_kw_cum','batt_kw_cum','batt_kwh_cum','year']].copy()
                last_year_installed_capacity = last_year_installed_capacity.loc[last_year_installed_capacity['year'] == year]
                last_year_installed_capacity = last_year_installed_capacity.groupby('state_abbr')[['system_kw_cum','batt_kw_cum','batt_kwh_cum']].sum().reset_index()

                # write outputs… (same as original)
                drop_list = [f for f in [
                    'index','reeds_reg','customers_in_bin_initial',
                    'load_kwh_per_customer_in _bin_initial','load_kwh_in_bin_initial',
                    'sector','roof_adjustment','load_kwh_in_bin','naep',
                    'first_year_elec_bill_savings_frac','metric',
                    'developable_load_kwh_in_bin','initial_number_of_adopters',
                    'initial_pv_kw','initial_market_share','initial_market_value',
                    'market_value_last_year','teq_yr1','mms_fix_zeros','ratio',
                    'teq2','f','new_adopt_fraction','bass_market_share',
                    'diffusion_market_share','new_market_value','market_value',
                    'total_gen_twh','tariff_dict','deprec_sch','cash_flow',
                    'cbi','ibi','pbi','cash_incentives','state_incentives',
                    'export_tariff_results'
                ] if f in solar_agents.df.columns]
                df_write = solar_agents.df.drop(drop_list, axis=1)
                df_write.to_pickle(os.path.join(out_scen_path, f'agent_df_{year}.pkl'))
                mode = 'replace' if year == scenario_settings.model_years[0] else 'append'
                iFuncs.df_to_psql(df_write, engine, schema, owner,
                                    'agent_outputs', if_exists=mode, append_transformations=True)
                del df_write

            # teardown and finish
            logger.info("---------Saving Model Results---------")
            out_subfolders = datfunc.create_tech_subfolders(out_scen_path, scenario_settings.techs, out_subfolders)
            pool.close(); pool.join()

        if i < len(model_settings.input_scenarios):
            pass
        else:
            engine.dispose()
            con.close()
        datfunc.drop_output_schema(model_settings.pg_conn_string, schema, model_settings.delete_output_schema)
        scenario_endtime = round(time.time())
        logger.info(f"-------------Model Run Complete in {round(scenario_start_time-scenario_endtime,1)}s-------------")

if __name__ == '__main__':
    main()

