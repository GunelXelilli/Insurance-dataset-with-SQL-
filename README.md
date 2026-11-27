# Insurance Data: SQL Window Functions Project

A hands-on project for practicing **SQL window functions** and **CTEs** on a synthetic insurance dataset, queried in MySQL 8.

> **Note:** All data is synthetic. It does not represent real customers, companies or individuals. Amounts are in AZN.

## Goal

- Apply window functions to realistic business questions
- Build complex queries step by step with CTEs
- Calculate core insurance metrics (premiums, claims, loss ratio) in SQL

## Database

| Table | Rows | Contents |
|-------|------|----------|
| `musteriler` (customers) | 300 | Name, gender, date of birth, city |
| `agentler` (agents) | 10 | Sales agents and their branches |
| `polisler` (policies) | 620 | Type, term, coverage, premium, status |
| `odenisler` (payments) | 2,911 | Premium payments (monthly, quarterly, annual, one-time) |
| `iddialar` (claims) | 316 | Event type, claimed and paid amounts |

### Relationships

```
musteriler ──< polisler >── agentler
                 │
                 ├──< odenisler
                 └──< iddialar
```

- `musteriler.musteri_id` → `polisler.musteri_id`
- `agentler.agent_id` → `polisler.agent_id`
- `polisler.polis_id` → `odenisler.polis_id` and `iddialar.polis_id`

### Key columns

| Column | Description |
|--------|-------------|
| `polisler.sigorta_novu` | Policy type: Auto (KASKO), Compulsory Auto, Health, Property, Life, Travel |
| `polisler.illik_premium` | Annual premium (company revenue) |
| `polisler.sigorta_meblegi` | Maximum coverage amount |
| `odenisler.gecikme_gun` | Days the payment was late (0 = on time) |
| `iddialar.odenilen_mebleg` | Amount actually paid (NULL for claims still under review) |
| `iddialar.baxilma_tarixi` | Claim resolution date (NULL for claims still under review) |

A full column dictionary is in the `Sutun_izahi` sheet of `data/sigorta_datasi.xlsx`. Column names are written without special characters (no ə, ı, ş) to make SQL import easier.

## How to run

**Requirement:** MySQL **8.0 or higher** (needed for window functions).

1. Connect to your server in MySQL Workbench.
2. Go to **File → Open SQL Script** and open `sql/sigorta_mysql.sql`.
3. Click the lightning bolt (Execute). The script creates the database, tables and data.
4. The final query should return row counts of **300, 10, 620, 2911, 316**.

The script can be re-run safely (it drops and recreates the tables).

## Topics covered

- **Ranking:** `ROW_NUMBER`, `RANK`, `DENSE_RANK`, top N per group
- **Offset functions:** `LAG`, `LEAD` for month-over-month change and % growth
- **Running and rolling totals:** `ROWS BETWEEN ... PRECEDING AND CURRENT ROW`
- **Distribution:** `NTILE`, `PERCENT_RANK`, `CUME_DIST`
- **CTEs:** multi-step queries with `WITH`
- **Also:** `JOIN`, `GROUP BY`, NULL handling

## Project structure

```
.
├── README.md
├── data/
│   ├── musteriler.csv
│   ├── agentler.csv
│   ├── polisler.csv
│   ├── odenisler.csv
│   ├── iddialar.csv
│   └── sigorta_datasi.xlsx
├── sql/
│   └── sigorta_mysql.sql
└── queries/
    └── (query files are added here)
```

## Key lessons learned

- Adding `ORDER BY` inside `OVER` turns an aggregate from a "group total" into a "running total".
- A **tie-breaker** (e.g. `ORDER BY salary DESC, id`) keeps `ROW_NUMBER` results stable when values are equal.
- Window functions cannot be used in `WHERE`; wrap them in a CTE and filter afterwards.
- For monthly or per-group totals, aggregate first with `GROUP BY`, then apply the window function.

## Author

[Your Name] · [Your LinkedIn URL]
