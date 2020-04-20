
DROP FUNCTION IF EXISTS diffusion_shared.get_dependencies(target_schema_name text, target_view_name text);
CREATE OR REPLACE FUNCTION diffusion_shared.get_dependencies(target_schema_name text, target_view_name text) 
RETURNS TABLE(dependency_tree text)
AS $function$
	with recursive view_tree(parent_schema, parent_obj, child_schema, child_obj) as 
	(
	  select vtu_parent.view_schema, vtu_parent.view_name, 
	    vtu_parent.table_schema, vtu_parent.table_name
	  from information_schema.view_table_usage vtu_parent
	  where vtu_parent.view_schema = target_schema_name
		and vtu_parent.view_name = target_view_name
	  union all
	  select vtu_child.view_schema, vtu_child.view_name, 
	    vtu_child.table_schema, vtu_child.table_name
	  from view_tree vtu_parent, information_schema.view_table_usage vtu_child
	  where vtu_child.view_schema = vtu_parent.child_schema 
	  and vtu_child.view_name = vtu_parent.child_obj
	) 
	select a.child_obj
	from view_tree a
	LEFT JOIN information_schema.TABLES b
	ON a.child_schema = b.table_schema
	and a.child_obj = b.table_name
	where b.table_type = 'VIEW';
$function$ 
LANGUAGE sql VOLATILE;


select diffusion_shared.get_dependencies('diffusion_template', 'input_main_nem_bau_scenario');


-- with a as
-- (
-- 	select TABLE_NAME::text, get_dependencies('diffusion_template', table_name)
-- 	FROM information_schema.TABLES 
-- 	WHERE table_schema = 'diffusion_template' 
-- 		and table_type = 'VIEW'
-- 	ORDER BY table_name ASC
-- ),
-- b as
-- (
-- 	select table_name, count(*) as count_dependents
-- 	FROM a
-- 	group by table_name
-- ),
-- c as
-- (
-- 	select a.table_name, coalesce(b.count_dependents, 0) as count_dependents
-- 	from information_schema.TABLES a
-- 	LEFT JOIN b
-- 	ON a.table_name = b.table_name
-- 	WHERE a.table_schema = 'diffusion_template' 
-- 		and table_type = 'VIEW'
-- )
-- SELECT table_name
-- from c
-- order by count_dependents asc;

	


