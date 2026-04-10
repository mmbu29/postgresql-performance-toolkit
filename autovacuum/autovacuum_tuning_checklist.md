# Autovacuum Tuning Checklist

Autovacuum is essential for controlling table and index bloat, maintaining healthy visibility maps, and preventing transaction ID wraparound.  
This checklist provides the key parameters, best practices, and recommended baseline settings for production PostgreSQL environments.

---

## Key Parameters

### 🔧 autovacuum_vacuum_scale_factor
Percentage of table growth that triggers VACUUM.  
Lower values = more frequent vacuuming.

### 🔧 autovacuum_analyze_scale_factor
Percentage of table changes that trigger ANALYZE.  
Lower values = fresher statistics.

### 🔧 autovacuum_vacuum_cost_limit
Controls how aggressively autovacuum can consume I/O.  
Higher values = faster cleanup.

### 🔧 autovacuum_vacuum_cost_delay
Delay between vacuum cost cycles.  
Lower values = more aggressive vacuuming.

### 🔧 maintenance_work_mem
Memory used for VACUUM, ANALYZE, and index maintenance operations.

---

## Best Practices

### ✔ Reduce scale factors for large tables (0.01–0.05)
Large tables accumulate dead tuples quickly.  
Lower scale factors ensure timely cleanup.

### ✔ Increase cost limit for busy OLTP systems
OLTP workloads benefit from faster vacuum cycles to avoid bloat and index degradation.

### ✔ Monitor `pg_stat_all_tables` for dead tuples
Key columns:
- `n_dead_tup`
- `last_autovacuum`
- `vacuum_count`

### ✔ Enable verbose autovacuum logging
Helps diagnose:
- Autovacuum lag  
- Blocked autovacuum workers  
- Long‑running transactions preventing cleanup  

Example:
```conf
log_autovacuum_min_duration = 0

