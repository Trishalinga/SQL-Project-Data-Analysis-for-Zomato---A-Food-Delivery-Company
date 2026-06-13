--Zomato Data Analysis using SQL
 CREATE TABLE customers
     (
        customer_id INT PRIMARY KEY,
        customer_name VARCHAR(25),
        reg_date DATE
	 );

CREATE TABLE restaurents
    (
        restaurent_id INT PRIMARY KEY,
		restaurent_name VARCHAR(55),
		city VARCHAR(25),
		opening_hours VARCHAR(55)
	);

CREATE TABLE orders
    (
        order_id INT PRIMARY KEY,
		customer_id INT, --this is coming from customers table
		restaurent_id INT, --this is coming from restaurents table
		order_item VARCHAR(55),
		order_date DATE,
		order_time TIME,
		order_status VARCHAR(25),
		total_amount FLOAT
	);

-- adding FOREIGN KEY constraint
ALTER TABLE orders
ADD CONSTRAINT fk_customers
FOREIGN KEY (customer_id) references customers(customer_id);

-- adding FOREIGN KEY constraint
ALTER TABLE orders
ADD CONSTRAINT fk_restaurents
FOREIGN KEY (restaurent_id) references restaurents(restaurent_id);


CREATE TABLE riders
    (
        rider_id INT PRIMARY KEY,
		rider_name VARCHAR(55),
		sign_up DATE
	);
	
CREATE TABLE deliveries
    (
       delivery_id INT PRIMARY KEY,
	   order_id INT, --From orders table
	   delivery_status VARCHAR(35),
	   delivery_time TIME,
	   rider_id INT --From riders table(foreign key)
	);


-- adding FOREIGN KEY constraint
ALTER TABLE deliveries
ADD CONSTRAINT fk_riders
FOREIGN KEY (rider_id) references riders(rider_id);

-- adding FOREIGN KEY constraint
ALTER TABLE deliveries
ADD CONSTRAINT fk_orders
FOREIGN KEY (order_id) references orders(order_id);

--END OF SCHEMAS




	