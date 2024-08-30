PRAGMA user_version = 7;
PRAGMA foreign_keys = ON;

ALTER TABLE Configuration ADD COLUMN solution_method INTEGER DEFAULT 1;