ALTER FUNCTION PawnKill (@id1 int)
  RETURNS @table TABLE(_id INT, _color CHAR(6), _type CHAR(6), _x CHAR, _y CHAR) AS
  BEGIN
	Declare @x int, @y int, @color char(6), @yMod int;
	Select @x = ASCII(x) from Chessboard1 where cid = @id1;
	Select @y = ASCII(y) from Chessboard1 where cid = @id1;
	Select @color = fcolor from Chessman where cid = @id1;
	if (@color = 'white')
		Set @yMod = 1;
	if (@color = 'black')
		Set @yMod = -1;
	Insert @table 
		Select Chessman.cid, Chessman.fcolor, Chessman.ftype, x, y
		From Chessman, Chessboard1 
		Where (ASCII(x) = @x + 1 or ASCII(x) = @x - 1) and ASCII(y) = @y + @yMod
			and Chessman.cid = Chessboard1.cid
			and @color <> fcolor
	Return

  END