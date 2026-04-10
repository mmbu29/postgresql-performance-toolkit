# Query Optimization Example — EXPLAIN/ANALYZE Breakdown

## Problem
A critical reporting query was taking **12.4 seconds** to execute during peak hours, causing CPU spikes and blocking concurrent transactions in the Aurora PostgreSQL cluster.  
The latency was especially noticeable during the daily reporting window when analytical workloads overlapped with OLTP traffic.

---

## Original Query
```sql
SELECT o.id, o.created_at, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.created_at >= NOW() - INTERVAL '30 days'
ORDER BY o.created_at DESC;
Findings (EXPLAIN/ANALYZE)
🔍 1. Sequential Scan on orders (4.2M rows)
PostgreSQL performed a full table scan due to the missing index on created_at.

The date filter could not be optimized, resulting in high I/O and CPU usage.

🔍 2. Missing Index on orders.created_at
The query filters on a 30‑day window.

Without an index, PostgreSQL must evaluate the predicate for every row.

🔍 3. Hash Join Spill to Disk
The join between orders and customers spilled to disk.

Root cause: insufficient work_mem for the hash table size.

Disk spills significantly increased latency.

🔍 4. Customer Table Join OK
customers.id was indexed.

The join condition itself was not the bottleneck.

Fix
A descending index on created_at supports both the filter and the ORDER BY clause.

sql
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
Result
🚀 Performance Improvements
Query runtime reduced from 12.4 seconds → 118 ms

Hash join no longer spills to disk

CPU usage dropped by 40% during the reporting window

Execution plan shifted from:

❌ Seq Scan + Hash Join (Disk Spill)  
to

✅ Index Scan + Index-Only Scan