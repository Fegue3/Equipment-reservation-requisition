CREATE OR ALTER   TRIGGER [dbo].[trg_AtribuirIDReserva]
ON [dbo].[Reserva]
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Vari�veis para controle
    DECLARE @AnoAtual NVARCHAR(4) = CONVERT(NVARCHAR(4), YEAR(GETDATE()));
    DECLARE @UltimaSequencia NVARCHAR(4) = '0000';
    DECLARE @NovaSequencia NVARCHAR(4);

    -- Encontrar a sequ�ncia m�xima j� usada no ano atual
    SELECT @UltimaSequencia = ISNULL(MAX(SUBSTRING(ID_Reserva, 5, 4)), '0000')
    FROM Reserva
    WHERE LEFT(ID_Reserva, 4) = @AnoAtual;

    -- Incrementar a sequ�ncia como string
    SET @NovaSequencia = RIGHT('0000' + CONVERT(NVARCHAR(4), CONVERT(INT, @UltimaSequencia) + 1), 4);

    -- Inserir os novos registros
    INSERT INTO Reserva (ID_Reserva, TimeStamp_Reserva, Data_Inicio_Pedido, Data_Fim_Pedido, Estado, ID_Utilizador, Data_Cancelamento, Data_Inicio_Real, Data_Fim_Real, Data_Alterada, Motivo_Reserva)
    SELECT 
        dbo.MakeID(GETDATE(), CONVERT(INT, @UltimaSequencia) + ROW_NUMBER() OVER (ORDER BY (SELECT NULL))) AS ID_Reserva,
        TimeStamp_Reserva,
        Data_Inicio_Pedido,
        Data_Fim_Pedido,
        Estado,
        ID_Utilizador,
        Data_Cancelamento,
        Data_Inicio_Real,
        Data_Fim_Real,
        Data_Alterada,
        Motivo_Reserva
    FROM inserted;
END;
