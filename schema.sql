-- Types FOR USERS TABLE
CREATE TYPE "users_badge" AS ENUM ('The Architect', 'Side Quest Hero', 'All or Nothing', 'Vanilla Latte',
'Overthinker', 'Pixel Perfect', 'Void Cat', 'Invisible', 'Eclipse');

-- Architect : Autism
-- Side Quest Hero : ADHD
-- All or Nothing :
-- Vanilla Late : Neurotypical
-- Overthinker : Anxiety Syndrome
-- Pixel Perfect : OCD
-- Void Cat :
-- Invisible : Introvert
-- Eclipse : Bipolar Disorder

CREATE TYPE "users_status" AS ENUM ('Active', 'Moon Walking', 'Sensory Overload', 'Electric');

CREATE TABLE IF NOT EXISTS "users" (
    "id" SERIAL,
    "username" TEXT NOT NULL UNIQUE,
    "password_hash" TEXT NOT NULL,
    "display_name" TEXT,
    "badge" users_badge DEFAULT 'Vanilla Latte',
    "pfp" TEXT DEFAULT 'xyz.jpg',
    "bio" TEXT,
    "status" users_status DEFAULT 'Active',
    "verified" BOOLEAN NOT NULL,
    PRIMARY KEY ("id")
);
-- TYPES FOR SERVERS TABLE
--
CREATE TYPE server_security_level AS ENUM ('Level 1', 'Level 2');

CREATE TABLE IF NOT EXISTS "servers" (
    "id" SERIAL,
    "server_name" TEXT NOT NULL UNIQUE,
    "display_name" TEXT NOT NULL,
    "banner" TEXT DEFAULT 'server_banner.jpg',
    "icon" TEXT DEFAULT 'server_icon.jpg',
    "description" TEXT,
    "security_level" server_security_level DEFAULT 'Level 1',
    PRIMARY KEY ("id")
);

CREATE TYPE "role_name" AS ENUM ('Member', 'Admin', 'Muted');

-- Look UP Table
CREATE TABLE IF NOT EXISTS "roles" (
    "id" INT,
    "name" role_name UNIQUE,
    "permissions" TEXT[],
    PRIMARY KEY ("id")
);

INSERT INTO roles (id, name, permissions) VALUES
(1, 'Muted', ARRAY['Read']),
(2, 'Member', ARRAY['Read', 'Write', 'Delete']),
(3, 'Admin', ARRAY['Read', 'Write', 'Delete', 'Ban_Users', 'Update_Server_Settings']);

CREATE TABLE IF NOT EXISTS "users_in_servers" (
    "user_id" INT,
    "server_id" INT,
    "role_id" INT DEFAULT 2,
    PRIMARY KEY ("user_id", "server_id"),
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
    FOREIGN KEY ("server_id") REFERENCES "servers"("id") ON DELETE CASCADE,
    FOREIGN KEY ("role_id") REFERENCES "roles"("id")
);

CREATE TABLE IF NOT EXISTS "messages_in_servers"(
    "id" SERIAL,
    "user_id" INT,
    "server_id" INT,
    "message" TEXT NOT NULL,
    "attachment" TEXT DEFAULT NULL,
    "sent_at" TIMESTAMPTZ(0) DEFAULT now(),
    "is_deleted" BOOLEAN DEFAULT FALSE NOT NULL,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
    FOREIGN KEY ("server_id") REFERENCES "servers"("id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "audit_logs" (
    "id" SERIAL,
    "message_id" INT,
    "deleted_of_id" INT,
    "deleted_by_id" INT,
    "server_id" INT,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("message_id") REFERENCES "messages_in_servers"("id") ON DELETE CASCADE,
    FOREIGN KEY ("server_id") REFERENCES "servers"("id") ON DELETE CASCADE,
    FOREIGN KEY ("deleted_of_id") REFERENCES "users"("id") ON DELETE CASCADE,
    FOREIGN KEY ("deleted_by_id") REFERENCES "users"("id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "messages_in_dms"(
    "id" SERIAL,
    "author_id" INT,
    "receiver_id" INT,
    "message" TEXT NOT NULL,
    "attachment" TEXT DEFAULT NULL,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE,
    FOREIGN KEY ("receiver_id") REFERENCES "users"("id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "points_balance"(
    "id" SERIAL,
    "user_id" INT UNIQUE, -- by default, FKs are not unique in 
    "balance" DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY("id"),
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "points_transactions"(
    "id" BIGSERIAL,
    "sender_id" INT,
    "receiver_id" INT,
    "amount_sent" DECIMAL (8,2) NOT NULL CHECK (amount_sent > 0),
    PRIMARY KEY("id"),
    FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE CASCADE,
    FOREIGN KEY ("receiver_id") REFERENCES "users"("id") ON DELETE CASCADE
);

CREATE TYPE gifts AS ENUM ('earplugs', 'headphones', 'dim lights', 'fidget spinners', 'weighted blanket', 'fragrance');

CREATE TABLE IF NOT EXISTS gift_inventory (
    "type" gifts NOT NULL UNIQUE,
    "price" DECIMAL(7,2) NOT NULL,
    PRIMARY KEY("type")
);

INSERT INTO gift_inventory(type,price)
VALUES ('earplugs', 30.00),
('headphones', 150.00),
('dim lights', 30.00),
('fidget spinners', 50.00),
('weighted blanket', 250.00),
('fragrance', 300.00);

CREATE TABLE IF NOT EXISTS "gifts_transactions" (
    "id" BIGSERIAL,
    "sender_id" INT,
    "receiver_id" INT,
    "gift_type" gifts,
    PRIMARY KEY("id"),
    FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE CASCADE,
    FOREIGN KEY ("receiver_id") REFERENCES "users"("id") ON DELETE CASCADE,
    FOREIGN KEY ("gift_type") REFERENCES "gift_inventory"("type")
);

CREATE TABLE IF NOT EXISTS "friends" (
    "id" SERIAL,
    "user_1_id" INT,
    "user_2_id" INT,
    PRIMARY KEY ("user_1_id", "user_2_id"),
    FOREIGN KEY ("user_1_id") REFERENCES "users"("id") ON DELETE CASCADE,
    FOREIGN KEY ("user_2_id") REFERENCES "users"("id") ON DELETE CASCADE,
    CHECK ("user_1_id" <> "user_2_id")
);
