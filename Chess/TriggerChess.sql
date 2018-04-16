ALTER Trigger [dbo].[MoveFigure]
On [dbo].[Chessboard1]
Instead of Update As
Begin
Declare @x char, @y char, @color varchar(6), @id int, @anotherId int, @aColor varchar(6)
select @x = x from inserted
select @y = y from inserted
select @id = cid from inserted
select @color = fcolor from Chessman where @id = Chessman.cid
if (Select COUNT(*) from Chessboard1 where x = @x and y = @y ) > 0
	Begin
	select @anotherId = cid from Chessboard1 where x = @x and y = @y 
	select @aColor = fcolor from Chessman where cid = @anotherId
	End
else Begin
	Delete From Chessboard1 where cid = @id
	Insert Into Chessboard1 (cid,x,y) Values (@id, @x, @y)
	return
	End
if  (@aColor <> @color)
	Begin
	Delete From Chessboard1 Where cid = @anotherId
	Delete From Chessboard1 where cid = @id
	Insert Into Chessboard1 (cid,x,y) Values (@id, @x, @y)
	End
Else
	Begin
	print('Don`t eat your own figures')
	RollBack 
	End
End
