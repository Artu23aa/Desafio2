--Primer ejercicio 
CREATE OR REPLACE VIEW vista_peliculas_info AS
SELECT
    f.film_id,
    f.title AS nombre_pelicula,


    (
        SELECT GROUP_CONCAT(DISTINCT CONCAT(p.first_name, ' ', p.last_name) ORDER BY p.first_name, p.last_name SEPARATOR ', ')
        FROM actor p
        JOIN film_actor fa ON fa.actor_id = p.actor_id
        WHERE fa.film_id = f.film_id
    ) AS actores,

  
    (
        SELECT GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ')
        FROM category c
        JOIN film_category fc ON fc.category_id = c.category_id
        WHERE fc.film_id = f.film_id
    ) AS categorias,

  
    CONCAT(ci.city, ', ', co.country) AS ubicacion_tienda

FROM film f


JOIN inventory i ON i.film_id = f.film_id
JOIN store s ON i.store_id = s.store_id
JOIN address a ON s.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id;



--Segundo ejercicio
USE sakila;

CREATE OR REPLACE VIEW vista_ganancias_pelicula_tienda AS
SELECT
    s.store_id,
    f.film_id,
    f.title AS nombre_pelicula,
    CONCAT(ci.city, ', ', co.country) AS tienda_ubicacion,
    SUM(p.amount) AS total_ganancias
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN store s ON i.store_id = s.store_id
JOIN address a ON s.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id
GROUP BY s.store_id, f.film_id;



--Tercer ejercicio

DELIMITER $$

CREATE PROCEDURE sp_generar_compra (
    IN p_film_id INT,
    IN p_customer_id INT,
    IN p_staff_id INT,
    OUT p_rental_id INT,
    OUT p_total_out DECIMAL(5,2)
)
BEGIN
    DECLARE v_inventory_id INT;
    DECLARE v_amount DECIMAL(5,2);
    DECLARE v_payment_date DATETIME;

    -- Obtener un inventory_id disponible para esa película
    SELECT inventory_id
    INTO v_inventory_id
    FROM inventory
    WHERE film_id = p_film_id
    LIMIT 1;

    -- Validar que haya inventario
    IF v_inventory_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No hay inventario disponible para esta película.';
    END IF;

    -- Insertar en rental
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
    VALUES (NOW(), v_inventory_id, p_customer_id, NULL, p_staff_id);

    SET p_rental_id = LAST_INSERT_ID();  -- Asigna el ID del alquiler a la variable OUT

    -- Obtener el precio (rental_rate) de la película
    SELECT rental_rate INTO v_amount
    FROM film
    WHERE film_id = p_film_id;

    -- Definir la fecha de pago
    SET v_payment_date = NOW();

    -- Insertar en payment
    INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
    VALUES (p_customer_id, p_staff_id, p_rental_id, v_amount, v_payment_date);

    -- Devolver valores por OUT
    SET p_total_out = v_amount;  -- Asignar el total a la variable OUT
END$$

DELIMITER ;
