CREATE OR REPLACE FUNCTION public.st_fishnet(geom geometry, cellsize double precision)
  RETURNS SETOF geometry AS
$BODY$
DECLARE 
  sql     TEXT;
  bbox   box2d;
  xmin numeric;
  xmax numeric;
  ymin numeric;
  ymax numeric;
  srid integer;
  rows integer;
  cols integer;
  
BEGIN

	select Box2d(geom) into bbox;
	select ST_XMin(bbox) into xmin;
	select ST_XMax(bbox) into xmax;
	SElect ST_YMin(bbox) into ymin;
	SELECT ST_Ymax(bbox) into ymax;
	SELECT ST_SRID(geom) into srid;
	select ceil((xmax-xmin)/cellsize) into cols;
	select ceil((ymax-ymin)/cellsize) into rows;
    sql := 'WITH
		a AS
		(
			SELECT ST_MakeEmptyRaster(' || cols::TEXT ||',
						   ' || rows::TEXT ||',
						   ' || xmin::TEXT ||',
						   ' || ymax::TEXT ||',
						   ' || cellsize::TEXT || '
						   ) as rast
		)

		SELECT ST_SetSrid((ST_PixelAsPolygons(rast)).geom, '|| srid::TEXT || ')
		FROM a;'
		;

	return QUERY execute sql;
  
END
$BODY$
  LANGUAGE plpgsql STABLE
  COST 100
  ROWS 1000;

