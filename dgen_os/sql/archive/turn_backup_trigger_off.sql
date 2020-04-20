UPDATE backups.tables
set (to_backup, skip_trigger) = (False, true)
where table_schema = 'diffusion_wind'
and table_name = 'unique_rate_gen_load_combinations';

UPDATE backups.tables
set (to_backup, skip_trigger) = (False, true)
where table_schema = 'diffusion_solar'
and table_name = 'unique_rate_gen_load_combinations';