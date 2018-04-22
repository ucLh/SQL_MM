ALTER PROCEDURE FillPayChecks(@id INT, @year NVARCHAR(4))
AS
BEGIN
  DECLARE @hdate DATE, @month INT, @tdate Date, @str NCHAR(2),
    @salary MONEY, @bonus MONEY, @cap INT
  SELECT @hdate = HiringDate FROM Employees WHERE @id = EId
  SELECT @salary = Salary FROM Employees WHERE @id = EId
  SELECT @bonus = Bonus FROM Employees WHERE @id = EId
  IF @year <> '2018'
    SET @cap = 12
  ELSE
    SET @cap = MONTH(GETDATE())
  SELECT @month = MONTH(@hdate) + 1
  WHILE @month <= @cap
  BEGIN
    Select @str = CAST(@month as NVARCHAR(2))
    SELECT @tdate = CONCAT(@year, '-', @str, '-1')
    INSERT INTO SalaryRecord
      VALUES (@id, @tdate, @salary, NULL );
    SELECT @month = @month + 1;
  END
END

CREATE FUNCTION CapCheck(@id1 INT)
  RETURNS INT --0 если всё в порядке, иначе 1
  AS
  BEGIN
    DECLARE @salary MONEY, @pos INT, @category NVARCHAR(40),
      @min MONEY, @max MONEY, @res INT
    SELECT @salary = Salary FROM Employees WHERE @id1 = EId
    SELECT @pos = PositionId FROM Employees WHERE @id1 = EId
    SELECT @category = CatName FROM Positions WHERE @pos = PositionId
    SELECT @min = MinSalary FROM Category WHERE @category = CatName
    SELECT @max = MaxSalary FROM Category WHERE @category = CatName
    IF (@salary <= @max) AND (@salary >= @min)
      SET @res = 0
    ELSE
      SET @res = 1
    RETURN(@res)
  END
GO

-- Just a prototype
CREATE TRIGGER IntegrityCheck ON Employees
  INSTEAD OF INSERT
  AS
  BEGIN
    DECLARE @id INT
    SELECT @id = EId FROM inserted
    IF dbo.CapCheck(@id) = 1
    BEGIN
      print('Salary is not in the stated limits')
      ROLLBACK
    END
    ELSE
      INSERT INTO Employees
        SELECT * FROM inserted
  END

ALTER TRIGGER VacancyCheck ON Employees
  INSTEAD OF INSERT
  AS
  BEGIN
    DECLARE @id INT, @pos INT, @dep INT, @actual INT, @vacancy INT
    SELECT @pos = PositionId FROM inserted
    SELECT @dep = DepId FROM inserted
    SELECT @actual = COUNT(*)
      FROM Employees
      WHERE @pos = PositionId and @dep = DepId
      GROUP BY PositionId, DepId
    SET @actual += 1
    SELECT @vacancy = Quantity
      FROM Vacancies
      WHERE @pos = Vacancies.PositionId and @dep = Vacancies.DepId
    IF @actual > @vacancy
    BEGIN
        PRINT('На эту должность нет свободных вакансий')
        ROLLBACK
    END
    ELSE
    BEGIN
      INSERT INTO Employees
        SELECT * FROM inserted
    END
  END