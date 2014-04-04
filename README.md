cids-creator
============

A bunch of PostgreSQL scripts that allow to automatically fill cids classes with a database structure. It uses the information_schema of the postgreSQL database to get the tables, columns and constrains and uses them to form insertable values for the cs_class, cs_type and cs_attr classes. To properbly recognice array-classes the array link has to be a foreign key on itself and the two array values need to be in a single UNIQUE-constraint.
