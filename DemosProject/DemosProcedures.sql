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
    print(@vacancy)
    IF @vacancy IS NULL
    BEGIN
      PRINT ('Такой должности в данном отделе не существует')
      ROLLBACK
    END
    ELSE
    BEGIN
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
  END

ALTER FUNCTION VacancyCount(@pos INT, @dep INT)
  RETURNS INT
AS
BEGIN
  DECLARE @actual INT, @vacancy INT, @res INT
  SELECT @actual = COUNT(*)
      FROM Employees
      WHERE @pos = PositionId and @dep = DepId
      GROUP BY PositionId, DepId
  SELECT @vacancy = Quantity
      FROM Vacancies
      WHERE @pos = Vacancies.PositionId and @dep = Vacancies.DepId
  IF @actual IS NULL
    SET @res = @vacancy
  ELSE
    SET @res = @vacancy - @actual
  RETURN(@res)
END

ALTER PROCEDURE AddEmployee(
  @Name NVARCHAR(40), @Surname NVARCHAR(40),
  @pos  INT, @dep INT,
  @id INT OUTPUT , @salary MONEY OUTPUT , @chief NVARCHAR(40) OUTPUT )
AS
  BEGIN
    DECLARE @chiefId INT
    SELECT @id = EId
    FROM Employees
    ORDER BY EId
    SET @id +=1
    SELECT @salary = MinSalary
    FROM FullPosData
    WHERE PositionId = @pos;
    SELECT @chiefId = ChiefId
    FROM Departments
    WHERE @dep = DepId
    SELECT @chief = LastName
    FROM Employees
    WHERE @chiefId = EId
    INSERT INTO Employees
      VALUES (@id, @Name, @Surname, @chiefId, @dep, @pos, @salary, NULL , NULL, GETDATE(),
      NULL , NULL , NULL , NULL , NULL)
  END

GO
DECLARE @id INT , @salary MONEY, @chief NVARCHAR(40)
EXEC AddEmployee 'Вася', 'Петров', 4, 2, @id out, @salary out, @chief out
SELECT @id, @salary, @chief

ALTER PROCEDURE FireChief(@dep INT, @newChief INT)
AS
  BEGIN
    DECLARE @tmp INT, @oldChief INT, @salary MONEY, @pos INT
    SELECT @tmp = DepId
    FROM Employees
    WHERE EId = @newChief

    SELECT @oldChief = ChiefId
    FROM Departments
    WHERE DepId = @dep

    SELECT @pos = PositionId
    FROM Employees
    WHERE @oldChief = EId

    SELECT @salary = MinSalary
    FROM Category
    WHERE CatName = 'Руководство'
    IF @dep <> @tmp
      RAISERROR('NO_DATA_FOUND', 15, 1)
    ELSE
    BEGIN
      UPDATE Employees
      SET ChiefId = @newChief
      WHERE DepId = @dep

      UPDATE Employees
      SET ChiefId = NULL, Salary = @salary, PositionId = @pos
      WHERE EId = @newChief

      UPDATE Departments
      SET ChiefId = @newChief
      WHERE DepId = @dep

      DELETE FROM Employees
      WHERE EId = @oldChief
    END
  END

 GO


CREATE TRIGGER ChiefChanged ON Employees
  AFTER DELETE
  AS
  BEGIN
    DECLARE @dep INT, @id INT, @currentCheif INT, @newChief INT, @pos INT
    SELECT @id = Eid FROM deleted
    SELECT @dep = DepId FROM deleted
    SELECT @pos = PositionId FROM deleted

    SELECT @currentCheif = ChiefId
    FROM Departments
    WHERE DepId = @dep

    IF @currentCheif = @id
      BEGIN
        SELECT @newChief = Eid
        FROM Employees
        WHERE PositionId = @pos

        UPDATE Departments
        SET ChiefId = @newChief
        WHERE @dep = DepId
      END
  END

GO

CREATE TRIGGER PositionCheck ON Employees
  INSTEAD OF UPDATE
  AS
  BEGIN
    DECLARE @newPos INT, @newDep INT, @quant INT, @id INT
    SELECT @newPos = PositionId FROM inserted
    SELECT @newDep = DepId FROM inserted
    SELECT @id = EId FROM deleted

    SELECT @quant = Quantity
    FROM Vacancies
    WHERE DepId = @newDep and PositionId = @newPos

    IF (@quant IS NULL) or (@quant = 0)
    BEGIN
      PRINT('Такой должности нет в данном отделе')
      ROLLBACK
    END
    ELSE
    BEGIN
      DELETE FROM dbo.Employees
      WHERE EId = @id

      INSERT INTO Employees
        SELECT * FROM inserted
    END
  END

Alter PROCEDURE RiseSalary (@newSalary MONEY, @salaryDiff MONEY OUTPUT)
AS
BEGIN
  DECLARE @diff MONEY, @category NVARCHAR(40), @min MONEY, @max MONEY,
    @oldSum MONEY, @newSum MONEY
	Declare	@table TABLE (id INT, oldSalary MONEY)
  SELECT @diff = @newSalary * 0.25
  DECLARE Cats CURSOR FOR
    SELECT *
    FROM Category
  OPEN Cats
  FETCH FROM Cats INTO @category, @min, @max
  WHILE (@@FETCH_STATUS = 0)
  BEGIN
    IF @min < @newSalary
    BEGIN
      UPDATE Category
      SET MinSalary = @newSalary
      WHERE CatName = @category

      IF (@max - @min) < @diff
      BEGIN
        UPDATE Category
        SET MaxSalary = 1.25 * @newSalary
        WHERE CatName = @category
      END
    END

    FETCH FROM Cats INTO @category, @min, @max
  END
  CLOSE Cats
  DEALLOCATE Cats
  INSERT @table
    SELECT EId, Salary
    FROM Employees
    WHERE Salary < @newSalary

  SELECT @oldSum = SUM(Salary)
    FROM Employees
    WHERE Salary < @newSalary

  UPDATE Employees
  SET Salary = @newSalary
  WHERE Salary < @newSalary

  SELECT @newSum = SUM(Salary)
  FROM Employees
  WHERE EId in
    (Select id
    From @table)

  SET @salaryDiff = @newSum - @oldSum
  IF @salaryDiff IS NULL
	Set @salaryDiff = 0
END

CREATE TRIGGER SalaryChange ON Category
  FOR UPDATE
  AS
  BEGIN
    DECLARE @id INT, @category NVARCHAR(40), @oldmin MONEY, @newmin MONEY,
      @salary MONEY, @max MONEY
    DECLARE @table TABLE (id INT, salary MONEY)
    SELECT @category = CatName FROM inserted
    SELECT @oldmin = MinSalary FROM deleted
    SELECT @newmin = MinSalary FROM inserted
    SELECT @max = MaxSalary FROM deleted
    IF @oldmin <> @newmin
    BEGIN
      INSERT @table
        SELECT EId, Salary
        FROM Employees
        WHERE Salary <= @max and Salary >= @oldmin
      UPDATE @table
      SET salary = (salary/@oldmin)*@newmin
      DECLARE People CURSOR FOR
        SELECT *
        FROM @table
      OPEN People
      FETCH FROM People INTO @id, @salary
      WHILE (@@FETCH_STATUS = 0)
      BEGIN
        UPDATE Employees
        SET Salary = @salary
        WHERE EId = @id

        FETCH FROM People INTO @id, @salary
      END
    END
  END
