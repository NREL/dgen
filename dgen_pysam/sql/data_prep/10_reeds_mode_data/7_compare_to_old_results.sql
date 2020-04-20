select a.pca_reg, a.tilt, a.azimuth,
round(a.h01::NUMERIC, 2) as h01, round(b.h01::NUMERIC, 2) as h01, CASE WHEN a.h01 = 0 THEN NULL ELSE round((a.h01/b.h01)::NUMERIC, 2) END as ratio_h01,
round(a.h02::NUMERIC, 2) as h02, round(b.h02::NUMERIC, 2) as h02, CASE WHEN a.h02 = 0 THEN NULL ELSE round((a.h02/b.h02)::NUMERIC, 2) END as ratio_h02,
round(a.h03::NUMERIC, 2) as h03, round(b.h03::NUMERIC, 2) as h03, CASE WHEN a.h03 = 0 THEN NULL ELSE round((a.h03/b.h03)::NUMERIC, 2) END as ratio_h03,
round(a.h04::NUMERIC, 2) as h04, round(b.h04::NUMERIC, 2) as h04, CASE WHEN a.h04 = 0 THEN NULL ELSE round((a.h04/b.h04)::NUMERIC, 2) END as ratio_h04,
round(a.h05::NUMERIC, 2) as h05, round(b.h05::NUMERIC, 2) as h05, CASE WHEN a.h05 = 0 THEN NULL ELSE round((a.h05/b.h05)::NUMERIC, 2) END as ratio_h05,
round(a.h06::NUMERIC, 2) as h06, round(b.h06::NUMERIC, 2) as h06, CASE WHEN a.h06 = 0 THEN NULL ELSE round((a.h06/b.h06)::NUMERIC, 2) END as ratio_h06,
round(a.h07::NUMERIC, 2) as h07, round(b.h07::NUMERIC, 2) as h07, CASE WHEN a.h07 = 0 THEN NULL ELSE round((a.h07/b.h07)::NUMERIC, 2) END as ratio_h07,
round(a.h08::NUMERIC, 2) as h08, round(b.h08::NUMERIC, 2) as h08, CASE WHEN a.h08 = 0 THEN NULL ELSE round((a.h08/b.h08)::NUMERIC, 2) END as ratio_h08,
round(a.h09::NUMERIC, 2) as h09, round(b.h09::NUMERIC, 2) as h09, CASE WHEN a.h09 = 0 THEN NULL ELSE round((a.h09/b.h09)::NUMERIC, 2) END as ratio_h09,
round(a.h10::NUMERIC, 2) as h10, round(b.h10::NUMERIC, 2) as h10, CASE WHEN a.h10 = 0 THEN NULL ELSE round((a.h10/b.h10)::NUMERIC, 2) END as ratio_h10,
round(a.h11::NUMERIC, 2) as h11, round(b.h11::NUMERIC, 2) as h11, CASE WHEN a.h11 = 0 THEN NULL ELSE round((a.h11/b.h11)::NUMERIC, 2) END as ratio_h11,
round(a.h12::NUMERIC, 2) as h12, round(b.h12::NUMERIC, 2) as h12, CASE WHEN a.h12 = 0 THEN NULL ELSE round((a.h12/b.h12)::NUMERIC, 2) END as ratio_h12,
round(a.h13::NUMERIC, 2) as h13, round(b.h13::NUMERIC, 2) as h13, CASE WHEN a.h13 = 0 THEN NULL ELSE round((a.h13/b.h13)::NUMERIC, 2) END as ratio_h13,
round(a.h14::NUMERIC, 2) as h14, round(b.h14::NUMERIC, 2) as h14, CASE WHEN a.h14 = 0 THEN NULL ELSE round((a.h14/b.h14)::NUMERIC, 2) END as ratio_h14,
round(a.h15::NUMERIC, 2) as h15, round(b.h15::NUMERIC, 2) as h15, CASE WHEN a.h15 = 0 THEN NULL ELSE round((a.h15/b.h15)::NUMERIC, 2) END as ratio_h15,
round(a.h16::NUMERIC, 2) as h16, round(b.h16::NUMERIC, 2) as h16, CASE WHEN a.h16 = 0 THEN NULL ELSE round((a.h16/b.h16)::NUMERIC, 2) END as ratio_h16,
round(a.h17::NUMERIC, 2) as h17, round(b.h17::NUMERIC, 2) as h17, CASE WHEN a.h17 = 0 THEN NULL ELSE round((a.h17/b.h17)::NUMERIC, 2) END as ratio_h17


from diffusion_solar.solar_resource_by_pca_summary a
left join diffusion_solar.reeds_solar_resource_by_pca_summary_wide b
ON a.pca_reg = b.pca_reg
and a.tilt = b.tilt
and a.azimuth = b.azimuth;

-- results for some timeslices sometimes off in the range of 0.05-0.09 absolute
-- this is potentially due to ben mistakenly applying the derate factor when he didn't need to
-- and then also pvwatts5 sam improvements