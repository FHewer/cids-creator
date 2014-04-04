cids-creator
============

A bunch of PostgreSQL scripts that allow to automatically fill cids classes with a database structure. It uses the information_schema of the postgreSQL database to get the tables, columns and constrains and uses them to form insertable values for the cs_class, cs_type and cs_attr classes. To properbly recognice array-classes the array link has to be a foreign key on itself and the two array values need to be in a single UNIQUE-constraint.


To import the datastructure into cids follow these steps

1. install "postgis" and "postgis_topology" plugins  in postgres

2. create cids tables (cids_init)

3. execute "create_update_table_ignore"

4. create tables

5. execute "into cs_class"
6. execute "into cs_type"
7. execute "into cs_attr"

It's done


Conditions for a succesfull import:

Every 1:1 relation needs:
1. A foreign key to the target table (one way)

Every n:m relation needs:
1. The array-link is a foreign key on the own class.
2. The array-class needs a foreign key to both the array-link and the target.
3. both array-values need to be in ONE unique constraint together.
4. The array-class hast to stand as comment in the array-link field.
