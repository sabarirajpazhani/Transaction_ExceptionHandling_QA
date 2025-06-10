create database TransactionExceptionQA;
use TransactionExceptionQA;
/*Banking System:
Implement a stored procedure to transfer money between two accounts. Ensure that:
The amount is deducted from one account.
The same amount is credited to another account.
If any step fails, rollback the entire transaction and log the error.*/
--Creating Accounts table
CREATE TABLE Accounts (
    AccountID INT PRIMARY KEY,
    AccountHolderName VARCHAR(100),
    Balance DECIMAL(10,2)
);
--Creating ErrorLog Table
CREATE TABLE ErrorLog (
    ErrorID INT IDENTITY(1,1) PRIMARY KEY,
    ErrorMessage NVARCHAR(MAX),
    ErrorTime DATETIME
);
--Inserting the data
INSERT INTO Accounts (AccountID, AccountHolderName, Balance) VALUES
(101, 'Ravi Kumar', 5000.00),
(102, 'Priya Sharma', 3000.00),
(103, 'Amit Verma', 10000.00),
(104, 'Neha Reddy', 7500.00);

select * from Accounts;

create procedure TransferMoney
	@FromAmount int,
	@ToAccount int,
	@Amount decimal(10,2)
as
begin
	begin try
	    begin transaction

		update Accounts
		set Balance = Balance - @Amount
		where AccountID = @FromAmount

		if @@rowcount = 0
		begin
			throw 50001, 'Sender AccountID not Found',1;
		end

		update Accounts 
		set Balance = Balance + @Amount
		where AccountID = @ToAccount

		if @@rowcount = 0
		begin
			throw 50001, 'Sender AccountID not Found',1;
		end

		commit transaction
	end try
	begin catch 
		rollback transaction
		insert into ErrorLog values
		(ERROR_MESSAGE(), GETDATE())

	end catch
end

exec TransferMoney 101, 106, 1000;
drop procedure TransferMoney;
select * from Accounts;
select * from ErrorLog;

/*Inventory Management:
Create a procedure to process an order:
Reduce stock from the inventory table.
Insert a record into the order table.
If stock is insufficient or any error occurs, rollback and return an error message.*/
CREATE TABLE Inventory (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    QuantityAvailable INT
);

CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    QuantityOrdered INT,
    OrderDate DATETIME
);

INSERT INTO Inventory (ProductID, ProductName, QuantityAvailable) VALUES
(1, 'Laptop', 10),
(2, 'Mouse', 25),
(3, 'Keyboard', 15),
(4, 'Monitor', 8);

select * from Inventory;

create procedure ProcessOrder
	@ProductID int,
	@Quantity int
as
begin
	begin try
		begin transaction
		declare @AvailableQuantity int
		select @AvailableQuantity = QuantityAvailable from Inventory
		where ProductID = @ProductID

		if(@AvailableQuantity < @Quantity)
		begin
			raiserror('Insuffient Stock', 16,1)
			rollback transaction
			return
		end

		update Inventory
		set QuantityAvailable = QuantityAvailable - @Quantity
		where ProductID = @ProductID

		insert into Orders values
		(@ProductID, @Quantity, GETDATE())

		commit transaction
	end try
	begin catch
		rollback transaction
		
		print 'Error Message - '+error_message()
	end catch
end

exec ProcessOrder 1, 8;
select * from Inventory;
Select * from Orders;
