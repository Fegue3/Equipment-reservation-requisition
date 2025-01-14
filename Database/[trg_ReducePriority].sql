CREATE OR ALTER TRIGGER [dbo].[trg_ReducePriority] 
ON [dbo].[Penalizacao]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @utilizadores_afetados TABLE (
        ID_Utilizador VARCHAR(10),
        Prioridade_Atual VARCHAR(20),
        Total_Anterior INT,
        Novas_Penalizacoes INT,
        Total_Final INT
    );

    -- Obter informações dos utilizadores afetados
    INSERT INTO @utilizadores_afetados
    SELECT 
        u.ID_Utilizador,
        u.Prioridade,
        -- Total anterior (excluindo as novas)
        ISNULL((
            SELECT SUM(p.Valor_Penalizacao)
            FROM Penalizacao p
            INNER JOIN Reserva r ON p.ID_Reserva = r.ID_Reserva
            WHERE r.ID_Utilizador = u.ID_Utilizador
            AND p.ID_Penalizacao NOT IN (SELECT ID_Penalizacao FROM inserted)
        ), 0) as Total_Anterior,
        -- Novas penalizações
        ISNULL((
            SELECT SUM(i.Valor_Penalizacao)
            FROM inserted i
            INNER JOIN Reserva r ON i.ID_Reserva = r.ID_Reserva
            WHERE r.ID_Utilizador = u.ID_Utilizador
        ), 0) as Novas_Penalizacoes,
        -- Total final
        ISNULL((
            SELECT SUM(p.Valor_Penalizacao)
            FROM Penalizacao p
            INNER JOIN Reserva r ON p.ID_Reserva = r.ID_Reserva
            WHERE r.ID_Utilizador = u.ID_Utilizador
        ), 0) as Total_Final
    FROM Utilizador u
    WHERE EXISTS (
        SELECT 1 
        FROM inserted i 
        INNER JOIN Reserva r ON i.ID_Reserva = r.ID_Reserva 
        WHERE r.ID_Utilizador = u.ID_Utilizador
    );

    -- Atualizar prioridades
    UPDATE u
    SET u.Prioridade = 
        CASE 
            WHEN ua.Prioridade_Atual = 'Maxima' AND FLOOR(ua.Total_Final/5) > FLOOR(ua.Total_Anterior/5) THEN 'Acima da Media'
            WHEN ua.Prioridade_Atual = 'Acima da Media' AND FLOOR(ua.Total_Final/5) > FLOOR(ua.Total_Anterior/5) THEN 'Media'
            WHEN ua.Prioridade_Atual = 'Media' AND FLOOR(ua.Total_Final/5) > FLOOR(ua.Total_Anterior/5) THEN 'Abaixo da Media'
            WHEN ua.Prioridade_Atual = 'Abaixo da Media' AND FLOOR(ua.Total_Final/5) > FLOOR(ua.Total_Anterior/5) THEN 'Minima'
            ELSE ua.Prioridade_Atual
        END
    FROM Utilizador u
    INNER JOIN @utilizadores_afetados ua ON u.ID_Utilizador = ua.ID_Utilizador;

END;