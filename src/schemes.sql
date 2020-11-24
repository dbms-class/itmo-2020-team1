CREATE TYPE PER_SEX AS ENUM ('Male', 'Female', 'Other');

CREATE TABLE USERS(
    id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL ,
    email TEXT UNIQUE NOT NULL ,
    phone_number TEXT UNIQUE NOT NULL ,
    sex PER_SEX,
    birth_date DATE,
    image_url TEXT
);
  
CREATE TABLE COUNTRIES(
    id SERIAL PRIMARY KEY,
    country_name TEXT UNIQUE NOT NULL,
    commission MONEY NOT NULL CHECK (commission > 0::MONEY)
); 

CREATE TABLE APARTMENTS(
    id SERIAL PRIMARY KEY, 
    host_id INT NOT NULL, 
    latitude NUMERIC CHECK (latitude >= -90 AND latitude <= 90),
    longitude NUMERIC CHECK (longitude >= -180 AND longitude <= 180), 
    country_id INT NOT NULL, 
    address TEXT NOT NULL,  
    name TEXT NOT NULL,
    rooms INT NOT NULL CHECK(rooms > 0),
    beds INT NOT NULL CHECK(beds > 0),
    max_ppl INT NOT NULL CHECK(max_ppl > 0), 
    album_url TEXT, 
    cleaning_price MONEY NOT NULL CHECK (cleaning_price > 0::MONEY),
    CONSTRAINT FK_HOSTS FOREIGN KEY (host_id) REFERENCES USERS(id),
    CONSTRAINT FK_COUNTRIES FOREIGN KEY (country_id) REFERENCES COUNTRIES(id),
    CONSTRAINT uniq_apart UNIQUE(latitude, longitude, address),
    CONSTRAINT uniq_apart2 UNIQUE(country_id, address)
);
  
CREATE TYPE CTR_STATUS AS ENUM ('waiting', 'accepted', 'denied');

CREATE TABLE CONTRACTS(
    id SERIAL PRIMARY KEY,
    status CTR_STATUS NOT NULL,
    tenant_id INT NOT NULL,
    apartment_id INT NOT NULL,
    num_of_ppl INT CHECK (num_of_ppl > 0) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL CHECK (end_date >= start_date),
    CONSTRAINT fk_tenant FOREIGN KEY(tenant_id) REFERENCES USERS(id),
    CONSTRAINT fk_apartment FOREIGN KEY(apartment_id) REFERENCES APARTMENTS(id),
    CONSTRAINT uniq_ctr UNIQUE(tenant_id, apartment_id, start_date)
);

CREATE TABLE APARTMENT_PRICES(
    id SERIAL PRIMARY KEY,
    apartment_id INT REFERENCES APARTMENTS,
    year INT NOT NULL,
    start_week INT NOT NULL CHECK (start_week > 0 AND start_week < 53),
    daily_price MONEY NOT NULL CHECK (daily_price > 0::MONEY),
    CONSTRAINT uniq_price UNIQUE(apartment_id, year, start_week)
);

CREATE TABLE AMENITIES(
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE
); 
    
CREATE TABLE AMEN_TO_APT(
    apartment_id INT REFERENCES APARTMENTS,
    amenity_id INT REFERENCES AMENITIES
);
  
CREATE TABLE APARTMENT_REVIEWS(
    id SERIAL PRIMARY KEY,
    contract_id INT UNIQUE REFERENCES CONTRACTS,
    text TEXT, 
    grade1 INT CHECK (grade1 > 0 AND grade1 < 6),
    grade2 INT CHECK (grade2 > 0 AND grade2 < 6),
    grade3 INT CHECK (grade3 > 0 AND grade3 < 6)
);
 
CREATE TABLE TENANT_REVIEWS(
    id SERIAL PRIMARY KEY,
    contract_id INT UNIQUE REFERENCES CONTRACTS,
    text TEXT,
    grade INT CHECK (grade > 0 AND grade < 6)
); 

CREATE TABLE DICT_GENRE_ATR(
    id SERIAL PRIMARY KEY,
    genre TEXT UNIQUE NOT NULL
);

CREATE TABLE ATTRACTIONS(
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    start_date DATE,
    end_date DATE CHECK (end_date >= start_date),
    latitude NUMERIC CHECK (latitude >= -90 AND latitude <= 90),
    longitude NUMERIC CHECK (longitude >= -180 AND longitude <= 180),
    genre_id INT,
    CONSTRAINT fk_genre FOREIGN KEY(genre_id) REFERENCES DICT_GENRE_ATR(id)
);

INSERT INTO COUNTRIES(country_name, commission) VALUES ('Russia', 1::Money), ('Sweden', 2::Money);

INSERT INTO USERS(first_name, last_name, email, phone_number) VALUES ('Hostname', 'Hostsurname', 'Hostmail', 'Hostnumber');

INSERT INTO APARTMENTS(host_id, latitude, longitude, country_id, address, name, rooms, beds, max_ppl, cleaning_price) VALUES
    (1, 0, 0, 1, 'Moscow', 'Kremlin', 1, 1, 1, 1::MONEY),
    (1, 0, 1, 1, 'Saint-Petersburg', 'Vyazemskiy per., 5-7', 100, 200, 200, 3::MONEY),
    (1, 1, 1, 2, 'Sweden city', 'Sweden house', 2, 3, 6, 5::MONEY);
