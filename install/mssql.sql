/* добавляем функцию translate */

IF OBJECT_ID (N'dbo.translate', N'FN') IS NOT NULL
    DROP FUNCTION dbo.translate;
GO
CREATE FUNCTION dbo.translate (@Data VARCHAR(MAX), @DataToReplace VARCHAR(100), @ReplacedWithData VARCHAR(100))
RETURNS VARCHAR(MAX)
 
BEGIN
     
    DECLARE @TranslaedData VARCHAR(MAX)
     
    ;WITH CTE(PosToReplace,Data,DataToReplace,ReplacedWithData) AS
    (
    SELECT 1,CAST(@Data AS VARCHAR(MAX)) AS Data,CAST(SUBSTRING(@DataToReplace,1,1) AS VARCHAR(MAX)) AS DataToReplace,CAST(SUBSTRING(@ReplacedWithData,1,1) AS VARCHAR(MAX)) AS ReplacedWithData
    UNION ALL
    SELECT C.PosToReplace+1 AS PosToReplace , CAST(REPLACE(C.Data,C.DataToReplace,C.ReplacedWithData) AS VARCHAR(MAX)) AS Data,CAST(SUBSTRING(@DataToReplace,PosToReplace+1,1) AS VARCHAR(MAX)) AS DataToReplace,CAST(SUBSTRING(@ReplacedWithData,PosToReplace+1,1) AS VARCHAR(MAX)) AS ReplacedWithData
    FROM CTE C
    WHERE C.PosToReplace <= LEN(@DataToReplace)
    )
    SELECT  @TranslaedData = C.Data FROM CTE C WHERE C.PosToReplace = LEN(@DataToReplace)+1
         
    RETURN @TranslaedData                          
     
END
 
 

/* trigger  flarm*/
 
CREATE TRIGGER [dbo].[tr_alarm]
   ON  [dbo].[temperature_current]
    AFTER INSERT, UPDATE, DELETE
AS

BEGIN
    SET NOCOUNT ON;
	declare @tid int, @rolling_mill int, @side int, @temperature int
	
	select @tid=tid, @rolling_mill=rolling_mill, @side=side, @temperature=temperature from inserted
	
	if exists(select tid from deleted) and exists(select tid from inserted)
	begin
		IF (not exists(select name from [status] where
				name='rolling_mill:'+cast(@rolling_mill as nvarchar(1))+
				':side:'+cast(@side as nvarchar(1))+':alarm'))

			insert INTO [status] (name, value)
			values('rolling_mill:'+cast(@rolling_mill as nvarchar(1))+
			':side:'+cast(@side as nvarchar(1))+':alarm' ,'0')			
	end
	
	if UPDATE(temperature) and NOT UPDATE(tid) and NOT UPDATE(rolling_mill) and NOT UPDATE(side) 
	begin
		IF (@temperature < 
		   (select isnull(low, 0) from calculated_data
				where cid=@tid and rolling_mill=@rolling_mill and side=@side and step=0) and
			(select isnull(low, 0) from calculated_data
				where cid=@tid and rolling_mill=@rolling_mill and side=@side and step=0) <> 0
				or
		   (@temperature) > 
		   (select isnull(high, 0) from calculated_data
				where cid=@tid and rolling_mill=@rolling_mill and side=@side and step=0) and
		   (select isnull(high, 0) from calculated_data
				where cid=@tid and rolling_mill=@rolling_mill and side=@side and step=0) <> 0)				
		   and (@temperature > 270)
		begin
			UPDATE [status] SET value='1'
				where name='rolling_mill:'+cast(@rolling_mill as nvarchar(1))+
				':side:'+cast(@side as nvarchar(1))+':alarm'
		end
		else
		begin
			UPDATE [status] SET value='0'
				where name='rolling_mill:'+cast(@rolling_mill as nvarchar(1))+
				':side:'+cast(@side as nvarchar(1))+':alarm'
		end
	end
END



/* тестовый тригер с задержкой до 3х значений */

ALTER TRIGGER [dbo].[tr_alarm]
   ON  [dbo].[temperature_current]
    AFTER INSERT, UPDATE, DELETE
AS

BEGIN
    SET NOCOUNT ON;
	declare @tid int, @rolling_mill int, @side int, @temperature int
	
	select @tid=tid, @rolling_mill=rolling_mill, @side=side, @temperature=temperature from inserted
	
	if exists(select tid from deleted) and exists(select tid from inserted)
	begin
		IF (not exists(select name from [status] where
				name='rolling_mill:'+cast(@rolling_mill as nvarchar(1))+
				':side:'+cast(@side as nvarchar(1))+':count'))

			insert INTO [status] (name, value)
			values('rolling_mill:'+cast(@rolling_mill as nvarchar(1))+
			':side:'+cast(@side as nvarchar(1))+':count' ,'0')

		IF (not exists(select name from [status] where
				name='rolling_mill:'+cast(@rolling_mill as nvarchar(1))+
				':side:'+cast(@side as nvarchar(1))+':alarm'))

			insert INTO [status] (name, value)
			values('rolling_mill:'+cast(@rolling_mill as nvarchar(1))+
			':side:'+cast(@side as nvarchar(1))+':alarm' ,'0')			
	end

	if ((select value from [status] where
				name='rolling_mill:'+cast(@rolling_mill as nvarchar(1))+
				':side:'+cast(@side as nvarchar(1))+':count') > 3)
	begin
			UPDATE [status] SET value='1'
				where name='rolling_mill:'+cast(@rolling_mill as nvarchar(1))+
				':side:'+cast(@side as nvarchar(1))+':alarm'
	end
	else
	begin
			UPDATE [status] SET value='0'
				where name='rolling_mill:'+cast(@rolling_mill as nvarchar(1))+
				':side:'+cast(@side as nvarchar(1))+':alarm'				
	end
	
	if UPDATE(temperature) and NOT UPDATE(tid) and NOT UPDATE(rolling_mill) and NOT UPDATE(side) 
	begin
		IF (/*@temperature < 
		   (select isnull(low, 0) from calculated_data
				where cid=@tid and rolling_mill=@rolling_mill and side=@side and step=0) and
			(select isnull(low, 0) from calculated_data
				where cid=@tid and rolling_mill=@rolling_mill and side=@side and step=0) <> 0*/
--				or/*
		   (@temperature) > 
		   (select isnull(high, 0) from calculated_data
				where cid=@tid and rolling_mill=@rolling_mill and side=@side and step=0) and
		   (select isnull(high, 0) from calculated_data
				where cid=@tid and rolling_mill=@rolling_mill and side=@side and step=0) <> 0)				
--		   and @temperature > 270)
		begin
			UPDATE [status] SET value=cast(cast(value as int)+1 as nvarchar(20))
				where name='rolling_mill:'+cast(@rolling_mill as nvarchar(1))+
				':side:'+cast(@side as nvarchar(1))+':count'
		end
		else
		begin
			UPDATE [status] SET value='0'
				where name='rolling_mill:'+cast(@rolling_mill as nvarchar(1))+
				':side:'+cast(@side as nvarchar(1))+':count'
		end
	end
END
