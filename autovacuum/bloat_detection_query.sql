-- Table bloat detection
SELECT
  current_database(),
  schemaname,
  tablename,
  ROUND(((bloat_ratio * table_size) / (1024 * 1024))::numeric, 0) AS bloat_mb,
  ROUND((table_size / (1024 * 1024))::numeric, 0) AS actual_mb,
  ROUND((bloat_ratio * 100)::numeric, 1) AS bloat_percentage
FROM (
  SELECT 
    schemaname, 
    tablename, 
    pg_table_size(quote_ident(schemaname) || '.' || quote_ident(tablename)) AS table_size,
    CASE 
      WHEN relpages > 0 THEN (relpages - est_relpages_ff)::float / relpages 
      ELSE 0 
    END AS bloat_ratio
  FROM (
    SELECT
      nspname AS schemaname,
      relname AS tablename,
      relpages,
      COALESCE(
        (SELECT (regexp_matches(reloptions::text, 'fillfactor=([0-9]+)'))[1]),
        '100'
      )::real AS fillfactor,
      CEIL(reltuples / ((8192 - 24) / (avg_width + 28))) AS est_relpages_ff
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN (SELECT schemaname, tablename, AVG(avg_width) AS avg_width 
               FROM pg_stats GROUP BY 1,2) s 
               ON s.schemaname = n.nspname AND s.tablename = c.relname
    WHERE c.relkind = 'r' 
      AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  ) AS sub
) AS final
WHERE bloat_ratio > 0
ORDER BY bloat_mb DESC;
