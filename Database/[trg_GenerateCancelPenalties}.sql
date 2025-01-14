CREATE OR ALTER   TRIGGER [dbo].[trg_GenerateCancelPenalties]
ON [dbo].[Reserva]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Atualizar reservas expiradas para o estado 'forgotten'
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.Estado NOT IN ('satisfied', 'canceled', 'forgotten')
          AND i.Data_Fim_Pedido < GETDATE()
    )
    BEGIN
        UPDATE r
        SET Estado = 'forgotten'
        FROM dbo.Reserva r
        INNER JOIN inserted i ON r.ID_Reserva = i.ID_Reserva
        WHERE r.Estado NOT IN ('satisfied', 'canceled', 'forgotten')
          AND r.Data_Fim_Pedido < GETDATE();

        -- Atualizar a prioridade do utilizador associado
        UPDATE Utilizador
        SET Prioridade = 
            CASE 
                WHEN Prioridade = 'Maxima' THEN 'Acima da Media'
                WHEN Prioridade = 'Acima da Media' THEN 'Media'
                WHEN Prioridade = 'Media' THEN 'Abaixo da Media'
                WHEN Prioridade = 'Abaixo da Media' THEN 'Minima'
                ELSE Prioridade
            END
        FROM Utilizador u
        INNER JOIN Reserva r ON u.ID_Utilizador = r.ID_Utilizador
        INNER JOIN inserted i ON r.ID_Reserva = i.ID_Reserva
        WHERE r.Estado = 'forgotten'
          AND EXISTS (
              SELECT 1
              FROM ReservaEquipamento re
              WHERE re.ID_Reserva = r.ID_Reserva AND re.imprescindivel = 'Y'
          )
          AND NOT EXISTS (
              SELECT 1
              FROM Penalizacao p
              WHERE p.ID_Reserva = r.ID_Reserva
                AND p.ID_Utilizador = u.ID_Utilizador
          );
    END
    -- Inserir penalizações para reservas canceladas
    INSERT INTO Penalizacao (Data_Penalizacao, Valor_Penalizacao, Motivo_Penalizacao, ID_Reserva, ID_Utilizador)
    SELECT 
        GETDATE() AS Data_Penalizacao, -- Data da penalização
        CASE 
            WHEN GETDATE() BETWEEN r.Data_Inicio_Pedido AND r.Data_Fim_Pedido THEN 
                CASE 
                    WHEN DATEDIFF(HOUR, r.Data_Inicio_Pedido, GETDATE()) < 3 THEN DATEDIFF(HOUR, r.Data_Inicio_Pedido, GETDATE())
                    ELSE 3
                END
            WHEN GETDATE() < r.Data_Inicio_Pedido AND DATEDIFF(HOUR, GETDATE(), r.Data_Inicio_Pedido) >= 2 THEN 0
            ELSE 1
        END AS Valor_Penalizacao,
        CASE 
            WHEN GETDATE() BETWEEN r.Data_Inicio_Pedido AND r.Data_Fim_Pedido THEN 'Cancelamento dentro do tempo de uso'
            WHEN GETDATE() < r.Data_Inicio_Pedido AND DATEDIFF(HOUR, GETDATE(), r.Data_Inicio_Pedido) >= 2 THEN 'Cancelamento antes de uso inferior a 2 horas'
            ELSE 'Cancelamento antes do início do período'
        END AS Motivo_Penalizacao,
        r.ID_Reserva,
        r.ID_Utilizador -- ID do utilizador associado à reserva
    FROM inserted r
    INNER JOIN deleted d ON r.ID_Reserva = d.ID_Reserva
    WHERE r.Estado = 'canceled' AND d.Estado <> 'canceled'; -- Detectar alterações para "canceled"
END;
