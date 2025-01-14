CREATE OR ALTER TRIGGER [dbo].[trg_IncreasePriority]
ON [dbo].[Reserva]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @utilizadores_afetados TABLE (
        ID_Utilizador VARCHAR(10),
        Prioridade_Atual VARCHAR(20),
        Total_Anterior INT,
        Total_Final INT
    );

    -- Obter informações dos utilizadores afetados
    INSERT INTO @utilizadores_afetados
    SELECT 
        u.ID_Utilizador,
        u.Prioridade,
        -- Total anterior (excluindo as atualizadas)
        ISNULL((
            SELECT COUNT(*)
            FROM Reserva r
            WHERE r.ID_Utilizador = u.ID_Utilizador
            AND r.Estado = 'satisfied'
            AND r.ID_Reserva NOT IN (SELECT ID_Reserva FROM inserted WHERE Estado = 'satisfied')
        ), 0) as Total_Anterior,
        -- Total final (incluindo as novas)
        ISNULL((
            SELECT COUNT(*)
            FROM Reserva r
            WHERE r.ID_Utilizador = u.ID_Utilizador
            AND r.Estado = 'satisfied'
        ), 0) as Total_Final
    FROM Utilizador u
    WHERE EXISTS (
        SELECT 1 
        FROM inserted i 
        WHERE i.ID_Utilizador = u.ID_Utilizador
        AND i.Estado = 'satisfied'
    );

    -- Atualizar prioridades
    UPDATE u
    SET u.Prioridade = 
        CASE 
            WHEN ua.Prioridade_Atual = 'Minima' AND FLOOR(ua.Total_Final/2) > FLOOR(ua.Total_Anterior/2) THEN 'Abaixo da Media'
            WHEN ua.Prioridade_Atual = 'Abaixo da Media' AND FLOOR(ua.Total_Final/2) > FLOOR(ua.Total_Anterior/2) THEN 'Media'
            WHEN ua.Prioridade_Atual = 'Media' AND FLOOR(ua.Total_Final/2) > FLOOR(ua.Total_Anterior/2) THEN 'Acima da Media'
            WHEN ua.Prioridade_Atual = 'Acima da Media' AND FLOOR(ua.Total_Final/2) > FLOOR(ua.Total_Anterior/2) THEN 'Maxima'
            ELSE ua.Prioridade_Atual
        END
    FROM Utilizador u
    INNER JOIN @utilizadores_afetados ua ON u.ID_Utilizador = ua.ID_Utilizador;
END;