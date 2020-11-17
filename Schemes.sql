TABLE LIST:

  CREATE TYPE PER_SEX AS ENUM ('Male', 'Female', 'Other')

  CREATE TABLE USERS(
      id SERIAL PRIMARY KEY,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL ,
      email TEXT UNIQUE NOT NULL ,
      phone_number TEXT UNIQUE NOT NULL ,
      sex PER_SEX,
      birth_date DATE,
      image_url TEXT,
      CONSTRAINT uniq_user UNIQUE(email, phone_number)
    ) //пользователи системы (хосты и тенанты)
    // id - уникальный ключ человека, зарегистрированного в системе
    // first_name, last_name - имя и фамилия человека
    // email, phone_number - телефон и почта определяют человека, мы не хотим, чтобы один человек зарегистрировался больше одного раза
    
  
CREATE TABLE COUNTRIES(
      id SERIAL PRIMARY KEY,
      country_name TEXT UNIQUE NOT NULL,
      commission MONEY NOT NULL
    ) // Таблица стран, в которых доступен сервис.
    // id - уникальный ключ страны
    // country_name - название страны  определяет страну- ключ, потому что мы не хотим, чтобы одна и таже страна могла взять разные коимссии
    // commission - комиссия, которую назначает сервис, в зависимости от страны



  CREATE TABLE APARTMENTS(
      id SERIAL PRIMARY KEY, 
      host_id INT NOT NULL, 
      latitude NUMERIC CHECK (latitude >= -180 AND latitude <= 180),
      longitude NUMERIC CHECK (longitude >= -180 AND longitude <= 180), 
      country_id INT NOT NULL, 
      address TEXT NOT NULL,  
      name TEXT NOT NULL,
      rooms INT NOT NULL CHECK(rooms > 0),
      beds INT NOT NULL CHECK(beds > 0),
      max_ppl INT NOT NULL CHECK(max_ppl > 0), 
      album_url TEXT, 
      cleaning_price NOT NULL MONEY,
      CONSTRAINT FK_HOSTS FOREIGN KEY (host_id) REFERENCES USERS(id),
      CONSTRAINT FK_COUNTRIES FOREIGN KEY (country_id) REFERENCES COUNTRIES(id),
      CONSTRAINT uniq_apart UNIQUE(latitude, longtitude, address),
      CONSTRAINT uniq_apart2 UNIQUE(country_id, addrees)
    ) // Апартаменты в которые может въехать и которые можно сдать.
    //id - униальный ключ апартаментов зарегистрированных в системе. 
    //latitude, longitude - координаты апартаментов
    //country_id - идентификатор страны
    //address - адрес апартаменов в текстовом формате
    //name - название апартаментов(Должно быть классным по условию заданря)
    //rooms - количестов комнат в апартаментах
    //beds - количестов краватей в апартаментах
    //max_ppl - маскимальное количество человек, которое может жить в апартаментах единовременно.
    //album_url -  url по которому лежит альбом с фотографиями
    //cleaning_price - цена уборки
    //UNIQUE(latitue, longtitude, address) - Только одна единица недвижиомости может находиться по этому адресу в этих координатах (адрес нужен, потому что координаты не учитывают высоту (например этаж))
    //UNIQUE(country_id, address) - Только одна единица недвижимости может находиться в стране по этому адресу
  
  CREATE TYPE CTR_STATUS AS ENUM ('waiting', 'accepted', 'denied')
  // Статус заявки - пользователь отправил заявку и ждет ответа, хост принял заявку, хост отклонил заявку.

  CREATE TABLE CONTRACTS(
      id SERIAL PRIMARY KEY,
      status CTR_STATUS NOT NULL,
      tenant_id INT NOT NULL,
      apartment_id INT NOT NULL,
      num_of_ppl INT CHECK (num_of_ppl > 0) NOT NULL,
      start_date TIMESTAMP NOT NULL,
      end_date TIMESTAMP NOT NULL CHECK (end_date >= start_date),
      CONSTRAINT fk_tenant FOREIGN KEY(tenant_id) REFERENCES USERS(id),
      CONSTRAINT fk_apartment FOREIGN KEY(apartment_id) REFERENCES APARTMENTS(id),
      CONSTRAINT uniq_ctr UNIQUE(tenant_id, apartment_id, start_date)
    ) //заявки на аренду жилья в разных состояниях.
    // id - уникальный ключ заявки
    // status - текущий статус заявки
    // tenant_id - id арендатора, подавшего заявку
    // apartment_id - id апартаменов
    // num_of_ppl - количество проживающих, согласно заявке
    // start_date - дата начала проживания
    // end_date - дата конца проживания
    // uniq_ctr - заявка определяется арендатором, местом, которое он хочет снять, и временем.

  CREATE TABLE APARTMENT_PRICES(
      id SERIAL PRIMARY KEY,
      apartment_id INT,
      year INT NOT NULL,
      start_week INT NOT NULL CHECK (start_week > -1 AND start_week < 52),
      daily_price MONEY NOT NULL,
      CONSTRAINT fk_apartment FOREIGN KEY(apartment_id) REFERENCES APARTMENTS(id),
      CONSTRAINT uniq_price UNIQUE(apartment_id, year, start_week)
    ) //Интервалы времени, за которые определена цена на аренду квартиру
    //id - уникальный ключ для участка времени
    //UNIQUE(apartment_id, year, start_week) - В такой-то год, в такую то неделю цена у такой-то квартиры
    может быть только одна
    //daily_price - цена за сутки аренды

  CREATE TABLE AMENITIES(
      apartment_id INT UNIQUE NOT NULL,
      wifi BOOLEAN,
      tv BOOLEAN,
      pets BOOLEAN,
      CONSTRAINT fk_apartment FOREIGN KEY(apartment_id) REFERENCES APARTMENTS(id)
    ) //Таблица с описанием удобств доступных в апартаментах
    //apartment_id - идентификатор апартаменов, в которых описанием удобства
    //wifi, tv, pets, ... etc - наименования удобств
    
    
    // ALTER_TABLE ADD_COLUMN when needed, new columns false by default // НУЛЛ лучше по умолчанию - мы не знаем про старое жилье, есть ли оно (удобство) там или нет. А false - точно нет.

  
  CREATE TABLE APARTMENT_REVIEWS(
      id SERIAL PRIMARY KEY,
      contract_id INT UNIQUE NOT NULL, // Номер заявки
      text TEXT, 
      grade1 INT CHECK (grade1 > 0 AND grade1 < 6), // Оценка по параметру 1 (например чистота)
      grade2 INT CHECK (grade2 > 0 AND grade2 < 6),
      grade3 INT CHECK (grade3 > 0 AND grade3 < 6),
      CONSTRAINT fk_contract FOREIGN KEY(contract_id) REFERENCES CONTRACTS(id),
    ) // Оценки от арендаторов 
    // id - униальный идентификатор отзыва
    // contract_id - идентификатор котракта, в рамках которого проиходит оценка, по заявке может быть только один отзыв
    // text - текст отзыва
    // grade1, ..., gradeN - наименования критериев оценки орендатора(его квартиры). 
 
  CREATE TABLE TENANT_REVIEWS(
      id SERIAL PRIMARY KEY,
      contract_id INT UNIQUE NOT NULL, // Номер заявки
      text TEXT, // Текст отзыва
      grade INT CHECK (grade > 0 AND grade < 6), // Оценка
      CONSTRAINT fk_contract FOREIGN KEY(contract_id) REFERENCES CONTRACTS(id)
    ) // Оценки от хозяина
    // id - униальный идентификатор отзыва
    // contract_id - идентификатор котракта, в рамках которого проиходит оценка, по заявке только один отзыв
    // text - текст отзыва
    // grade - оценка
    
  

    

  CREATE TABLE DICT_GENRE_ATR(
    id SERIAL PRIMARY KEY,
    genre TEXT UNIQUE NOT NULL
  ); // Таблица-справочник жанров
  // Не хотим записывать одни и теже жанры больше одного раза

  CREATE TABLE ATTRACTIONS(
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      start_date TIMESTAMP,
      end_date TIMESTAMP CHECK (end_date >= start_date),
      latitude NUMERIC CHECK (latitude >= -80 AND latitude <= 180),
      longitude NUMERIC CHECK (longitude >= -180 AND longitude <= 180),
      genre_id INT,
      CONSTRAINT fk_genre FOREIGN KEY(genre_id) REFERENCES DICT_GENRE_ATR(id)
    ) // start_date и end_date может быть NULL - если достопримечательность вечна
    
    // Достопримечательности, которые можно посетить рядом с жильем.
    // id - уникальный ключ достопримечательности
    // name - название достопримечательности
    // start_date - дата начала достопримечательности, в случае если это какой-то ивент
    // end_date - дата конца достопримечательности
    // latitude - широта достопримечательности
    // longitude - долгота достопримечательности
    // genre_id - id тэга достопримечательности
    
  
  