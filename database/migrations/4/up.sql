PRAGMA user_version = 4;
PRAGMA foreign_keys = ON;

ALTER TABLE Product ADD COLUMN note TEXT;
ALTER TABLE Product ADD COLUMN minimum_sell_quantity REAL NOT NULL DEFAULT 0.0;
ALTER TABLE Product ADD COLUMN minimum_sell_violation_penalty REAL;

CREATE TABLE Plant (
    id INTEGER PRIMARY KEY,
    label TEXT NOT NULL,
    initial_capacity REAL NOT NULL DEFAULT 0.0,
    reference_capex REAL NOT NULL,
    reference_capacity REAL NOT NULL,
    maximum_capacity REAL,
    scaling_factor REAL NOT NULL DEFAULT 0.7,
    interest_rate REAL NOT NULL DEFAULT 0.1,
    lifespan INTEGER NOT NULL DEFAULT 20,
    note TEXT
) STRICT;

INSERT INTO Plant (id, label, reference_capex, reference_capacity, scaling_factor, interest_rate, lifespan)
SELECT 
    id AS id,
    label AS label,
    capex AS reference_capex,
    base_capacity AS reference_capacity,
    scaling_factor AS scaling_factor,
    interest_rate AS interest_rate,
    lifespan AS lifespan
FROM 
    Process;

PRAGMA foreign_keys = OFF;

CREATE TABLE Process_new (
    id INTEGER PRIMARY KEY,
    label TEXT NOT NULL,
    plant_id INTEGER,
    opex REAL NOT NULL,
    note TEXT,
    FOREIGN KEY (plant_id) REFERENCES Plant (id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

INSERT INTO Process_new (id, label, plant_id, opex)
SELECT 
    id AS id,
    label AS label,
    id AS plant_id,
    opex AS opex
FROM
    Process;

DROP TABLE Process;

ALTER TABLE Process_new RENAME TO Process;

PRAGMA foreign_keys = ON;