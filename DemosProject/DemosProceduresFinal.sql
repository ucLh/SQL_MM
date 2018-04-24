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
--Пример работы триггера на добавление
DECLARE @id INT , @salary MONEY, @chief NVARCHAR(40)
EXEC AddEmployee 'Дима', 'Иванов', 2, 2, @id out, @salary out, @chief out
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

GO --Пример удаления начальника
EXEC FireChief 2, 16
GO

Alter PROCEDURE RiseSalary (@newSalary MONEY, @salaryDiff MONEY OUTPUT)
AS
BEGIN
  DECLARE @diff MONEY, @category NVARCHAR(40), @min MONEY, @max MONEY,
    @oldSum MONEY, @newSum MONEY
	Declare	@table TABLE (id INT, oldSalary MONEY)
  SELECT @diff = @newSalary * 0.25

  SELECT @oldSum = SUM(Salary)
    FROM Employees
    WHERE Salary < @newSalary
  PRINT (@oldSum)

  INSERT @table
    SELECT EId, Salary
    FROM Employees
    WHERE Salary < @newSalary

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


  UPDATE Employees
  SET Salary = @newSalary
  WHERE Salary < @newSalary

  SELECT @newSum = SUM(Salary)
  FROM Employees
  WHERE EId in
    (Select id
    From @table)
  PRINT(@newSum)

  SET @salaryDiff = @newSum - @oldSum
  PRINT (@salaryDiff)
  IF @salaryDiff IS NULL
	  Set @salaryDiff = 0
END
GO
DECLARE @diff MONEY
EXEC RiseSalary 10000.0000, @diff OUTPUT
SELECT @diff
GO
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
