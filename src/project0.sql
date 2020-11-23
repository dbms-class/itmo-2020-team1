-- Справочник политических строев
CREATE TABLE Government(id SERIAL PRIMARY KEY, value TEXT UNIQUE);

-- Планета, её название, расстояние до Земли, политический строй
CREATE TABLE Planet(
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE,
  distance NUMERIC(5,2),
  government_id INT REFERENCES Government);

-- Значения рейтинга пилотов
CREATE TYPE Rating AS ENUM('Harmless'), ('Poor'), ('Average'), ('Competent'), ('Dangerous'), ('Deadly'), ('Elite');

-- Пилот корабля
CREATE TABLE Commander(
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE);



WITH Names AS (
  SELECT unnest(ARRAY['Громозека'), ('Ким'), ('Буран'), ('Зелёный'), ('Горбовский'), ('Ийон Тихий'), ('Форд Префект'), ('Комов'), ('Каммерер'), ('Гагарин'), ('Титов'), ('Леонов'), ('Крикалев'), ('Армстронг'), ('Олдрин']) AS name
)
INSERT INTO Commander(name, rating)
SELECT name FROM Names

INSERT INTO Commander(name) VALUES 
('Громозека'), ('Ким'), ('Буран'), ('Зелёный'), ('Горбовский'), ('Ийон Тихий'), ('Форд Префект'), ('Комов'), ('Каммерер'), ('Гагарин'), ('Титов'), ('Леонов'), ('Крикалев'), ('Армстронг'), ('Олдрин');