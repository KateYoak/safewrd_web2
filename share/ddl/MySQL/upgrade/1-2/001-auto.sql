-- Convert schema 'share/ddl/_source/deploy/1/001-auto.yml' to 'share/ddl/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE pair CHANGE COLUMN title title VARCHAR(255) NULL,
                 CHANGE COLUMN parent_device_id parent_device_id VARCHAR(36) NULL,
                 CHANGE COLUMN child_device_id child_device_id VARCHAR(36) NULL,
                 CHANGE COLUMN parent_user_id parent_user_id CHAR(36) NULL,
                 CHANGE COLUMN child_user_id child_user_id CHAR(36) NULL,
                 CHANGE COLUMN kliq_id kliq_id CHAR(36) NULL,
                 CHANGE COLUMN code code CHAR(8) NULL;

;

COMMIT;

