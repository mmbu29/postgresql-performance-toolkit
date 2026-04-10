/*
 * SCRIPT: Index Recommendation Examples
 * -------------------------------------
 * Purpose: Transition from "Dead Weight" detection to "High Performance" indexing.
 * Includes: Detection queries and specialized index patterns for 2026 workloads.
 */

-- [DETECTION] Identify Missing or Low-Usage Indexes
-- This helps you find indexes that are literally "paying rent" (using I/O) without working.
SELECT
    schemaname,
    relname AS table_name,
    indexrelname AS index_name,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE idx_scan < 50 -- Threshold for "Low Usage"
ORDER BY idx_scan ASC;

-- [RECOMMENDATION 1: High-Frequency Filter]
-- Best for: Columns used constantly in WHERE clauses (e.g., login timestamps).
-- Strategy: Simple B-Tree.
CREATE INDEX idx_users_last_login ON users(last_login);

-- [RECOMMENDATION 2: Composite Index (Leading Column Strategy)]
-- Best for: Multi-column filters like "Show me 'active' orders from the last 7 days."
-- Strategy: Place the most selective column (status) first. 
-- Adding DESC to the timestamp aligns with common 'ORDER BY' requirements.
CREATE INDEX idx_orders_status_created ON orders(status, created_at DESC);

-- [RECOMMENDATION 3: Partial Index (The Cost Saver)]
-- Best for: Large tables where you only care about a tiny subset of data.
-- Strategy: Only indexes rows matching the WHERE clause. 
-- Results in a much smaller index footprint and faster maintenance.
CREATE INDEX idx_orders_failed_only ON orders(status)
WHERE status = 'FAILED';

-- [RECOMMENDATION 4: Covering Index (Index-Only Scans)]
-- Best for: Queries that only need a few columns.
-- Strategy: Use INCLUDE to add extra data to the leaf nodes, avoiding a Heap Fetch.
-- Useful for your 2026 high-throughput data pipelines.
CREATE INDEX idx_orders_id_include_total ON orders(order_id) 
INCLUDE (total_amount);