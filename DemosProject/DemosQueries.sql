--1.Выбрать названия и описания позиций, существующих в фирме.
SELECT PosName, PosDecript
FROM Positions p

-- 2.Получить список отделов фирмы.
SELECT DepName
FROM Departments

-- 3. Названия вакансий, но с вилкой окладов, соответствующих должности.
SELECT PosName, MinSalary, MaxSalary
FROM FullPosData
WHERE PositionId IN
      (SELECT PositionId
       FROM Vacancies
       WHERE dbo.VacancyCount(PositionId, DepId) > 0
       GROUP BY PositionId)

-- 4.Список сотрудников, относящихся к определенной категории зарплаты
CREATE VIEW FullPosData AS
SELECT p.*, MinSalary, MaxSalary
FROM Positions p, Category c
WHERE p.CatName = c.CatName

SELECT FirstName, LastName
FROM Employees
WHERE PositionId in
  (SELECT PositionId
  FROM FullPosData
  WHERE CatName = 'Специалист')

-- 5.Список сотрудников определенного отдела с адресами.
SELECT FirstName, LastName, City, Street, House, Flat
FROM Employees
WHERE DepId in
  (SELECT DepId
  FROM Departments
  WHERE DepName = 'Отдел кадров')

-- 6.Список сотрудников с должностями, не имеющих премий.
SELECT LastName, FirstName, PosName
FROM Employees e, Positions p
WHERE Bonus IS NULL and e.PositionId = p.PositionId

-- 7.Список сотрудников, живущих на той же улице, что и отдел, в котором они работают.
SELECT *
FROM Employees
WHERE Street in
      (SELECT Street
      FROM Departments
      WHERE Employees.DepId = Departments.DepId)

-- 8.Список отделов, имеющих дефицит (избыток, насыщение) сотрудников
-- Пример для дефицита
SELECT DepName
FROM Departments
WHERE DepId IN
      (SELECT DepId
      FROM Vacancies
      WHERE dbo.VacancyCount(PositionId, DepId) > 0
      GROUP BY DepId)

-- 9.Список сотрудников, имеющих определенный сертификат (диплом).
SELECT *
FROM Employees
WHERE Diploma IS NOT NULL

-- 10.Выдать ежеквартальную премию в размере 2% топ-менеджерам,
-- 4% сотрудникам (всем) и 3% начальникам отделов (менеджерам среднего звена).
ALTER PROCEDURE GiveBonus(@percent MONEY, @cat NVARCHAR(40))
AS
BEGIN
  DECLARE @id INT, @salary MONEY
  DECLARE Reward CURSOR FOR
  SELECT Eid, Salary
  FROM Employees
  WHERE PositionId IN
    (SELECT PositionId
    FROM FullPosData
    WHERE CatName = @cat)
  OPEN Reward
  FETCH FROM Reward INTO @id, @salary
  WHILE(@@FETCH_STATUS = 0)
  BEGIN
    PRINT (@salary)
    PRINT (@percent)
    PRINT(@salary*@percent)
    UPDATE SalaryRecord
    SET Bonus += @salary*@percent
    WHERE @id = Eid and MONTH(PayCheckDay) = MONTH(GETDATE())
          and YEAR(PayCheckDay) = YEAR(GETDATE())
    FETCH FROM Reward INTO @id, @salary
  END
  CLOSE Reward
  DEALLOCATE Reward
END

GO

EXEC GiveBonus 0.05, 'Специалист'