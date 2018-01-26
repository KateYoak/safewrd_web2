CREATE TABLE drone (
  id char(36) NOT NULL,
  created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  location POINT,
  in_flight BOOLEAN DEFAULT FALSE,
  vehicle_id VARCHAR(100),
  access_token TEXT,
  PRIMARY KEY(id),
  UNIQUE KEY vehicle_id_uniq (vehicle_id)
);
