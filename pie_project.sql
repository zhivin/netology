
-- запрос 3.1 : получаем среднюю стоимость заказа

select round ( avg(order_cart_sum) :: numeric , 0 ) as avg_order_sum from orders;

-- запрос 3.2 : получаем кол-во заказов > 10 пирогов

select count(cart_order_id) as more_10_order from order_cart where pie_count>10;

-- запрос 3.3 : получаем заказы оформленные online и со стоимостью доставки >= 500

select order_id from orders where order_delivery_price>=500 and order_source='internet' limit 10;

-- запрос 3.4 : получаем кол-во уникальных заказчиков

select count(person_id) as uniq_persons from order_persons;

-- запрос 3.5 : получаем среднее кол-во пирогов в заказе

select round( sum(pie_count) / count(distinct cart_order_id) :: numeric, 3 ) as avg_pie from order_cart;

-- запрос 3.6 : получаем среднюю стоимость доставки

select round( avg(order_delivery_price) :: numeric, 0 ) as avg_delivery_price from orders where order_delivery_type = 'exp' ;

-- запрос 3.7 : получаем top-10 самых лояльных заказчиков

select first_name, last_name, count(order_id) as order_count from person left join
order_persons on order_persons.person_id=person.id group by first_name, last_name order by order_count desc limit 10;

-- запрос 3.8 : получаем top-10 самых продаваемых пирогов

select pie_name, pie_id, count(cart_pie_id) as pie_count from pie inner join order_cart on pie.pie_id=order_cart.cart_pie_id
group by pie_id order by pie_count desc limit 10;

-- запрос 3.9 : получаем среднюю стоймость заказа в зависимости от стоймости заказа

select order_id, order_delivery_price, order_cart_sum,
    avg(order_cart_sum) over ( partition by order_delivery_price ) as avg_sum
from orders where order_delivery_price!= 0 order by order_delivery_price asc limit 10;

-- запрос 3.10 : получаем среднее кол-во пирогов в заказе у заказчиков с историей > = 5 заказов

with A1 as (select person_id from order_persons group by person_id having count(order_id) >= 5)
select round( avg(sum_pie) :: numeric, 2 ) from ( select sum(pie_count) as sum_pie
from A1
join order_persons as OP on OP.person_id = A1.person_id
join order_cart as OC on OP.order_id = OC.cart_order_id group by OP.order_id ) A2;


-- запрос 4.1 : с помощью view создаем таблицу важных заказчиков и достаем кол-во полученных ими бонусных пирогов

create view important_custom as select person_id, count(order_id) from order_persons
group by person_id having count(order_id)>5 order by count(order_id) desc;

select sum(pie_bonus), order_persons.person_id
from important_custom join order_persons on important_custom.person_id=order_persons.person_id
join order_cart on order_cart.cart_order_id=order_persons.order_id group by order_persons.person_id
order by sum(pie_bonus) desc limit 10;

-- запрос 4.2 : с помощью view создаем таблицу id только сладких пирогов и достаем заказы состоящие только из сладких пирогов

create view sweet as select pie_id, pie_name, pie_price from pie where pie_type='Сладкий';

select order_id as sweet_only_order from orders as A1 where not exists
(select OC.cart_order_id from order_cart OC left join sweet S on OC.cart_pie_id = S.pie_id
where OC.cart_order_id = A1.order_id AND S.pie_id IS NULL) limit 10; 