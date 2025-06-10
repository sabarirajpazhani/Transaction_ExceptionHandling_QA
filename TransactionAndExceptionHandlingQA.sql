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