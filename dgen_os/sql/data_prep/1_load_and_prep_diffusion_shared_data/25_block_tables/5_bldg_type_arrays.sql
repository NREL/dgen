set role 'diffusion-writers';

------------------------------------------------------------------------------------------
-- create table
DROP TABLE IF EXISTS diffusion_blocks.bldg_type_arrays;
CREATE TABLE diffusion_blocks.bldg_type_arrays
(
	sector_abbr varchar(3) primary key,
	bldg_types text[]
);

INSERT INTO diffusion_blocks.bldg_type_arrays
select 'all', ARRAY[
		'agr1', 'com1', 'com10', 'com2', 'com3', 
		'com4', 'com5', 'com6', 'com7', 'com8', 
		'com9', 'edu1', 'edu2', 'gov1', 'gov2', 
		'ind1', 'ind2', 'ind3', 'ind4', 'ind5', 
		'ind6', 'rel1', 'res1', 'res2', 'res3a', 
		'res3b', 'res3c', 'res3d', 'res3e', 'res3f',
		'res4', 'res5', 'res6'
	     ];


INSERT INTO diffusion_blocks.bldg_type_arrays
select 'res', ARRAY[
		'res1', 'res2', 'res3a', 'res3b', 'res3c', 
		'res3d', 'res3e', 'res3f'
	     ];	

INSERT INTO diffusion_blocks.bldg_type_arrays
select 'com', ARRAY[
		'res4', 'res5', 'res6', 'com1', 'com2', 
		'com3', 'com4', 'com5', 'com6', 'com7', 
		'com8', 'com9', 'com10', 'rel1', 'gov1', 
		'gov2', 'edu1', 'edu2'
	     ];	

INSERT INTO diffusion_blocks.bldg_type_arrays
select 'ind', ARRAY[
		'ind1', 'ind2', 'ind3', 'ind4', 'ind5', 
		'agr1'
	     ];		 

INSERT INTO diffusion_blocks.bldg_type_arrays
select 'mfg', ARRAY[
		'ind1', 'ind2', 'ind3', 'ind4', 'ind5'
	     ];		


INSERT INTO diffusion_blocks.bldg_type_arrays
select 'ag', ARRAY[
		'agr1'
	     ];		

------------------------------------------------------------------------------------------
-- QA/QC

-- check results
select *
FROM diffusion_blocks.bldg_type_arrays;