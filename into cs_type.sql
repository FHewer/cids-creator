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
)

INSERT
	into public.cs_type

SELECT DISTINCT
	nextval('cs_type_sequence'),-- as id,
	upper(columns.table_name), --as name,
	max(cs_class.id), --as class_id,
	FALSE, --as complex_type,
	max(cs_class.descr),--as descr              	                                  
	NULL::integer, --as editor, 	       __________________   _______________<>_   __________________   __________________
	NULL::integer --as renderer	      /-´ h==========h== |0| ==h==========h== |0| ==h==========h== |0| ==h==========h `-\
	                  --                 `-oo--------------oo´ `oo--------------oo´ `oo--------------oo´ `oo--------------oo-´
FROM
	columns,
	public.cs_class
WHERE
	columns.table_schema = 'public' AND
	columns.table_name = cs_class.name
GROUP BY 
	upper(columns.table_name)
ORDER BY
	upper(columns.table_name)