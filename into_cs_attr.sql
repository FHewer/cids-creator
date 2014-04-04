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
),
	keyvalues
as (SELECT --Function which provides a table where all columns have an attribute showing what kind of key they have (N = no key, P = Primary Key, F = Foreign key) Unique constraints are listed under no key.
	'N' as type,
	col.table_name,
	col.column_name,
	source.constraint_name,
	table_constraints.constraint_type,
	--source.table_name as schlüsselquelle_tabelle,
	--source.column_name as schlüsselquelle_spalte,
	target.table_name as target
	--target.column_name as schlüsselziel_spalte
FROM
	columns as col
	LEFT JOIN
		information_schema.key_column_usage as source ON 
			col.table_name = source.table_name AND 
			col.column_name = source.column_name
	LEFT JOIN
		information_schema.constraint_column_usage as target ON 
			source.constraint_name = target.constraint_name
	LEFT JOIN
		information_schema.table_constraints ON 
			source.constraint_name = table_constraints.constraint_name
	LEFT JOIN
		number_of_columns_in_constraint as nucic ON
			source.constraint_name = nucic.constraint_name
WHERE	
	col.table_schema='public' AND
	(source.constraint_name IS NULL OR (
	 NOT table_constraints.constraint_type ilike '%PRIMARY%' AND 
	 NOT table_constraints.constraint_type ilike '%FOREIGN%' AND
	 nucic.number_of_columns < 2)) --Used to filter the UNIQUE Constraints defining array classes...

UNION

SELECT 
	'P' as type,
	col.table_name ,
	col.column_name,
	source.constraint_name,
	table_constraints.constraint_type,
	--source.table_name as schlüsselquelle_tabelle,
	--source.column_name as schlüsselquelle_spalte,
	target.table_name as target
	--target.column_name as schlüsselziel_spalte
FROM
	columns as col
	LEFT JOIN
		information_schema.key_column_usage as source ON 
			col.table_name = source.table_name AND 
			col.column_name = source.column_name
	LEFT JOIN
		information_schema.constraint_column_usage as target ON 
			source.constraint_name = target.constraint_name AND
			source.table_name = target.table_name AND
			source.column_name = target.column_name
	LEFT JOIN
		information_schema.table_constraints ON 
			source.constraint_name = table_constraints.constraint_name
WHERE	
	col.table_schema='public' AND
	table_constraints.constraint_type ilike '%PRIMARY%'

UNION

SELECT 
	'F' as type,
	col.table_name,
	col.column_name,
	source.constraint_name,
	table_constraints.constraint_type,
	--source.table_name as schlüsselquelle_tabelle,
	--source.column_name as schlüsselquelle_spalte,
	target.table_name as target
	--target.column_name as schlüsselziel_spalte
FROM
	columns as col
	LEFT JOIN
		information_schema.key_column_usage as source ON 
			col.table_name = source.table_name AND 
			col.column_name = source.column_name
	LEFT JOIN
		information_schema.constraint_column_usage as target ON 
			source.constraint_name = target.constraint_name AND
			(source.table_name != target.table_name OR
			source.column_name != target.column_name)
	LEFT JOIN
		information_schema.table_constraints ON 
			source.constraint_name = table_constraints.constraint_name
WHERE	
	col.table_schema='public' AND
	table_constraints.constraint_type ilike '%FOREIGN%'
ORDER BY type
),
	descriptions 
as (SELECT --Used to reference the descriptions of columns
	columns.table_schema, 
	columns.table_name, 
	columns.column_name, 
	pg_description.description
FROM 
	pg_catalog.pg_statio_all_tables as all_tables --Some statistics table, used to get the id for the combination of a schema- and tablename 
	RIGHT JOIN pg_catalog.pg_description on       -- table wich contains the descriptions of columns, only referenced by the table id.
		pg_description.objoid = all_tables.relid
	RIGHT JOIN columns ON 			      -- join daescription and oids with the notinsertet columns to get the description for specific columns needed to recocnize array-links
		pg_description.objsubid=columns.ordinal_position AND
		columns.table_schema = all_tables.schemaname AND 
		columns.table_name = all_tables.relname
WHERE
	columns.table_schema = 'public'
),
	arrayseeker
