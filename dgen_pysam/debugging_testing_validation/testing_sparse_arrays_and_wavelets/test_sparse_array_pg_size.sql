
with a as
(
	select unnest(array['mgleason.sparse_data_pandas', 'mgleason.sparse_components',
	'mgleason.sparse_data_custom', 'mgleason.smallint_data', 'mgleason.regular_data',
	'mgleason.reg_int_unnest', 'mgleason.small_int_unnest']) as relation
)
select relation, pg_total_relation_size(relation) as size, pg_size_pretty(pg_total_relation_size(relation)) as pretty_size
from a
order by size desc;

