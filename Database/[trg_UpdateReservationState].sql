CREATE OR ALTER TRIGGER [dbo].[trg_UpdateReservationState]
ON [dbo].[ReservaEquipamento]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Atualizar o estado da reserva para 'active' ou 'waiting'
    UPDATE r
    SET r.Estado = CASE
                      WHEN NOT EXISTS (
                          SELECT 1
                          FROM dbo.ReservaEquipamento re
                          INNER JOIN dbo.Equipamento e ON re.ID_Equipamento = e.ID_Equipamento
                          WHERE re.ID_Reserva = r.ID_Reserva
                            AND e.Estado_Equipamento != 'disponível'
                            AND re.imprescindivel = 'Y'
                      )
                      THEN 'active'
                      ELSE 'waiting'
                   END
    FROM dbo.Reserva r
    WHERE EXISTS (
        SELECT 1
        FROM inserted i
        WHERE r.ID_Reserva = i.ID_Reserva
    );
END;
