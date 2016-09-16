SELECT NOW()||' CREATE TEMPORARY TABLE TMP_ORG' AS LOG_DETAIL;

CREATE TEMP TABLE TMP_ORG AS
(
	SELECT DISTINCT ORG_KEY, LVL_2_NM AS REGION, LVL_3_NM AS DIVISION
	FROM ${NZ_DATABASE_DL}..DL_ORGANIZATION ORG
	WHERE LVL_2_NM LIKE '%Region'
	        AND ORG.HIER_NM = 'All Regions'
	        AND EFF_START_DAY_KEY <= (CURRENT_DATE - TO_DATE('${StartOfTime}','YYYY-MM-DD') + 1)
	        AND EFF_END_DAY_KEY > (CURRENT_DATE - TO_DATE('${StartOfTime}','YYYY-MM-DD') + 1)
)
DISTRIBUTE ON RANDOM;

SELECT NOW()||' CREATE External File for Organization' AS LOG_DETAIL;

CREATE EXTERNAL TABLE '${DIR_DATATGT}/${EXRT_FILE_NM}'
USING (DELIMITER ${NZ_DATA_DELIM} DATEDELIM '/' DATESTYLE 'MDY' timestyle '12HOUR'  REMOTESOURCE 'odbc' NULLVALUE '' ESCAPECHAR '\')  AS
SELECT ORG_KEY,
	REGION,
	DIVISION
FROM (
SELECT CAST(ORG_KEY as VARCHAR(15)) ORG_KEY,
	REGION,
	DIVISION
FROM TMP_ORG
UNION ALL
(SELECT 'ORG_KEY' ORG_KEY,
        'REGION' REGION,
        'DIVISION' DIVISION
FROM TMP_ORG
WHERE ORG_KEY IS NOT NULL
LIMIT 1)
) A
ORDER BY ORG_KEY DESC;
