
---------------------- ALTAS Y SU PRIMER PAGO EN SUSTENTO --------------------

WITH TRAMAS AS(
      SELECT CERTIFICADO, TIPO_DE_MOVIMIENTO, TIPO_DE_REGISTRO, 
            DATE(FECHA_DE_INICIO_DEL_SEGURO) AS FECHA_INICIO, 
            DATE(FECHA_FIN_DEL_SEGURO) AS FECHA_FIN, TRAMA_ORIGINAL AS TRAMA_ALTA,
            DATE(FECHA_TRAMA) AS FECHA_TRAMA

      FROM (
            SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2025`
            UNION ALL 
            SELECT * FROM `produccion.TRAMAS_diarias_BBVA_2026`
            ) 
      WHERE TIPO_DE_MOVIMIENTO IN ('1') AND TIPO_DE_SEGURO = '904'
),
CRUCE AS (
      SELECT T.*, S.Nro_Certificado, S.Prima, S.trama_original AS TRAMA_PRIMER_PAGO, fecha_recepcion,
      ROW_NUMBER() OVER (PARTITION BY Nro_Certificado ORDER BY fecha_recepcion) AS NRO
      FROM TRAMAS T
      JOIN `develop.TABLA_SUSTENTO_BBVA` S ON T.CERTIFICADO= S.Nro_Certificado
)
SELECT *
FROM CRUCE 
WHERE NRO = 1
LIMIT 3000

---------------  CRUCE DE CERTIFICAOD CONVENIOS CON ERRORES, MORAIRA Y ANGI -------------------

CREATE OR REPLACE TABLE `produccion.TEMP_CONVENIOS_CRUCE_MORAIMA_ANGI` AS
WITH CONVENIOS AS (
  SELECT  Nro_Certificado, COUNT(*) CANT_PAGOS, SUM(Prima) AS TOTAL_PRIMA
  FROM `develop.TABLA_SUSTENTO_BBVA`
  WHERE Codigo_Subproducto IN ('958', '968', '972')
  GROUP BY Nro_Certificado
),
errores AS (
  SELECT DISTINCT *
  FROM `produccion.temp_ERRORES_prestamos_10-07-26`
)
SELECT C.*, E.*, M.CERTIFICADO IS NOT NULL AS ESTA_EN_MORAIMA, A.CERTIFICADO IS NOT NULL AS ESTA_EN_ANGI
FROM CONVENIOS C
LEFT JOIN errores E ON C.NRO_CERTIFICADO=E.CODIGO_CERTIFICADO
LEFT JOIN (SELECT DISTINCT *
            FROM `produccion.temp_cert_moraima_10-07`) M 
            ON C.NRO_CERTIFICADO= M.CERTIFICADO
LEFT JOIN (SELECT DISTINCT *
            FROM `produccion.temp_cert_angie_10-07`) A
            ON C.NRO_CERTIFICADO= A.CERTIFICADO
----------------------------------------------------------------------

WITH cert_pagos AS (
      SELECT *, 
        CONCAT('00',Certificado,'_',prima) as llave
      FROM `produccion.temp_pagos_retroact_16-06`
)
SELECT CONCAT('00',P.Certificado) AS CERTIFICADO, p.fecha_inicio, p.fecha_fin, p.prima, S.Nro_Certificado AS CERTIFICADO_SUSTENTO, S.Prima AS PRIMA_SUSTENTO, nombre_archivo_trama, fecha_recepcion 
FROM cert_pagos p
JOIN `develop.TABLA_SUSTENTO_BBVA` S ON p.llave= CONCAT(S.Nro_Certificado,'_',S.Prima)
ORDER BY Nro_Certificado, fecha_recepcion

----------------------------------------------------------------------------------------

SELECT  
  Moneda, 
  count(*) AS Cantidad_registros, 
  sum(Prima) AS Total_Prima, 
FROM `develop.PRESTAMOS_2025_BBVA` 
WHERE fecha_recepcion between '2025-08-4' and '2025-09-01'
GROUP BY Moneda;

-------------------------------------------------------------------------------------------
SELECT  
  Moneda, 
  count(*) AS Cantidad_registros, 
  sum(Prima) AS Total_Prima, 
FROM `develop.TABLA_SUSTENTO_BBVA` 
WHERE fecha_recepcion ='2025-08-15' and Codigo_Subproducto in ("901", "902", "903", "906", "941", "943", "972", "959", "961", "968", "963", "964", "962", "951", "958", "953", "954", "952", "969","966")
GROUP BY Moneda;
----------------------------------------------------------------------------------------

WITH certificados_unicos AS(
  SELECT  DISTINCT Nro_Certificado
  FROM `develop.TABLA_SUSTENTO_BBVA` 
  WHERE fecha_recepcion ='2025-07-15' and Codigo_Subproducto in ("901", "902", "903", "906", "941", "943", "972",
            "959", "961", "968", "963", "964", "962", "951", "958", "953", "954", "952", "969","966")
)
SELECT cu.Nro_Certificado, tp.trama_original
FROM certificados_unicos cu
LEFT JOIN `develop.TABLA_PRESTAMOS_BBVA` tp ON cu.Nro_Certificado = tp.Certificado
WHERE Tipo_Movimiento = '1' AND Tipo_Registro = '01';


SELECT Certificado, count(*) AS contador 
FROM `develop.TABLA_PRESTAMOS_BBVA` 
WHERE Tipo_Movimiento = '1' AND Tipo_Registro = '01'
GROUP BY Certificado
HAVING contador > 1;

-----------------------------------------------------------------------------

SELECT Certificado, trama_original, fecha_recepcion
FROM `develop.TABLA_PRESTAMOS_BBVA` 
WHERE fecha_recepcion BETWEEN '2024-07-01' AND '2025-08-01' AND Tipo_Movimiento = '6';

------- Cruce para ver los certificados en alta --------
SELECT Fecha_Afiliacion, Fecha_Inicio_Seguro, cu.Certificado
FROM `produccion.Temp_certificados` cu
INNER JOIN `develop.TABLA_PRESTAMOS_BBVA` tp ON cu.certificado = tp.Certificado
WHERE Tipo_Movimiento = '1' AND Tipo_Registro = '01';


------- Cruce para ver los certificados martha --------
SELECT cu.Certificado, Fecha_Inicio_Seguro, Fecha_Fin_Seguro, fecha_recepcion, Tipo_Movimiento
FROM `develop.temp_cert_marta` cu
LEFT JOIN `develop.TABLA_PRESTAMOS_BBVA` tp ON cu.certificado = tp.Certificado
WHERE Tipo_Movimiento IN ('4');

----------- CONSULTA A TKT ----------------------------
SELECT cu.Certificado, fecha_recepcion, trama_original
FROM `develop.certificados_tkt_16-10` cu
LEFT JOIN `develop.TABLA_TKT_BBVA` tkt ON cu.certificado = tkt.Certificado
WHERE Tipo_Movimiento IN ('4');

SELECT distinct cu.Certificado, fecha_recepcion, trama_original, nombre_archivo_trama
FROM `develop.temp_certificados_tkt-21-11` cu
LEFT JOIN `develop.TABLA_TKT_BBVA` tkt ON cu.certificado = tkt.Certificado
WHERE Tipo_Movimiento IN ('1');

---------------------------------------------------
SELECT Certificado, count(*) AS contador
FROM `develop.temp_pagos_cert1`
GROUP BY CERTIFICADO
ORDER BY CONTADOR DESC;

SELECT *
FROM `develop.temp_pagos_cert1`
WHERE Certificado = '00110760644000068053'
ORDER BY fecha_recepcion DESC;

-------------------------------- SELECCIONAR EL ULTIMO PAGO EN TRAMAS DIARIAS DE UNA LISTA DE CERTIFICADOS -------------------------
SELECT *
FROM (
  SELECT 
    cu.Certificado,
    tp.Fecha_Inicio_Seguro,
    SAFE.PARSE_DATE('%Y%m%d', tp.Fecha_Inicio_Seguro) AS Fecha_Inicio,
    tp.Fecha_Fin_Seguro,
    SAFE.PARSE_DATE('%Y%m%d', tp.Fecha_Fin_Seguro)   AS Fecha_Fin,
    tp.fecha_recepcion,
    tp.Tipo_Movimiento,
    ROW_NUMBER() OVER (
      PARTITION BY cu.Certificado
      ORDER BY tp.fecha_recepcion DESC
    ) AS rn
  FROM `develop.temp_cert_marta2` cu
  LEFT JOIN `develop.TABLA_PRESTAMOS_BBVA` tp 
         ON cu.Certificado = tp.Certificado
  WHERE tp.Tipo_Movimiento IN ('4')
)
WHERE rn = 1;

-----------------------

SELECT C.CERTIFICADO, fecha_recepcion,trama_original        
FROM `develop.TABLA_TKT_BBVA` tkt
INNER JOIN `produccion.temp_cert_tkt` c ON c.CERTIFICADO= tkt.CERTIFICADO
WHERE Tipo_Movimiento = '1'
ORDER BY c.CERTIFICADO, fecha_recepcion;


------------- CRUCES DE CERTIFICADOS CON TABLA SUSTENTO (CON LLAVE)--------------------------
WITH pagos AS(
  SELECT CONCAT(
        CERTIFICADO, '_',
        FORMAT_DATE('%Y%m', PARSE_DATE('%d/%m/%Y', FECHA_INICIO))
      ) AS llave, *
  FROM `develop.temp_pagos-15-12`
),
tramas_sustento AS(
  SELECT CONCAT(
        Nro_Certificado, '_',
        FORMAT_DATE('%Y%m', fecha_recepcion)
      ) AS llave, fecha_recepcion, trama_original
  FROM `develop.TABLA_SUSTENTO_BBVA`

)
SELECT p.CERTIFICADO, p.FECHA_INICIO, ts.fecha_recepcion, ts.trama_original
FROM pagos p
LEFT JOIN tramas_sustento ts ON p.llave = ts.llave
WHERE ts.fecha_recepcion IS NOT NULL;

-------------- CRUCES DE CERTIFICADOS CON SUSTENTO -------------------------

SELECT p.CERTIFICADO, p.FECHA_INICIO, ts.fecha_recepcion, ts.trama_original
FROM (
  SELECT DISTINCT *
  FROM `develop.temp_pagos-15-12`
) p
INNER JOIN `develop.TABLA_SUSTENTO_BBVA` ts ON p.CERTIFICADO = ts.Nro_Certificado


--------------------------------------------------------------------------
SELECT Nro_Certificado, fecha_recepcion, trama_original
FROM `develop.TABLA_SUSTENTO_BBVA`
WHERE Nro_Certificado IN ('00110921494000230599','00110241754001160210','00110114674000456018',
                  '00110091684000009387','00110091684000009387','00110103984000897766','00110091604000007783')
ORDER BY fecha_recepcion


---------------------------------------------------------------------------------------

SELECT Codigo_Subproducto, P.PRODUCTO, Moneda,
  count(*) AS Cantidad_registros, 
  sum(Prima) AS Total_Prima, 
FROM `develop.TABLA_SUSTENTO_BBVA` S
JOIN `produccion.EQUIVALENCIAS_PRODUCTOS` P ON S.Codigo_Subproducto = P.CODIGO_PRODUCTO
WHERE Codigo_Subproducto NOT IN ("901", "902", "903", "906", "941", "943", "972", "959", "961", "968", "963", "964", "962", "951", "958", "953", "954", "952", "969","966")
GROUP BY Codigo_Subproducto, P.PRODUCTO, Moneda;


SELECT MONEDA, COUNT(*) AS CANTIDAD
FROM `develop.TABLA_SUSTENTO_BBVA` 
WHERE Codigo_Subproducto = '918' AND fecha_recepcion = '2026-01-15'
GROUP BY MONEDA;


SELECT *
FROM `develop.TABLA_SUSTENTO_BBVA` 
WHERE Codigo_Subproducto = '918' AND fecha_recepcion = '2026-01-15'
LIMIT 800000 OFFSET 800000
---------------------------------------------------------------------------------------

SELECT Nro_Certificado, fecha_recepcion, trama_original
FROM `develop.TABLA_SUSTENTO_BBVA` 
WHERE Nro_Certificado = '00110189864000397029' AND fecha_recepcion >= '2025-01-15'
ORDER BY fecha_recepcion

------------------------------- CRUCE DE CERTIFICADOS Y SUSTENTO ------------------------
WITH cert_huecos AS (
      SELECT CERTIFICADO, SAFE.PARSE_DATE('%d/%m/%Y', FECHA_FIN_PRO) AS FECHA_FIN_PROC, 
            SAFE.PARSE_DATE('%d/%m/%Y', FECHA_INI_ERR) AS FECHA_INI_ERROR, 
            FORMAT_DATE('%Y%m', SAFE.PARSE_DATE('%d/%m/%Y', FECHA_FIN_PRO)) AS YEAR_MES_FECHA_FIN,
            FORMAT_DATE('%Y%m', SAFE.PARSE_DATE('%d/%m/%Y', FECHA_INI_ERR)) AS YEAR_MES_FECHA_INI_ERR
      FROM `produccion.temp_cert_huecos-18-03`
)
SELECT H.CERTIFICADO, H.FECHA_FIN_PROC, H.FECHA_INI_ERROR, S.fecha_recepcion, S.trama_original
FROM cert_huecos H
JOIN `develop.TABLA_SUSTENTO_BBVA` S ON H.CERTIFICADO= S.Nro_Certificado
WHERE FORMAT_DATE('%Y%m', S.fecha_recepcion) BETWEEN YEAR_MES_FECHA_FIN AND YEAR_MES_FECHA_INI_ERR
ORDER BY H.CERTIFICADO, S.fecha_recepcion
