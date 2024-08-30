PRAGMA user_version = 5;
PRAGMA foreign_keys = ON;

ALTER TABLE Configuration ADD COLUMN optimization_solver INTEGER DEFAULT 0;