-- Convert schema 'share/ddl/_source/deploy/2/001-auto.yml' to 'share/ddl/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE contacts ALTER COLUMN handle TYPE character varying(255);

;
ALTER TABLE personas ALTER COLUMN handle TYPE character varying(255);

;

COMMIT;

