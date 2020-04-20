-- change the table owner
set role 'diffusion-writers';

-- change the table name
DROP TABLE IF EXISTS diffusion_geo.egs_tract_id_alias_lkup;
ALTER TABLE diffusion_geo.egs_lkup
RENAME TO egs_tract_id_alias_lkup;

-- create indices
CREATE INDEX egs_tract_id_alias_lkup_btree_tract_id_alias
ON diffusion_geo.egs_tract_id_alias_lkup
USING BTREE(tract_id_alias);

CREATE INDEX egs_tract_id_alias_lkup_btree_cell_gid
ON diffusion_geo.egs_tract_id_alias_lkup
USING BTREE(cell_gid);

-- add primary key
ALTER TABLE diffusion_geo.egs_tract_id_alias_lkup
ADD PRIMARY KEY (tract_id_alias, cell_gid);

-- change the cell gid to integfer
ALTER TABLE diffusion_geo.egs_tract_id_alias_lkup
ALTER COLUMN cell_gid type integer using cell_gid::INTEGER;