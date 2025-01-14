CREATE OR ALTER TRIGGER [dbo].[AtualizaIDUtilizador]
ON [dbo].[Utilizador]
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaxLength INT = 10;

    -- Tabela temporária para armazenar os dados
    DECLARE @TempTable TABLE (
        RowID INT IDENTITY(1,1),
        ID_Utilizador NVARCHAR(50),
        ID_TipoUtilizador NVARCHAR(10),
        Nome NVARCHAR(100),
        Telefone NVARCHAR(20),
        Email NVARCHAR(100),
        Prioridade NVARCHAR(20)
    );

    -- Insere os dados na tabela temporária
    INSERT INTO @TempTable (ID_TipoUtilizador, Nome, Telefone, Email)
    SELECT ID_TipoUtilizador, Nome, Telefone, Email FROM inserted;

    -- Gera os IDs únicos e insere na tabela final
    WHILE EXISTS (SELECT 1 FROM @TempTable)
    BEGIN
        DECLARE @RowID INT, 
                @ID_TipoUtilizador NVARCHAR(10), 
                @Nome NVARCHAR(100), 
                @Telefone NVARCHAR(20), 
                @Email NVARCHAR(100), 
                @BaseID NVARCHAR(50), 
                @NewID NVARCHAR(50), 
                @Prioridade NVARCHAR(20);

        SELECT TOP 1 
            @RowID = RowID,
            @ID_TipoUtilizador = ID_TipoUtilizador,
            @Nome = Nome,
            @Telefone = Telefone,
            @Email = Email
        FROM @TempTable;

        -- Define a prioridade com base no ID_TipoUtilizador
        SELECT @Prioridade = CASE
            WHEN @ID_TipoUtilizador = 'PD' THEN 'Maxima'
            WHEN @ID_TipoUtilizador = 'PR' THEN 'Acima da Media'
            WHEN @ID_TipoUtilizador = 'BS' THEN 'Media'
			WHEN @ID_TipoUtilizador = 'RS' THEN 'Media'
            WHEN @ID_TipoUtilizador = 'MS' THEN 'Media'
            WHEN @ID_TipoUtilizador = 'DS' THEN 'Media'
            WHEN @ID_TipoUtilizador = 'SF' THEN 'Media'
            WHEN @ID_TipoUtilizador = 'XT' THEN 'Media'
            ELSE 'Media' -- Valor padrão
        END;

        SET @BaseID = LEFT(CONCAT(@ID_TipoUtilizador, '_', LEFT(@Nome, CHARINDEX(' ', @Nome + ' ') - 1)), @MaxLength - 1);

        -- Garante unicidade do ID
        SET @NewID = @BaseID;
        WHILE EXISTS (SELECT 1 FROM Utilizador WHERE ID_Utilizador = @NewID)
        BEGIN
            DECLARE @Counter INT;
            SELECT @Counter = COUNT(*) + 1 FROM Utilizador WHERE ID_Utilizador LIKE @BaseID + '%';
            SET @NewID = @BaseID + RTRIM(@Counter);
        END;

        -- Insere na tabela final
        INSERT INTO Utilizador (ID_Utilizador, ID_TipoUtilizador, Nome, Telefone, Email, Prioridade)
        VALUES (@NewID, @ID_TipoUtilizador, @Nome, @Telefone, @Email, @Prioridade);

        -- Remove o registro processado da tabela temporária
        DELETE FROM @TempTable WHERE RowID = @RowID;
    END;
END;
