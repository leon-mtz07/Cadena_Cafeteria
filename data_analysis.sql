/*
 Preguntas a responder para el análisis de esta cadena de cafeterías
 - ¿Cuáles son los productos más vendidos por ciudad o tienda?
 - ¿Qué días y horas tienen mayor volumen de ventas?
 - ¿Cuál es el ticket promedio por tienda?
 - ¿Qué perfil de cliente (edad, género) consume más café?
 - ¿Qué porcentaje del total de ventas representan los productos de panadería?
 */

-- ¿Cuáles son los productos más vendidos por ciudad o tienda?
WITH best_products AS (
    SELECT
        city,
        neighborhood,
        product_name,
        COUNT(quantity) AS quantity,
        price,
        ROW_NUMBER() OVER (PARTITION BY city, neighborhood ORDER BY COUNT(quantity) DESC) AS rn
    FROM
        stores
    INNER JOIN transactions ON transactions.store_id = stores.store_id
    INNER JOIN products ON transactions.product_id = products.product_id
    GROUP BY city, neighborhood, product_name, price
)

SELECT
    city,
    neighborhood,
    product_name,
    quantity
FROM
    best_products
WHERE
    rn = 1
ORDER BY
    quantity DESC;

/*
 Aquí se observa la cantidad del mejor producto de cada sucursal, pero a la vez se nota la cantidad de productos
 que venden, porque entre más venden de su mejor producto nos podemos dar una idea de cuanto venden de todos los
 productos
 */

-- ¿Qué días y horas tienen mayor volumen de ventas?
SELECT
    HOUR(transaction_date) AS hour,
    SUM(quantity) AS transactions
FROM
    transactions
GROUP BY
    hour
ORDER BY
    hour;

-- Vemos que se vende casi igual en todas las horas menos desde las 13:00 hasta las 14:00 se ve una alza.

SELECT
    DAY(transaction_date) AS day,
    SUM(quantity) AS transactions
FROM
    transactions
GROUP BY
    day
ORDER BY
    day;

/*
 Aquí logramos ver que mientras el mes inicia vemos una cierta estabilidad en las transacciones, pero conforme va
 avanzando el mes, logramos ver que poco a poco disminuyen las ventas, donde a final del mes cae un 42%,
 comparado a inicios de mes dando un giro de 540 a solo 311 ventas
 */

-- ¿Cuál es el ticket promedio por tienda
SELECT
    city,
    neighborhood,
    ROUND(SUM(price * quantity) / COUNT(DISTINCT transaction_id), 2) AS avg_ticket
FROM
    stores
INNER JOIN transactions ON stores.store_id = transactions.store_id
INNER JOIN products ON transactions.product_id = products.product_id
GROUP BY
    city, neighborhood
ORDER BY
    avg_ticket DESC;

-- Aquí se logra ver una estabilidad en su ticket promedio de cada tienda, solo variando como 1 dólar

-- ¿Qué perfil de cliente (edad, género) consume más café?
SELECT
    gender,
    age,
    SUM(quantity) AS quantity
FROM
    customers
INNER JOIN transactions ON customers.customer_id = transactions.customer_id
WHERE product_id IN (
    SELECT
        product_id
    FROM
        products
    WHERE
        category = 'Coffee'
    )
GROUP BY gender, age
ORDER BY quantity DESC
LIMIT 5;

/*
 Aquí se ve algo curioso, ya que podemos que los primeros 5 lugares son mujeres abarcando juntas unos 448 cafés
 hasta la fecha, y las primeras 3 dentro de una edad de los 50 años y 70, y las otras 2 alrededor los 30 años

 A continuación se realizarán otros análisis extra para profundizar este análisis
 */

-- ¿Quiénes toman más café los hombres o las mujeres?
SELECT
    gender,
    SUM(quantity) AS quantity
FROM
    customers
INNER JOIN transactions ON customers.customer_id = transactions.customer_id
WHERE product_id IN (
    SELECT
        product_id
    FROM
        products
    WHERE
        category = 'Coffee'
    )
GROUP BY gender
ORDER BY quantity DESC;

/*
 De forma rápida podemos ver que las mujeres toman más cafe a comparación de los hombres, con una diferencia de
 174 cafés
 */

-- ¿De qué edades consumen más café los hombres?
SELECT
    age,
    SUM(quantity) AS quantity
FROM
    customers
INNER JOIN transactions ON customers.customer_id = transactions.customer_id
WHERE product_id IN (
        SELECT
            product_id
        FROM
            products
        WHERE
            category = 'Coffee'
    ) AND gender = 'M'
GROUP BY age
ORDER BY quantity DESC
LIMIT 5;

/*
 Aquí logramos ver que dentro de los hombres, que el rango de edad del top 5 están dentro de la edad de los 30 a
 65 años, el segundo lugar y el último son los más jóvenes dentro de los 30 años de edad, y los otros 3 están
 dentro de los 45 a 65 años
 */


-- ¿Qué porcentaje del total de ventas representan los productos de cafetería?
WITH total_sales AS (
    SELECT
        category,
        SUM(price * quantity) AS total_sell,
        AVG(price) AS avg_price
    FROM
        products
    INNER JOIN transactions ON products.product_id = transactions.product_id
    GROUP BY category
), total AS (
SELECT
    category,
    SUM(total_sell) AS total_sell,
    avg_price
FROM
    total_sales
GROUP BY category
)

SELECT
    category,
    total_sell,
    ROUND(100.0 * total_sell / SUM(total_sell) OVER (), 2) AS percentage,
    ROUND(avg_price, 2) AS avg_price_categ
FROM total;

/*
 Aquí podemos ver dentro de las cafeterías, la mayor parte de las ventas es de café, con un 44.12% de las ventas
 totales, luego le sigue los tes y los pasteles, los dos con un 22% de las ventas cada uno, luego le sigue los
 sandwiches con un 14% de las ventas, probablemente se deba a los costos de este y a su nula variedad dentro de esta
 categoría, ya que mientas el café tiene 4 variedades, el sandwich solo tiene uno además de que es el producto más caro
 de todos.
 */