WITH
	columns
AS( --Function wich excludes preinserted Tables from the query
	SELECT columns.*
	FROM	
		information_schema.columns
		LEFT JOIN
			public.table_ignore ON
			columns.table_name = table_ignore.table_name
	WHERE
		table_schema = 'public' AND
		ignore IS NULL
),
	number_of_columns_in_constraint
AS ( --Function which counts the colums of a constraint on a table (for array-class purpose)
	SELECT key_column_usage.table_name, key_column_usage.constraint_name, count(*) as number_of_columns
	FROM
		information_schema.key_column_usage
		LEFT JOIN
			public.table_ignore ON key_column_usage.table_name = table_ignore.table_name
	WHERE
		key_column_usage.table_schema = 'public'
		AND
		table_ignore.ignore IS NULL
	GROUP BY key_column_usage.constraint_name,
		key_column_usage.table_name
)

INSERT
	into public.cs_class
SELECT --DISTINCT
	nextval('cs_class_Sequence'),-- as id,
	columns.table_name,-- as name,
	'''',-- as descr,
	1,-- as class_icon_id,
	1,-- as object_icon_id,
	upper(columns.table_name),-- as table_name,
	max(columns.column_name),-- as primary_key,
	FALSE,-- as indexed,
	NULL,-- as tostring,
	NULL,-- as editor,                   					  ____________   _______<'___   ____________   ____________
	NULL,-- as renderer,       				 		 /-=h======h= |0| =h======h= |0| =h======h= |0| =h======h=-\
	(max( nocic.number_of_columns ) > 1 ),-- '?' as array_link, --TODO   	`-oo--------oo´ `oo--------oo´ `oo--------oo´ `oo--------oo-´
	NULL,-- as policy,				-- There can't be any error by not having constraints in a table, beacause every table in cids must have an id as primary key.
	NULL-- as attribute_policy
FROM
	columns
	LEFT JOIN number_of_columns_in_constraint as nocic
		ON columns.table_name = nocic.table_name,
	information_schema.constraint_column_usage as prime_ccu,
	information_schema.table_constraints as prime_tc
WHERE
	columns.table_schema = 'public' AND
	columns.table_name = prime_ccu.table_name AND
	columns.column_name = prime_ccu.column_name AND
	prime_ccu.constraint_name = prime_tc.constraint_name AND
	prime_tc.constraint_type = 'PRIMARY KEY'
GROUP BY 
	columns.table_name
ORDER BY
	columns.table_name