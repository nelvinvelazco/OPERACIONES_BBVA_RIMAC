

######################### BORRAR REGISTROS DE TABLAS ####################################

--DELETE FROM `produccion.ERRORES_desgravamen_prestamos`
--WHERE FECHA_PERIODO = '2025-09-05';

/*DELETE FROM `produccion.CONTROL_tramas_diarias`
--WHERE ARCHIVO_TXT IN ('RED020226_0302.TXT', 'RED030226_0402.TXT','RED040226_0502.TXT',
                      'RED050226_0602.TXT','RED060226_0902.TXT');
*/


--UPDATE `produccion.ERRORES_desgravamen_TC` 
--SET MONEDA = 'SIN DATO'
--WHERE MONEDA NOT IN ('SOL','USD') OR MONEDA IS NULL;


------------------------------- AGREGAR REGISTROS A UNA TABLA -------------------------------

INSERT INTO `produccion.TIPO_CAMBIO_DOLAR` (PERIODO, CAMBIO)
VALUES ('202610',3.433)

-------------------------------- MODIFICAR FECHA EXTRAYENDO DEL NOMBRE DE ARCHIVO ----------------------------------
/*CREATE TABLE `produccion.CONTROL_tramas_diarias-2` AS
SELECT ARCHIVO_TXT, FECHA_CARGA,CASE
            WHEN LENGTH(ARCHIVO_TXT)<12 THEN SAFE.PARSE_DATE('%Y%m%d', CONCAT('2006',SUBSTR(ARCHIVO_TXT, 4,4)))
            ELSE SAFE.PARSE_DATE('%d%m%y', SUBSTR(ARCHIVO_TXT, 4,6))

          END AS FECHA_TRAMA
FROM `produccion.CONTROL_tramas_diarias`*/

--------------------------- MODIFICAR FECHAS ---------------------------------
/*
UPDATE `produccion.TRAMAS_diarias_BBVA_2019` 
SET FECHA_TRAMA = DATE('2019-02-25'), FECHA_DECLARADA = DATE('2019-02-26')
WHERE NOMBRE_DE_ARCHIVO = 'RED250219_26.02.TXT'
*/

--------------------------- CREAR COPIA DE TABLA ------------------------------
CREATE TABLE `produccion.TRAMAS_diarias_BBVA_2010-1` AS
SELECT *
FROM `produccion.TRAMAS_diarias_BBVA_2010`;


------- Crear una tabla particionada a partir de otra ----------
CREATE OR REPLACE TABLE `produccion.TRAMAS_diarias_BBVA_2018`
PARTITION BY DATE(FECHA_DECLARADA)
CLUSTER BY FECHA_TRAMA, TIPO_DE_SEGURO, TIPO_DE_MOVIMIENTO, CERTIFICADO
AS
SELECT *
FROM `produccion.TRAMAS_diarias_BBVA_2018-1`;


CREATE OR REPLACE TABLE `produccion.TRAMAS_diarias_BBVA_2010`
PARTITION BY DATE(FECHA_TRAMA)
CLUSTER BY TIPO_DE_SEGURO, TIPO_DE_MOVIMIENTO, CERTIFICADO
AS
SELECT *
FROM `produccion.TRAMAS_diarias_BBVA_2010-1`;

------------ EXPORTAR DIRECTAMENTE A UN BUCKET ---------------------------

EXPORT DATA OPTIONS (
  uri='gs://rs-nprd-dlk-ue4-gcs-ryl-sftp_generics/consultas exportadas/TRAMAS PROD 812 - DESDE 2020 A 2026 - PARTE1_*.CSV',
  format='CSV',
  header=true,
  overwrite=true
) AS
WITH ENUMERADOS AS(
      SELECT ROW_NUMBER() OVER(ORDER BY CERTIFICADO) AS REG, *
      FROM `produccion.TEMP_CONSULTA_PROD_812`
)
SELECT *
FROM ENUMERADOS
WHERE REG BETWEEN 1 AND 800000
ORDER BY REG
