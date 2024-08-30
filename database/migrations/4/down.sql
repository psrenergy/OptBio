PRAGMA user_version = 3;
PRAGMA foreign_keys = ON;

ALTER TABLE Product DROP COLUMN note;
ALTER TABLE Product DROP COLUMN minimum_sell_quantity;

PRAGMA foreign_keys = OFF;

CREATE TABLE Process_new (
    id INTEGER PRIMARY KEY,
    label TEXT NOT NULL,
    capex REAL NOT NULL,
    opex REAL NOT NULL,
    base_capacity REAL NOT NULL,
    scaling_factor REAL DEFAULT 0.7 NOT NULL,
    interest_rate REAL DEFAULT 0.1 NOT NULL,
    lifespan INTEGER DEFAULT 20 NOT NULL
);

INSERT INTO Process_new (id, label, capex, opex, base_capacity, scaling_factor, interest_rate, lifespan)
SELECT 
    Process.id AS id,
    Process.label AS label,
    Plant.reference_capex AS capex,
    Process.opex AS opex,
    Plant.reference_capacity AS base_capacity,
    Plant.scaling_factor AS scaling_factor,
    Plant.interest_rate AS interest_rate,
    Plant.lifespan AS lifespan
FROM
    Plant
JOIN Process ON Plant.id = Process.plant_id;

DROP TABLE Plant;
DROP TABLE Process;
ALTER TABLE Process_new RENAME TO Process;

