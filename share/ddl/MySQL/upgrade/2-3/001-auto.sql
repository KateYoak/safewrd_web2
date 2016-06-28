-- Convert schema 'share/ddl/_source/deploy/2/001-auto.yml' to 'share/ddl/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE contacts CHANGE COLUMN handle handle varchar(255) NOT NULL;

;
ALTER TABLE personas CHANGE COLUMN handle handle varchar(255) NOT NULL;

;

COMMIT;

