DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS appointment_services CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS service_categories CASCADE;
DROP TABLE IF EXISTS staff_members CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TYPE IF EXISTS appointment_status CASCADE;
DROP TYPE IF EXISTS payment_method CASCADE;

CREATE TYPE appointment_status AS ENUM ('planned', 'completed', 'cancelled');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'online');

CREATE TABLE clients (
    client_id SERIAL PRIMARY KEY,
    first_name VARCHAR(40) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(120) UNIQUE CHECK (email IS NULL OR email LIKE '%@%'),
    created_at DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE staff_members (
    staff_id SERIAL PRIMARY KEY,
    first_name VARCHAR(40) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    specialization VARCHAR(80) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    hire_date DATE NOT NULL
);

CREATE TABLE service_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(80) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE services (
    service_id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES service_categories(category_id),
    service_name VARCHAR(100) NOT NULL,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes BETWEEN 15 AND 360),
    price NUMERIC(10,2) NOT NULL CHECK (price > 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (category_id, service_name)
);

CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL REFERENCES clients(client_id) ON DELETE RESTRICT,
    staff_id INTEGER NOT NULL REFERENCES staff_members(staff_id) ON DELETE RESTRICT,
    starts_at TIMESTAMP NOT NULL,
    status appointment_status NOT NULL DEFAULT 'planned',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_staff_time UNIQUE (staff_id, starts_at)
);

CREATE TABLE appointment_services (
    appointment_id INTEGER NOT NULL REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    service_id INTEGER NOT NULL REFERENCES services(service_id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    price_at_booking NUMERIC(10,2) NOT NULL CHECK (price_at_booking > 0),
    PRIMARY KEY (appointment_id, service_id)
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    appointment_id INTEGER NOT NULL UNIQUE REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    method payment_method NOT NULL,
    paid_at TIMESTAMP NOT NULL,
    CONSTRAINT ck_payment_after_appointment CHECK (paid_at >= '2026-01-01'::timestamp)
);

CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    appointment_id INTEGER NOT NULL UNIQUE REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION check_payment_for_completed_appointment()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM appointments
        WHERE appointment_id = NEW.appointment_id
          AND status = 'completed'
    ) THEN
        RAISE EXCEPTION 'Payment can be added only for a completed appointment';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_payment_completed_appointment
BEFORE INSERT OR UPDATE ON payments
FOR EACH ROW
EXECUTE FUNCTION check_payment_for_completed_appointment();

INSERT INTO clients (first_name, last_name, phone, email, created_at)
VALUES
    ('Anna', 'Koval', '+380501111111', 'anna.koval@gmail.com', '2026-03-01'),
    ('Maria', 'Shevchenko', '+380502222222', 'maria.sh@gmail.com', '2026-03-02'),
    ('Olena', 'Bondar', '+380503333333', 'olena.bondar@gmail.com', '2026-03-05'),
    ('Iryna', 'Melnyk', '+380504444444', 'iryna.melnyk@gmail.com', '2026-03-08'),
    ('Kateryna', 'Tkachenko', '+380505555555', 'katya.t@gmail.com', '2026-03-12');

INSERT INTO staff_members (first_name, last_name, specialization, phone, hire_date)
VALUES
    ('Sofia', 'Marchenko', 'hair stylist', '+380671111111', '2025-08-10'),
    ('Natalia', 'Lysenko', 'nail master', '+380672222222', '2025-09-12'),
    ('Viktoria', 'Hnatiuk', 'brow artist', '+380673333333', '2025-10-01'),
    ('Alina', 'Savchuk', 'cosmetologist', '+380674444444', '2025-11-15');

INSERT INTO service_categories (category_name, description)
VALUES
    ('Hair', 'Haircuts, styling and coloring'),
    ('Nails', 'Manicure and pedicure services'),
    ('Brows', 'Brow correction and coloring'),
    ('Cosmetology', 'Facial care procedures');

INSERT INTO services (category_id, service_name, duration_minutes, price, is_active)
VALUES
    (1, 'Women haircut', 60, 650.00, TRUE),
    (1, 'Hair coloring', 150, 2200.00, TRUE),
    (2, 'Classic manicure', 75, 700.00, TRUE),
    (2, 'Pedicure', 90, 850.00, TRUE),
    (3, 'Brow correction', 30, 350.00, TRUE),
    (4, 'Facial cleansing', 90, 1300.00, TRUE);

INSERT INTO appointments (client_id, staff_id, starts_at, status, created_at)
VALUES
    (1, 1, '2026-04-01 10:00:00', 'completed', '2026-03-25 09:00:00'),
    (2, 2, '2026-04-01 12:00:00', 'completed', '2026-03-26 10:00:00'),
    (3, 3, '2026-04-02 11:00:00', 'planned', '2026-03-27 11:00:00'),
    (4, 4, '2026-04-03 15:00:00', 'completed', '2026-03-28 12:00:00'),
    (5, 1, '2026-04-04 13:00:00', 'cancelled', '2026-03-29 13:00:00'),
    (1, 2, '2026-04-05 09:30:00', 'completed', '2026-03-30 14:00:00');

INSERT INTO appointment_services (appointment_id, service_id, quantity, price_at_booking)
VALUES
    (1, 1, 1, 650.00),
    (1, 5, 1, 350.00),
    (2, 3, 1, 700.00),
    (3, 5, 1, 350.00),
    (4, 6, 1, 1300.00),
    (5, 2, 1, 2200.00),
    (6, 3, 1, 700.00),
    (6, 4, 1, 850.00);

INSERT INTO payments (appointment_id, amount, method, paid_at)
VALUES
    (1, 1000.00, 'card', '2026-04-01 11:10:00'),
    (2, 700.00, 'cash', '2026-04-01 13:20:00'),
    (4, 1300.00, 'online', '2026-04-03 16:40:00'),
    (6, 1550.00, 'card', '2026-04-05 11:20:00');

INSERT INTO reviews (appointment_id, rating, comment, created_at)
VALUES
    (1, 5, 'Great service and friendly staff', '2026-04-01 12:00:00'),
    (2, 4, 'Good manicure', '2026-04-01 14:00:00'),
    (4, 5, 'Professional cosmetology procedure', '2026-04-03 18:00:00');

SELECT 'clients' AS table_name, COUNT(*) AS rows_count FROM clients
UNION ALL SELECT 'staff_members', COUNT(*) FROM staff_members
UNION ALL SELECT 'service_categories', COUNT(*) FROM service_categories
UNION ALL SELECT 'services', COUNT(*) FROM services
UNION ALL SELECT 'appointments', COUNT(*) FROM appointments
UNION ALL SELECT 'appointment_services', COUNT(*) FROM appointment_services
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'reviews', COUNT(*) FROM reviews
ORDER BY table_name;