as(SELECT --The arrayseeker seeks an array and returns table and column and target table, of the backlink
	descriptions.column_name as start_column,
	keyvalues.table_name,
	keyvalues.column_name,
	keyvalues.target
FROM
	keyvalues,
	descriptions
WHERE
	keyvalues.target = descriptions.table_name
	AND	
	keyvalues.table_name = descriptions.description
)

INSERT
	into public.cs_attr
( SELECT -- NO Key Columns
	nextval('cs_attr_sequence'),-- as id,
	cs_class.id,-- as class_id,
	cs_type.id,-- as type_id,
	columns.column_name,-- as name,
	columns.column_name,-- as field_name,
	FALSE,-- as foreign_key,
	FALSE,-- as substitute,
	NULL::integer,-- as foreign_key_references_to,
	'',-- as descr,
	TRUE,-- as visible,
	FALSE,-- as indexed,
	FALSE,-- as isArray,
	'',-- as array_key,
	NULL::integer,-- as editor,--   	       	  ______________                                                        _______   ________   _______  _______   ________   _______         ______________ ______________ ______________ ______________ ______________
	NULL::integer,-- as tostring,-- 	      	 /-h == == == h-\  |\__________/| |\__________/| |\__________/|  _______^____ \\__H  ==  H__// ____^__^____ \\__H  ==  H__// ____^_______  |            | |            | |            | |            | |            |
	NULL::integer,-- as complex_editor,--   	^-oo----------oo-^=^oo--------oo^=^oo--------oo^=^oo--------oo^=^oo-oo--oo-oo^    `------´    ^oo-oo--oo-oo^    `------´    ^oo-oo--oo-oo^=^oo--------oo^=^oo--------oo^=^oo--------oo^=^oo--------oo^=^oo--------oo^
	columns.is_nullable::boolean,-- as optional,
	NULL,-- as default_value,
	NULL::integer,-- as from_string,
	(columns.ordinal_position - 1),-- as pos,
	columns.character_maximum_length,
	NULL::integer,-- as scale,
	FALSE-- as extension_at
	
FROM
	public.cs_class,
	public.cs_type,
	columns
	INNER JOIN
		keyvalues ON 
			columns.table_name = keyvalues.table_name AND
			columns.column_name = keyvalues.column_name
WHERE
	columns.table_schema = 'public'
	AND
	columns.udt_name ilike cs_type.name
	AND
	columns.table_name = cs_class.name
	AND
	keyvalues.type = 'N'
)
UNION

(SELECT --Primary Key Columns
	nextval('cs_attr_sequence'),-- as id,
	cs_class.id,-- as class_id,
	cs_type.id,-- as type_id,
	columns.column_name,-- as name,
	columns.column_name,-- as field_name,
	FALSE,-- as foreign_key,
	FALSE,-- as substitute,
	NULL::integer,-- as foreign_key_references_to,
	'Primärschlüssel',-- as descr,
	FALSE,-- as visible,
	FALSE,-- as indexed,
	FALSE,-- as isArray,
	'',-- as array_key,
	NULL::integer,-- as editor,--   	       	  ______________                                                        _______   ________   _______                 _______   ________   _______         ______________ ______________ ______________
	NULL::integer,-- as tostring,-- 	      	 /-h == == == h-\  |\__________/| |\__________/| |\__________/|  _______^____ \\__H  ==  H__// ____^_______   _______^____ \\__H  ==  H__// ____^_______  |            | |            | |            |
	NULL::integer,-- as complex_editor,--   	^-oo----------oo-^=^oo--------oo^=^oo--------oo^=^oo--------oo^=^oo-oo--oo-oo^    `------´    ^oo-oo--oo-oo^=^oo-oo--oo-oo^    `------´    ^oo-oo--oo-oo^=^oo--------oo^=^oo--------oo^=^oo--------oo^
	columns.is_nullable::boolean,-- as optional,
	NULL,-- as default_value,
	NULL::integer,-- as from_string,
	(columns.ordinal_position - 1),-- as pos,
	columns.character_maximum_length,
	NULL::integer,-- as scale,
	FALSE-- as extension_at
	
FROM
	public.cs_class,
	public.cs_type,
	columns
	INNER JOIN
		keyvalues ON 
			columns.table_name = keyvalues.table_name AND
			columns.column_name = keyvalues.column_name
WHERE
	columns.table_schema = 'public'
	AND
	columns.udt_name ilike cs_type.name
	AND
	columns.table_name = cs_class.name
	AND
	keyvalues.type = 'P'
)
UNION

