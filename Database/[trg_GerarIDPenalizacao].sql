CREATE OR ALTER TRIGGER [dbo].[trg_GerarIDPenalizacao]
ON [dbo].[Penalizacao]
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Inserir penalizações sem duplicações
    INSERT INTO Penalizacao (ID_Penalizacao, Data_Penalizacao, Valor_Penalizacao, Motivo_Penalizacao, ID_Requisicao, ID_Reserva, ID_Utilizador)
    SELECT 
        ISNULL((SELECT MAX(ID_Penalizacao) FROM Penalizacao), 0) + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ID_Penalizacao,
        i.Data_Penalizacao,
        i.Valor_Penalizacao, -- Valor da penalização
        i.Motivo_Penalizacao, -- Motivo da penalização
        i.ID_Requisicao, -- ID da requisição, se aplicável
        i.ID_Reserva, -- ID da reserva associada
        r.ID_Utilizador -- ID do utilizador relacionado à reserva
    FROM inserted i
    LEFT JOIN Reserva r ON i.ID_Reserva = r.ID_Reserva
    WHERE NOT EXISTS (
        SELECT 1 
        FROM Penalizacao p
        WHERE p.ID_Reserva = i.ID_Reserva
          AND p.Data_Penalizacao = i.Data_Penalizacao
    ); -- Evitar duplicações
END;
