
CREATE TABLE IF NOT EXISTS table_ignore ( -- This table contains all tables in the 'public' schema at the time this query is executed
	table_name text NOT NULL, 
	ignore boolean,
	CONSTRAINT ignore_pk PRIMARY KEY (table_name)
	
);

INSERT into
	table_ignore
	SELECT DISTINCT
		columns.table_name,
		TRUE
	FROM
		information_schema.columns
		LEFT JOIN
			table_ignore ON columns.table_name = table_ignore.table_name
	WHERE
		table_schema = 'public' AND
		table_ignore.ignore IS NULL
