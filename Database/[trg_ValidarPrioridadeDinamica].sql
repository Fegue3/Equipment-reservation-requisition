CREATE OR ALTER TRIGGER [dbo].[trg_ValidarPrioridadeDinamica]
ON [dbo].[Utilizador]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Atualiza a prioridade corrente para garantir que nunca ultrapassa o limite baseado no tipo de utilizador
    UPDATE Utilizador
    SET Prioridade = 
        CASE 
            -- Presidente do Departamento (PD): sempre "máxima"
            WHEN ID_TipoUtilizador = 'PD' THEN 'Maxima'

            -- Professores (PR): pode ser diminuída, mas não pode exceder "acima da média"
            WHEN ID_TipoUtilizador = 'PR' AND Prioridade = 'Maxima' THEN 'Acima da Media'

            -- Outros utilizadores: permitido "média", "abaixo da média" ou "mínima"
            WHEN ID_TipoUtilizador NOT IN ('PD', 'PR') AND Prioridade NOT IN ('Media', 'Abaixo da Media', 'Minima') THEN 'Media'

            -- Caso esteja dentro do permitido, mantém o valor atual
            ELSE Prioridade
        END
    WHERE ID_Utilizador IN (
        SELECT ID_Utilizador FROM inserted -- Apenas para os registros afetados
    );
END;
