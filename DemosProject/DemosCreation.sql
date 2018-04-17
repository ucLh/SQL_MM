Create Table Employees(
	EId int Primary Key,
	FirstName nvarchar(40) Not Null,
	LastName nvarchar(40) Not Null,
	ChiefId int Null references Employees(EId),
	DepId int Null,
	PositionId int Not Null, 
	Salary money Null,
	Bonus money Null,
	Diploma nvarchar(80) Null,
	HiringDate Date Not Null,
	City nvarchar(40) Not Null,
	District nvarchar(40) Null,
	Street nvarchar(80)Not Null,
	House nchar(10) Not Null,
	Flat nchar(10) Null
)
Go
Create Table Departments(
	DepId int Primary Key,
	DepName nvarchar(40) Not Null,
	ChiefId int references Employees(EId),
	City nvarchar(40) Not Null,
	District nvarchar(40) Null,
	Street nvarchar(80)Not Null,
	House nchar(10) Not Null,
	Flat nchar(10) Null
)
Go
Create Table Positions(
	PositionId int Primary Key,
	PosName nvarchar(80) Not Null,
	PosDecript nvarchar(500) Null,
	CatName nvarchar(40) Not Null
)
Go
Create Table Category(
	CatName nvarchar(40) Primary Key,
	MinSalary money Not Null,
	MaxSalary money Not Null
)
Go
Create Table SalaryRecord(
	Eid int references Employees(Eid),
	PayCheckDay Date,
	Salary money,
	Bonus money,
	Check(Day(PayCheckDay) = 1),
	Primary Key(Eid, PayCheckDay)
)
Go
Create Table Vacancies(
	PositionId int references Positions(PositionId),
	DepId int references Departments(DepId),
	Quantity int Not Null,
	Primary Key(DepId, PositionId)
)
