BEGIN;

SELECT
    a.appointment_id,
    c.first_name || ' ' || c.last_name AS client_name,
    s.first_name || ' ' || s.last_name AS staff_name,
    a.starts_at,
    a.status
FROM appointments AS a
JOIN clients AS c ON c.client_id = a.client_id
JOIN staff_members AS s ON s.staff_id = a.staff_id
WHERE a.status = 'planned'
ORDER BY a.starts_at;

SELECT
    a.appointment_id,
    sc.category_name,
    sv.service_name,
    aps.quantity,
    aps.price_at_booking
FROM appointment_services AS aps
JOIN appointments AS a ON a.appointment_id = aps.appointment_id
JOIN services AS sv ON sv.service_id = aps.service_id
JOIN service_categories AS sc ON sc.category_id = sv.category_id
WHERE a.appointment_id = 1;

SELECT service_id, service_name, duration_minutes, price
FROM services
WHERE is_active = TRUE
  AND price >= 800
ORDER BY price DESC;

WITH new_client AS (
    INSERT INTO clients (first_name, last_name, phone, email, created_at)
    VALUES ('Daria', 'Romanenko', '+380506666666', 'daria.romanenko@gmail.com', '2026-04-06')
    RETURNING client_id
),
new_appointment AS (
    INSERT INTO appointments (client_id, staff_id, starts_at, status, created_at)
    SELECT client_id, 2, '2026-04-08 10:00:00', 'completed', '2026-04-06 10:00:00'
    FROM new_client
    RETURNING appointment_id
),
inserted_services AS (
    INSERT INTO appointment_services (appointment_id, service_id, quantity, price_at_booking)
    SELECT appointment_id, service_id, 1, price
    FROM new_appointment
    CROSS JOIN services
    WHERE service_name IN ('Classic manicure', 'Pedicure')
    RETURNING appointment_id, service_id
),
new_payment AS (
    INSERT INTO payments (appointment_id, amount, method, paid_at)
    SELECT appointment_id, 1550.00, 'card', '2026-04-08 12:00:00'
    FROM new_appointment
    RETURNING payment_id
)
SELECT
    new_client.client_id,
    new_appointment.appointment_id,
    COUNT(inserted_services.service_id) AS services_added,
    new_payment.payment_id
FROM new_client
JOIN new_appointment ON TRUE
JOIN inserted_services ON TRUE
JOIN new_payment ON TRUE
GROUP BY new_client.client_id, new_appointment.appointment_id, new_payment.payment_id;

SELECT
    c.first_name || ' ' || c.last_name AS client_name,
    a.appointment_id,
    sv.service_name,
    aps.price_at_booking,
    p.amount
FROM clients AS c
JOIN appointments AS a ON a.client_id = c.client_id
JOIN appointment_services AS aps ON aps.appointment_id = a.appointment_id
JOIN services AS sv ON sv.service_id = aps.service_id
LEFT JOIN payments AS p ON p.appointment_id = a.appointment_id
WHERE c.phone = '+380506666666';

UPDATE appointments
SET starts_at = '2026-04-02 12:00:00'
WHERE appointment_id = 3
  AND status = 'planned'
RETURNING appointment_id, starts_at, status;

UPDATE services
SET price = 380.00
WHERE service_name = 'Brow correction'
RETURNING service_id, service_name, price;

DELETE FROM appointments
WHERE status = 'cancelled'
  AND appointment_id = 5
RETURNING appointment_id, status;

SELECT 'clients' AS table_name, COUNT(*) AS rows_count FROM clients
UNION ALL SELECT 'appointments', COUNT(*) FROM appointments
UNION ALL SELECT 'appointment_services', COUNT(*) FROM appointment_services
UNION ALL SELECT 'payments', COUNT(*) FROM payments
ORDER BY table_name;

COMMIT;
