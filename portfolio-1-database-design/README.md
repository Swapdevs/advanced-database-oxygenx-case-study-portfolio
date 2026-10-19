# Portfolio 1: Database Design and Modelling

**Case study:** Oxygen X Finance Company Ltd (Personal & Salary Loans, Business & SME Financing, BNPL / OxygenNow, Investment & Fund Management, General Banking & Digital Services)
**Database:** MySQL 8.0 (8.0.16 or later required so `CHECK` constraints are enforced)

## Files in this folder

| File | Purpose |
|---|---|
| `schema.sql` | Creates the `oxygenx_finance` database: 21 tables, 25 foreign keys, plus `UNIQUE`, `NOT NULL`, `CHECK` and `ENUM` constraints |
| `er-diagram.mermaid` | ER diagram source (Mermaid) |
| `er-diagram.png` | Exported image of the ER diagram `<add after exporting>` |
| `normalisation.md` | Step-by-step normalisation from a flat loan record to 3NF, with a BCNF check |
| `screenshots/` | Evidence from my own run of the schema `<add screenshots>` |

## How it was implemented

1. Chose Oxygen X Finance as the case study and listed the data and operations for each of its five services.
2. Identified the entities and relationships and drew the ER diagram.
3. Normalised the design (see `normalisation.md`) to remove repeating groups, partial dependencies and transitive dependencies.
4. Wrote `schema.sql` with keys and constraints that enforce the business rules (for example positive amounts, non-negative balances, valid date ranges, one loan per application).

## How it was tested

```bash
# Run from the repository root; enter your MySQL password when prompted
mysql -u root -p < portfolio-1-database-design/schema.sql

mysql -u root -p -e "SELECT COUNT(*) AS tables_created FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'oxygenx_finance'; SELECT COUNT(*) AS fk_count FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = 'oxygenx_finance';"
```

**Expected result:** `tables_created = 21` and `fk_count = 25`.
**My result:** `<fill in after running it yourself and attach the screenshot>`

## Key design decisions

- **Loan lifecycle split into four tables** (application, loan, repayment schedule, repayment). An application can be rejected and never become a loan, and "amount owed" must be kept apart from "amount paid".
- **`customer_employment` and `business_profile` kept separate from `customer`**, because salary loans and SME financing need different data and combining them would create many NULLs.
- **`investment_holding` uses a composite primary key** `(customer_id, fund_id)`.
- **`transfer` references `account` twice** (sender and receiver), with a `CHECK` that they differ.
- **Cards store only the last four digits**, never a full card number.
- **Deliberate denormalisation** of `loan.interest_rate`, `loan.tenor_months`, `account.balance`, `account_transaction.balance_after` and `loan.outstanding_balance`. The reasons are in section 5 of `normalisation.md`. Portfolio 2 measures the performance effect and Portfolio 3 covers keeping balances consistent.

## Challenges and lessons learned

`<Write this in your own words: what was difficult, what you changed during design, what you learned.>`
