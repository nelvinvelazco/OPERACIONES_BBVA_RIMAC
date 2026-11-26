CREATE OR REPLACE FUNCTION `produccion.FN_convertir_numero_trama` (valor STRING)
RETURNS FLOAT64
AS (
  CASE
    WHEN RIGHT(valor, 1) NOT IN ('{','A','B','C','D','E','F','G','H','I') THEN NULL
    ELSE
    (
      CAST(
        SAFE_CAST(SUBSTR(valor, 1, LENGTH(valor) - 1) AS INT64) *10
        +
        CASE RIGHT(valor, 1)
          WHEN '{' THEN 0
          WHEN 'A' THEN 1
          WHEN 'B' THEN 2
          WHEN 'C' THEN 3
          WHEN 'D' THEN 4
          WHEN 'E' THEN 5
          WHEN 'F' THEN 6
          WHEN 'G' THEN 7
          WHEN 'H' THEN 8
          WHEN 'I' THEN 9
        END
      AS NUMERIC) / 100.0 
    )
  END
)
