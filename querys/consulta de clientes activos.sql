WITH certificados_pagos AS (       
  SELECT CERTIFICADO, TRAMA_ORIGINAL, FECHA_DE_INICIO_DEL_SEGURO
  FROM (
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2024`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2025`
  )
  WHERE TIPO_DE_SEGURO = '829' AND TIPO_DE_MOVIMIENTO IN ('4') AND
  FECHA_DECLARADA BETWEEN '2025-01-01' AND '2025-12-31'
),
filtro_tramas_bajas AS (       
  SELECT *
  FROM (SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2018`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2019`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2020`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2021`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2022`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2023`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2024`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2025`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2026`
      )
  WHERE TIPO_DE_SEGURO = '829'AND TIPO_DE_MOVIMIENTO IN ('2','6') AND
  FECHA_DECLARADA <= '2025-12-31'
),
certificados_activos AS (
  SELECT DISTINCT cp.CERTIFICADO
  FROM certificados_pagos cp  
  LEFT JOIN filtro_tramas_bajas tb ON tb.CERTIFICADO= cp.CERTIFICADO
  WHERE tb.CERTIFICADO IS NULL
),
datos_extraidos AS(
  SELECT ce.CERTIFICADO, SUBSTR(TRAMA_ORIGINAL, 150, 1) AS TIPO_DOC,
        SUBSTR(TRAMA_ORIGINAL, 151, 10) AS NUMERO_DOC,
        SUBSTR(TRAMA_ORIGINAL, 50, 20) AS APELLIDO_PATERINO, 
        SUBSTR(TRAMA_ORIGINAL, 80, 30) AS APELLIDO_MATERNO,
        SUBSTR(TRAMA_ORIGINAL, 110, 30) AS NOMBRES
        #SUBSTR(TRAMA_ORIGINAL, 440, 2) AS TIPO_PLAN, TRAMA_ORIGINAL 
  FROM certificados_activos ce
  INNER JOIN certificados_pagos cp ON ce.CERTIFICADO= cp.CERTIFICADO 
),
clientes_unicos AS (
SELECT *
FROM datos_extraidos
  QUALIFY
    ROW_NUMBER() OVER (
      PARTITION BY CERTIFICADO, TIPO_DOC, NUMERO_DOC
      ORDER BY 1
    ) = 1
)
SELECT COUNT(*) AS CANTIDAD
FROM clientes_unicos;

--------------------------------- verificando todos los años -----------------------------
CREATE OR REPLACE TABLE `produccion.TEMP_CERTIFICADOS ACTIVOS_SATA` AS
WITH certificados_pagos AS (       
  SELECT CERTIFICADO, FECHA_DE_INICIO_DEL_SEGURO, FECHA_DECLARADA, PERIODO_DE_PAGO
  FROM (
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2018`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2019`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2020`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2021`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2022`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2023`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2024`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2025`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2026`
  )
  WHERE TIPO_DE_SEGURO = '816' AND TIPO_DE_MOVIMIENTO IN ('4') #AND
 # FECHA_DECLARADA BETWEEN '2025-02-01' AND '2026-01-31'
),
filtro_tramas_bajas AS (       
  SELECT CERTIFICADO, FECHA_DE_INICIO_DEL_SEGURO, FECHA_DECLARADA
  FROM (SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2018`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2019`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2020`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2021`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2022`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2023`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2024`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2025`
        UNION ALL
        SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2026`
      )
  WHERE TIPO_DE_SEGURO = '816'AND TIPO_DE_MOVIMIENTO IN ('2','6') #AND
  #FECHA_DECLARADA <= '2025-01-01'
),
certificados_activos AS (
  SELECT DISTINCT cp.CERTIFICADO
  FROM certificados_pagos cp  
  LEFT JOIN filtro_tramas_bajas tb ON tb.CERTIFICADO= cp.CERTIFICADO
  WHERE tb.CERTIFICADO IS NULL
),
pagos_sin_bajas AS (
  SELECT A.CERTIFICADO, DATE(FECHA_DE_INICIO_DEL_SEGURO) AS FECHA_INICIO, 
          DATE(FECHA_DECLARADA) AS FECHA_RECEPCION, PERIODO_DE_PAGO
  FROM certificados_activos A
  INNER JOIN certificados_pagos P ON A.CERTIFICADO= P.CERTIFICADO
)
SELECT *
FROM (
      SELECT *, ROW_NUMBER() OVER  (PARTITION BY CERTIFICADO ORDER BY FECHA_RECEPCION DESC ) AS NRO
      FROM pagos_sin_bajas
      )
WHERE NRO=1 AND (PERIODO_DE_PAGO != 'M' OR FECHA_RECEPCION >= '2025-11-01')