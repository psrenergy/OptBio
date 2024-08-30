PRAGMA user_version = 6;
PRAGMA foreign_keys = OFF;

CREATE TABLE SumOfProductsConstraint (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    sell_limit REAL NOT NULL DEFAULT 0.0,
    note TEXT
);

CREATE TABLE SumOfProductsConstraint_vector_product (
    id INTEGER,
    vector_index INTEGER NOT NULL,
    product_id INTEGER,
    FOREIGN KEY(id) REFERENCES SumOfProductsConstraint(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(product_id) REFERENCES Product(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
);

CREATE TABLE Plant_new (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    initial_capacity REAL NOT NULL DEFAULT 0.0,
    reference_capex REAL NOT NULL,
    reference_capacity REAL NOT NULL,
    maximum_capacity REAL,
    scaling_factor REAL NOT NULL DEFAULT 0.7,
    interest_rate REAL NOT NULL DEFAULT 0.1,
    lifespan INTEGER NOT NULL DEFAULT 20,
    note TEXT,
    maximum_capacity_for_scale REAL
)
STRICT;

INSERT INTO Plant_new (
    id,
    label,
    initial_capacity,
    reference_capex,
    reference_capacity,
    maximum_capacity,
    scaling_factor,
    interest_rate,
    lifespan,
    note
)
SELECT 
    id,
    label,
    initial_capacity,
    reference_capex,
    reference_capacity,
    maximum_capacity,
    scaling_factor,
    interest_rate,
    lifespan,
    note
FROM Plant;

DROP TABLE Plant;
ALTER TABLE Plant_new RENAME TO Plant;

CREATE TABLE Process_new (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    plant_id INTEGER,
    opex REAL NOT NULL,
    note TEXT,
    FOREIGN KEY (plant_id) REFERENCES Plant (id) ON DELETE SET NULL ON UPDATE CASCADE
)
STRICT;

INSERT INTO Process_new (
    id,
    label,
    plant_id,
    opex,
    note
)
SELECT 
    id,
    label,
    plant_id,
    opex,
    note
FROM Process;

DROP TABLE Process;

ALTER TABLE Process_new RENAME TO Process;

CREATE TABLE Product_new (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    unit TEXT NOT NULL,
    initial_availability REAL NOT NULL DEFAULT 0.0,
    sell_limit REAL,
    sell_price REAL NOT NULL DEFAULT 0.0,
    note TEXT,
    minimum_sell_quantity REAL NOT NULL DEFAULT 0.0,
    minimum_sell_violation_penalty REAL
)
STRICT;

INSERT INTO Product_new (
    id,
    label,
    unit,
    initial_availability,
    sell_limit,
    sell_price,
    note,
    minimum_sell_quantity,
    minimum_sell_violation_penalty
)
SELECT 
    id,
    label,
    unit,
    initial_availability,
    sell_limit,
    sell_price,
    note,
    minimum_sell_quantity,
    minimum_sell_violation_penalty
FROM Product;

DROP TABLE Product;

ALTER TABLE Product_new RENAME TO Product;

PRAGMA foreign_keys = ON;