set role 'diffusion-writers';
DROP TABLE IF EXISTS diffusion_shared.rate_type_desc_lkup;
CREATE TABLE diffusion_shared.rate_type_desc_lkup
(
	rate_type character varying(4) primary key,
	rate_type_desc text
);

INSERT INTO diffusion_shared.rate_type_desc_lkup
VALUES ('DT', 'Demand Tiered'),
	('D', 'Demand'),
	('DTOU', 'Demand Time of Use'),
	('TOU', 'Time of Use'),
	('F', 'Flat'),
	('TS', 'Tiered Seasonal'),
	('S', 'Seasonal'),
	('T', 'Tiered'),
	('UNK','Other');