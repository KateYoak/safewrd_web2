Following is how I have done backups of the schema and data for the kliq21
MySQL database, the one currently in use by the production code (it isn't
the kliq2 database, like some of the other, outdated documentation states).

date ; mysqldump --skip-opt --databases --user=kliq_SSM --password=self-expression --single-transaction --skip-dump-date --set-charset --no-data --create-options --routines kliq21 | gzip > kliq21_schema.sql.gz ; date

date ; mysqldump --skip-opt --databases --user=kliq_SSM --password=self-expression --single-transaction --skip-dump-date --set-charset --no-create-info --skip-triggers --add-locks --complete-insert --extended-insert --quick kliq21 | gzip > kliq21_data.sql.gz ; date

The first file alone or both files together are also suitable for creating
a clone of the database in either development or production.  Unlike the
default mysqldump settings, these ones should be more reliable in dump
quality and also should produce identical output when the database hasn't
changed (no dump timestamps).

Note that as of 2016-01-28, the dump/backup schema file is 3KB/18KB
compressed/raw and the data file is 8.6MB/45.2MB.

