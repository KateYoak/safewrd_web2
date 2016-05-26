-- Convert schema 'share/ddl/_source/deploy/1/001-auto.yml' to 'share/ddl/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE pair ALTER COLUMN title DROP NOT NULL;

;
ALTER TABLE pair ALTER COLUMN parent_device_id DROP NOT NULL;

;
ALTER TABLE pair ALTER COLUMN child_device_id DROP NOT NULL;

;
ALTER TABLE pair ALTER COLUMN parent_user_id DROP NOT NULL;

;
ALTER TABLE pair ALTER COLUMN child_user_id DROP NOT NULL;

;
ALTER TABLE pair ALTER COLUMN kliq_id DROP NOT NULL;

;
ALTER TABLE pair ALTER COLUMN code DROP NOT NULL;

;

COMMIT;

