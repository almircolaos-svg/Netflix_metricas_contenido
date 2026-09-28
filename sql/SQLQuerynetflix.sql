--CREATE DATABASE NetflixDB;

--SELECT name FROM sys.databases WHERE name = 'NetflixDB';

SELECT * FROM netflix_titles
WHERE title LIKE 'Naruto%';

SELECT 
    type,
    COUNT(*) AS total
FROM netflix_titles
GROUP BY type
ORDER BY total DESC;


-- vistas de la tabla

CREATE VIEW vw_top_genres AS
SELECT 
    primary_genre,
    type,
    COUNT(*) AS total
FROM netflix_titles
GROUP BY primary_genre, type;

CREATE VIEW vw_ratings AS
SELECT 
    rating,
    type,
    COUNT(*) AS total
FROM netflix_titles
GROUP BY rating, type;

CREATE VIEW vw_content_by_country AS
SELECT 
    country,
    COUNT(*) AS total
FROM netflix_titles
WHERE country != 'Unknown'
GROUP BY country;

CREATE VIEW vw_content_by_year AS
SELECT 
    year_added,
    type,
    COUNT(*) AS total
FROM netflix_titles
WHERE year_added IS NOT NULL
GROUP BY year_added, type;


-- consultas para verificar las vistas
SELECT * FROM vw_top_genres;
SELECT * FROM vw_ratings;
SELECT * FROM vw_content_by_country
SELECT * FROM netflix_titles;
SELECT * FROM vw_content_by_year;

-- consulta para ver las columnas y su tipo de dato
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'netflix_titles';

-- CREACION DE LAS TABLAS

-- Dimensión tipo
CREATE TABLE dim_type (
    type_id   INT IDENTITY(1,1) PRIMARY KEY,
    type_name VARCHAR(20)
);

-- Dimensión país
CREATE TABLE dim_country (
    country_id   INT IDENTITY(1,1) PRIMARY KEY,
    country_name VARCHAR(500)
);

-- Dimensión género
CREATE TABLE dim_genre (
    genre_id   INT IDENTITY(1,1) PRIMARY KEY,
    genre_name VARCHAR(100)
);

-- Dimensión rating
CREATE TABLE dim_rating (
    rating_id   INT IDENTITY(1,1) PRIMARY KEY,
    rating_name VARCHAR(20)
);

-- Dimensión fecha
CREATE TABLE dim_date (
    date_id      INT IDENTITY(1,1) PRIMARY KEY,
    year_added   INT,
    month_added  INT,
    month_name   VARCHAR(20)
);

-- tabla de hechos
CREATE TABLE fact_content (
    fact_id      INT IDENTITY(1,1) PRIMARY KEY,
    show_id      VARCHAR(20),
    title        VARCHAR(200),
    type_id      INT FOREIGN KEY REFERENCES dim_type(type_id),
    country_id   INT FOREIGN KEY REFERENCES dim_country(country_id),
    genre_id     INT FOREIGN KEY REFERENCES dim_genre(genre_id),
    rating_id    INT FOREIGN KEY REFERENCES dim_rating(rating_id),
    date_id      INT FOREIGN KEY REFERENCES dim_date(date_id),
    release_year INT,
    duration_value INT,
    duration_unit  VARCHAR(20)
);

-- INSERTAR LA ID DE type_id POR CADA type_name diferente
INSERT INTO dim_type (type_name)
SELECT DISTINCT type 
FROM netflix_titles
WHERE type IS NOT NULL;

-- INSERTAR LA ID DE country_id POR CADA genre_name diferente
INSERT INTO dim_genre (genre_name)
SELECT DISTINCT primary_genre 
FROM netflix_titles
WHERE primary_genre IS NOT NULL;

-- INSERTAR LA ID DE rating_id POR CADA rating_name diferente
INSERT INTO dim_rating (rating_name)
SELECT DISTINCT rating 
FROM netflix_titles
WHERE rating IS NOT NULL;

-- INSERTAR LA ID DE date_id POR CADA year_x, month_x, month_x
INSERT INTO dim_date (year_added, month_added, month_name)
SELECT DISTINCT year_added, month_added, month_name
FROM netflix_titles
WHERE year_added IS NOT NULL;

-- INSERTAR LA ID DE country_id POR CADA country_name diferente
INSERT INTO dim_country (country_name)
SELECT DISTINCT country 
FROM netflix_titles 
WHERE country IS NOT NULL;

-- Verificar los insert con dim_country
SELECT COUNT(*) FROM dim_country;
SELECT TOP 5 * FROM dim_country;

-- Poblar tabla fact_content cruzando la tabla original netflix_titles con las nuevas dimensiones.
INSERT INTO fact_content (
    show_id,
    title,
    type_id,
    country_id,
    genre_id,
    rating_id,
    date_id,
    release_year,
    duration_value,
    duration_unit
)
SELECT 
    n.show_id,
    n.title,
    t.type_id,
    c.country_id,
    g.genre_id,
    r.rating_id,
    d.date_id,
    n.release_year,
    n.duration_value,
    n.duration_unit
FROM netflix_titles n
LEFT JOIN dim_type    t ON n.type           = t.type_name
LEFT JOIN dim_country c ON n.country        = c.country_name
LEFT JOIN dim_genre   g ON n.primary_genre  = g.genre_name
LEFT JOIN dim_rating  r ON n.rating         = r.rating_name
LEFT JOIN dim_date    d ON n.year_added     = d.year_added 
                       AND n.month_added    = d.month_added;

-- Verificar filas cargadas
SELECT COUNT(*) AS total_filas FROM fact_content;

-- Verificar que los joins funcionaron
SELECT TOP 5
    f.title,
    t.type_name,
    c.country_name,
    g.genre_name,
    r.rating_name,
    d.year_added,
	d.month_name
FROM fact_content f
JOIN dim_type    t ON f.type_id    = t.type_id
JOIN dim_country c ON f.country_id = c.country_id
JOIN dim_genre   g ON f.genre_id   = g.genre_id
JOIN dim_rating  r ON f.rating_id  = r.rating_id
JOIN dim_date    d ON f.date_id    = d.date_id
JOIN dim_date    e ON f.date_id    = d.date_id;

-- consulta simple para ver los datos
SELECT * FROM dim_type;
SELECT DISTINCT type FROM netflix_titles;


-- por si se desea borrar las tablas y id por algun fallo y de nuevo ejecutar los insert y poblar fact_content
DELETE FROM fact_content;
DELETE FROM dim_type;
DELETE FROM dim_country;
DELETE FROM dim_genre;
DELETE FROM dim_rating;
DELETE FROM dim_date;
--resetear los IDS
DBCC CHECKIDENT ('dim_type',    RESEED, 0);
DBCC CHECKIDENT ('dim_country', RESEED, 0);
DBCC CHECKIDENT ('dim_genre',   RESEED, 0);
DBCC CHECKIDENT ('dim_rating',  RESEED, 0);
DBCC CHECKIDENT ('dim_date',    RESEED, 0);
DBCC CHECKIDENT ('fact_content', RESEED, 0);


