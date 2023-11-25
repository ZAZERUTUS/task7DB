--1 Вывести к каждому самолету класс обслуживания и количество мест этого класса
select aircraft_code, fare_conditions, count(seat_no)
from bookings.seats group by aircraft_code, fare_conditions order by aircraft_code;

--2 Найти 3 самых вместительных самолета (модель + кол-во мест)
select a.model, count(seat_no) cnt from bookings.seats s join bookings.aircrafts a on s.aircraft_code=a.aircraft_code
group by a.model order by cnt desc limit 3;


--3 Найти все рейсы, которые задерживались более 2 часов
select * from bookings.flights_v fv where (fv.scheduled_departure + interval '2 hour') < fv.actual_departure;

--4 Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных
select t.passenger_id, t.passenger_name, t.contact_data from bookings.tickets t join bookings.bookings b on t.book_ref=b.book_ref
join bookings.ticket_flights tf on t.ticket_no=tf.ticket_no where tf.fare_conditions='Business' order by b.book_date desc limit 10;

--5 Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')
select flight_id, count(fare_conditions='Economy') ce, count(fare_conditions='Comfort') cc, count(fare_conditions='Business') cb
from bookings.ticket_flights tf group by tf.fare_conditions, tf.flight_id having count(fare_conditions='Business') = 0 order by ce;

--6 Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой по вылету
--Оба запроса решение разными споссобами
select ad.airport_name, ad.city from bookings.flights_v fv join bookings.airports_data ad on fv.departure_airport=ad.airport_code
where fv.scheduled_arrival != fv.actual_arrival group by ad.airport_code;
select distinct ad.airport_name, ad.city from bookings.flights_v fv join bookings.airports_data ad on fv.departure_airport=ad.airport_code
where fv.scheduled_arrival != fv.actual_arrival;


--7 Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов
select ad.airport_name, count(f.flight_id) from bookings.flights f join bookings.airports_data ad on f.departure_airport=ad.airport_code group by ad.airport_code


--8 Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным
select count(flight_id) from bookings.flights_v fv where fv.scheduled_arrival != fv.actual_arrival


--9 Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
select s.aircraft_code, ad.model, s.seat_no from bookings.seats s join bookings.aircrafts_data ad on s.aircraft_code = ad.aircraft_code
where s.aircraft_code =
	(select ad.aircraft_code from bookings.aircrafts_data ad where ((ad.model::json->'ru')::varchar) = '"Аэробус A321-200"')
and s.fare_conditions != 'Economy' order by s.seat_no;


--10 Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
select a.airport_code, a.airport_name, a.city from bookings.airports a
where a.city in (select a.city c from bookings.airports a group by a.city having count(a.coordinates) > 1);


--11 Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
-- расчёт идёт от стоимости билета так как бронирование может содержать несколько билетов на разных пассажиров
select t.passenger_name from bookings.tickets t join bookings.ticket_flights tf on t.ticket_no=tf.ticket_no
where tf.amount > (select AVG(amount) from bookings.tickets t join bookings.ticket_flights tf on t.ticket_no=tf.ticket_no);


--12 Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
-- установлена дата так как ближайшего к текущей дате нет в БД
select * from bookings.flights_v fv
where fv.departure_city='Екатеринбург' and fv.arrival_city='Москва' and fv.status in ('On Time', 'Delayed', 'Scheduled')
and fv.scheduled_departure_local > '2017-08-26 10:10:00.000' order by fv.scheduled_departure_local limit 1;



-- 13 Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
WITH RankedTickets AS (
  select ticket_no, amount, ROW_NUMBER() OVER (ORDER BY amount ASC) AS min_rank, ROW_NUMBER() OVER (ORDER BY amount DESC) AS max_rank
  FROM bookings.ticket_flights
)
SELECT * FROM RankedTickets WHERE min_rank = 1 OR max_rank = 1;


-- 14 Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints)
CREATE TABLE public.customers (
    id SERIAL PRIMARY KEY,
    firstName VARCHAR(50) NOT NULL,
    lastName VARCHAR(50) NOT null,
    email VARCHAR(255) UNIQUE NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
    phone VARCHAR(15) UNIQUE,
    CHECK (LENGTH(phone) > 0)
);


--15 Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + constraints
CREATE TABLE public.orders (
    id SERIAL PRIMARY KEY,
    customerId int NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (customerId) REFERENCES customers(id)
);



--16 Написать 5 insert в эти таблицы
insert into public.customers values
	(default, 'name1', 'lastname1', 'asad1@ddqq.com', '122232'),
	(default, 'name2', 'lastname1', 'asad2@ddqq.com', '222232'),
	(default, 'name3', 'lastname3', 'asad3@ddqq.com', '322232'),
	(default, 'name1', 'lastname4', 'asad4@ddqq.com', '422232'),
	(default, 'name5', 'lastname1', 'asad5@ddqq.com', '522232');


insert into public.orders values
	(default, 1, 35),
	(default, 2, 33),
	(default, 3, 30),
	(default, 4, 32),
	(default, 5, 31);



-- 17 Удалить таблицы
drop table public.customers, public.orders;
