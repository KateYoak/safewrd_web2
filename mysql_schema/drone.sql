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
CREATE TABLE mission (
  id char(36) NOT NULL,
  created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  from_location POINT,
  to_location POINT,  
  drone_id VARCHAR(100),
  event_id VARCHAR(100),  
  in_flight BOOLEAN DEFAULT FALSE,
  PRIMARY KEY(id),
  CONSTRAINT `constraint_fk_event_id` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`),
  CONSTRAINT `constraint_fk_drone_id` FOREIGN KEY (`drone_id`) REFERENCES `drone` (`id`)    
);

CREATE UNIQUE INDEX mission_in_flight_event_unique
  ON mission(event_id, in_flight)
  WHERE in_flight IS TRUE;
