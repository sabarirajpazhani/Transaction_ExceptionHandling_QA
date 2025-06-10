create database TransactionExceptionQA;
use TransactionExceptionQA;
/*1. Banking System:
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

/*2. Inventory Management:
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

/*3. Employee Payroll:
Write a procedure to update employee salaries:
Apply a percentage increment to a department.
Log changes into a salary history table.
If any update fails, revert all salary updates and log the error.*/
CREATE TABLE Employees (
    EmpID INT PRIMARY KEY,
    EmpName VARCHAR(100),
    Department VARCHAR(50),
    Salary DECIMAL(10,2)
);
CREATE TABLE SalaryHistory (
    HistoryID INT IDENTITY(1,1) PRIMARY KEY,
    EmpID INT,
    OldSalary DECIMAL(10,2),
    NewSalary DECIMAL(10,2),
    UpdatedDate DATETIME
);
INSERT INTO Employees (EmpID, EmpName, Department, Salary) VALUES
(1, 'Ravi Kumar', 'IT', 50000),
(2, 'Priya Sharma', 'HR', 45000),
(3, 'Amit Verma', 'IT', 55000),
(4, 'Neha Reddy', 'Finance', 60000),
(5, 'Vijay Patel', 'HR', 47000);

select * from Employees;
select * from SalaryHistory;

create procedure EmployeeSalary
	@EmpID int,
	@SalaryPercent decimal(5,2)
as
begin	
	begin try
		begin transaction
			declare @OldSalary decimal(10,2), @NewSalary decimal(10,2)
			select @OldSalary = Salary from Employees where EmpID = @EmpID

			if @@rowcount = 0
			begin
				print 'Employee ID not Found'
				rollback transaction
				return
			end

			set @NewSalary = @OldSalary + (@OldSalary * @SalaryPercent /100)

			update Employees
			set Salary = @NewSalary
			where EmpID = @EmpID

			insert into SalaryHistory values
			(@EmpID, @OldSalary, @NewSalary, GETDATE())

		commit transaction
	end try
	begin catch
		rollback transaction
		print 'Error Message - ' + error_message()
	end catch
end

exec EmployeeSalary 10, 10;

drop procedure EmployeeSalary;

select * from Employees;
select * from SalaryHistory;


/*4. Flight Booking System:
Handle seat reservation:
Check seat availability.
Insert into booking table.
If the seat is already booked or any issue occurs, rollback and raise an error.*/
CREATE TABLE Flights (
    FlightID INT PRIMARY KEY,
    FlightName VARCHAR(100),
    TotalSeats INT
);
CREATE TABLE Bookings (
    BookingID INT IDENTITY(1,1) PRIMARY KEY,
    FlightID INT,
    SeatNumber INT,
    PassengerName VARCHAR(100),
    BookingDate DATETIME,
    CONSTRAINT UQ_FlightSeat UNIQUE (FlightID, SeatNumber)  -- prevents duplicate bookings
);
INSERT INTO Flights (FlightID, FlightName, TotalSeats) VALUES
(1, 'Indigo 6E-204', 100),
(2, 'Air India AI-101', 150),
(3, 'SpiceJet SG-456', 120);

select * from Flights;
select * from Bookings;

create procedure BookFlight
	@FlightID int,
	@SeatNumber int,
	@PassengerName varchar(80)
as
begin
	begin try
		begin transaction
			declare @AvailableSeats int
			select @AvailableSeats = TotalSeats from Flights where FlightID = @FlightID
			if exists (select 1 from Bookings where FlightID = @FlightID and SeatNumber = @SeatNumber)
			begin
				print 'Seat Already Booked'
				rollback transaction
				return
			end

			if(@AvailableSeats < @SeatNumber)
			begin
				print 'Invalid Seat Number' 
				rollback transaction
				return
			end

			insert into Bookings values
			(@FlightID,@SeatNumber,@PassengerName,GETDATE())

		commit transaction
	end try
	begin catch
		rollback transaction
		print 'Error Message - ' + error_message()
	end catch
end
			
exec BookFlight 1, 10, Arun;


select * from Flights;
select * from Bookings;


/*5. Online Shopping Cart:
When checking out:
Create an order.
Deduct stock.
Remove items from the cart.
If any part fails (e.g., stock out), cancel the order and rollback changes.*/
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Stock INT
);
CREATE TABLE Cart (
    CartID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT,
    ProductID INT,
    Quantity INT
);
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT,
    OrderDate DATETIME
);
CREATE TABLE OrderDetails (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    Quantity INT
);
-- Products
INSERT INTO Products (ProductID, ProductName, Stock) VALUES
(1, 'T-shirt', 20),
(2, 'Shoes', 15),
(3, 'Cap', 10);

-- Cart (User 101)
INSERT INTO Cart (UserID, ProductID, Quantity) VALUES
(101, 1, 2),  -- 2 T-shirts
(101, 2, 1);  -- 1 pair of Shoes



create procedure OrderProduct
	@UserID int
as
begin
	begin try
		begin transaction
			if Not Exists(Select 1 from Cart where UserID = @UserID)
			begin 
				raiserror ('User not found', 16,1)
				rollback transaction
				return
			end
			insert into Orders values
			(@UserID, getdate())

			declare @OrderID int= SCOPE_IDENTITY()

			declare @ProductID int, @Quantity int
			select @ProductID = ProductID , @Quantity = Quantity from Cart where UserID = @UserID

			insert into OrderDetails (OrderID, ProductID, Quantity)
			select @OrderID,ProductID, Quantity from Cart
			where UserID = @UserID;

			delete from Cart where UserID = @UserID;
		commit transaction
	end try
	begin catch
		rollback transaction
		print 'Error Message - ' + error_message()
	end catch
end


exec OrderProduct 101;

select * from Products;
select * from Cart;
select * from Orders;
select * from OrderDetails;