(SELECT --Foreign Key collumns (without backreference and array-link)
	nextval('cs_attr_sequence'),-- as id,
	cs_class.id,-- as class_id,
	cs_type.id,-- as type_id,
	columns.column_name,-- as name,
	columns.column_name,-- as field_name,
	TRUE,-- as foreign_key,-- In cids it is no foreign key, if it's the backlink of an array.
	FALSE,-- as substitute,
	cs_type.class_id,-- as foreign_key_references_to,
	'',-- as descr,
	TRUE,-- as visible,
	FALSE,-- as indexed,
	FALSE,-- as isArray,
	'',-- as array_key,
	NULL::integer,-- as editor,--   	       	  ______________                                                        _______   ________   _______         ______________ ______________ ______________
	NULL::integer,-- as tostring,-- 	      	 /-h == == == h-\  |\__________/| |\__________/| |\__________/|  _______^____ \\__H  ==  H__// ____^_______  |            | |            | |            | |\__________/| |\__________/| |\__________/|
	NULL::integer,-- as complex_editor,--   	^-oo----------oo-^=^oo--------oo^=^oo--------oo^=^oo--------oo^=^oo-oo--oo-oo^    `------´    ^oo-oo--oo-oo^=^oo--------oo^=^oo--------oo^=^oo--------oo^=^oo--------oo^=^oo--------oo^=^oo--------oo^
	columns.is_nullable::boolean,-- as optional,
	NULL,-- as default_value,
	NULL::integer,-- as from_string,
	(columns.ordinal_position - 1),-- as pos,
	columns.character_maximum_length,-- as precision,
	NULL::integer,-- as scale,
	FALSE-- as extension_at
	
FROM
	public.cs_class,
	public.cs_type,
	columns
	INNER JOIN
		keyvalues ON 
			columns.table_name = keyvalues.table_name AND
			columns.column_name = keyvalues.column_name
	INNER JOIN
		descriptions ON
			columns.table_name = descriptions.table_name AND
			columns.column_name = descriptions.column_name
	LEFT JOIN
		arrayseeker ON
			columns.table_name = arrayseeker.table_name
WHERE
	columns.table_schema = 'public'
	AND
	keyvalues.target ilike cs_type.name
	AND
	columns.table_name = cs_class.name
	AND
	keyvalues.type = 'F'
	AND
	descriptions.description IS NULL AND
	(NOT columns.column_name = arrayseeker.column_name OR arrayseeker.column_name IS NULL)
)
UNION

(SELECT DISTINCT--Array-Link Columns
	nextval('cs_attr_sequence'),-- as id,
	cs_class.id,-- as class_id,
	cs_type.id,-- as type_id,
	columns.column_name,-- as name,
	columns.column_name,-- as field_name,
	TRUE,-- as foreign_key,
	FALSE,-- as substitute,
	cs_type.class_id,-- as foreign_key_references_to,
	'',-- as descr,
	TRUE,-- as visible,
	FALSE,-- as indexed,
	TRUE,-- as isArray,
	arrayseeker.column_name,-- as array_key,
	NULL::integer,-- as editor,--   	       	  ______________                                                        _______   ________   _______         ______________ ______________ ______________ ______________ ______________ ______________
	NULL::integer,-- as tostring,-- 	      	 /-h == == == h-\  |\__________/| |\__________/| |\__________/|  _______^____ \\__H  ==  H__// ____^_______  |            | |            | |            | |            | |            | |            |
	NULL::integer,-- as complex_editor,--   	^-oo----------oo-^=^oo--------oo^=^oo--------oo^=^oo--------oo^=^oo-oo--oo-oo^    `------´    ^oo-oo--oo-oo^=^oo--------oo^=^oo--------oo^=^oo--------oo^=^oo--------oo^=^oo--------oo^=^oo--------oo^
	columns.is_nullable::boolean as optional,
	NULL,-- as default_value,
	NULL::integer,-- as from_string,
	(columns.ordinal_position - 1),-- as pos,
	columns.character_maximum_length,-- as precision,
	NULL::integer,-- as scale,
	FALSE-- as extension_at
	
FROM
	public.cs_class,
	public.cs_type,
	columns
	INNER JOIN
		keyvalues ON 
			columns.table_name = keyvalues.table_name AND
			columns.column_name = keyvalues.column_name
	INNER JOIN
		descriptions ON
			columns.table_name = descriptions.table_name AND
			columns.column_name = descriptions.column_name
	LEFT JOIN
		arrayseeker ON
			arrayseeker.target = columns.table_name AND
			arrayseeker.start_column = columns.column_name
	
WHERE
	columns.table_schema = 'public'
	AND
	descriptions.description ilike cs_type.name
	AND
	columns.table_name = cs_class.name
	AND
	keyvalues.type = 'F'
	AND
	NOT descriptions.description IS NULL
)	
UNION
(SELECT --backreference collumns
	nextval('cs_attr_sequence'),-- as id,
	cs_class.id,-- as class_id,
	2,-- as type_id,
	columns.column_name,-- as name,
	columns.column_name,-- as field_name,
	FALSE,-- as foreign_key,-- In cids it is no foreign key, if it's the backlink of an array.
	FALSE,-- as substitute,
	NULL::integer,-- as foreign_key_references_to,
	'',-- as descr,
	TRUE,-- as visible,
	FALSE,-- as indexed,
	FALSE,-- as isArray,
	'',-- as array_key,
	NULL::integer,-- as editor,--   	       	  ______________                                                        _______   ________   _______       
	NULL::integer,-- as tostring,-- 	      	 /-h == == == h-\  |\__________/| |\__________/| |\__________/|  _______^____ \\__H  ==  H__// ____^_______ 
	NULL::integer,-- as complex_editor,--   	^-oo----------oo-^=^oo--------oo^=^oo--------oo^=^oo--------oo^=^oo-oo--oo-oo^    `------´    ^oo-oo--oo-oo^
	columns.is_nullable::boolean,-- as optional,
	NULL,-- as default_value,
	NULL::integer,-- as from_string,
	(columns.ordinal_position - 1),-- as pos,
	columns.character_maximum_length,-- as precision,
	NULL::integer,-- as scale,
	FALSE-- as extension_at
	
FROM
	public.cs_class,
	public.cs_type,
	columns
	INNER JOIN
		keyvalues ON 
			columns.table_name = keyvalues.table_name AND
			columns.column_name = keyvalues.column_name
	INNER JOIN
		descriptions ON
			columns.table_name = descriptions.table_name AND
			columns.column_name = descriptions.column_name
	LEFT JOIN
		arrayseeker ON
			columns.table_name = arrayseeker.table_name
WHERE
	columns.table_schema = 'public'
	AND
	keyvalues.target ilike cs_type.name
	AND
	columns.table_name = cs_class.name
	AND
	keyvalues.type = 'F'
	AND
	descriptions.description IS NULL 
	AND
	columns.column_name = arrayseeker.column_name
)