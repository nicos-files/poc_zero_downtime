USE appdb;
INSERT INTO dbo.customers(name,email) 
VALUES ('Ada','ada@ex.com'),('Linus','linus@ex.com');

INSERT INTO dbo.orders(customer_id,total_amount) 
VALUES (1,100.00),(2,230.50);
