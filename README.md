# MIT 8103 Advanced Database Systems: Individual Portfolio

**Programme:** Master of Information Technology, MIVA Open University
**Session:** 2026/2027, First Semester Continuous Assessment (40 marks)
**Student:** `Christopher Akinsanmi` | **Student ID:** `ID`
**Database:** MySQL 8.0 (NoSQL component: `MongoDB / Redis / other, decide in Portfolio 4`)

---

## 1. Selected Case Study: Oxygen X Finance Company Ltd

**Organisation / scenario:** Oxygen X Finance Company Ltd, a simulated finance company used consistently across all five portfolio activities.

**Nature of the business:** A digital-first financial services company offering five core services:

1. Personal & Salary Loans
2. Business & SME Financing
3. Buy Now, Pay Later (BNPL / OxygenNow)
4. Investment & Fund Management
5. General Banking & Digital Services

**Users of the database:**
- Customers (individuals and businesses)
- Loan officers and credit analysts (review applications)
- Relationship managers and tellers (customer and account servicing)
- Fund managers (manage investment funds)
- BNPL partner merchants
- Administrators and auditors

**Major data stored:** Customers and KYC status, business profiles, employers and salaries, accounts, account transactions, transfers, cards, bill payments, loan applications, loans, repayment schedules, repayments, BNPL merchants/orders/installments, investment funds, investment orders, and customer fund holdings.

**Key operations supported:**
- Open accounts, deposit, withdraw, and transfer funds (with reversal of failed transfers)
- Submit, review, approve, and disburse loans; generate repayment schedules; record repayments
- Place BNPL orders and collect installments
- Buy and sell investment fund units and track holdings
- Audit account balances and detect overdue loans/installments

---

## 2. Repository Structure

```
advanced-database-oxygenx-case-study-portfolio/
├── portfolio-1-database-design/
│   ├── schema.sql
│   ├── er-diagram.mermaid
│   └── (er-diagram.png, screenshots, normalisation.md)
├── portfolio-2-query-optimisation/
├── portfolio-3-transactions-concurrency/
├── portfolio-4-nosql/
├── portfolio-5-distributed-cloud/
└── README.md
```

---

## 3. Progress Tracker

| Portfolio | Activity | Marks | Status |
|---|---|---|---|
| 1 | Database Design and Modelling | 7 | In progress: schema and ER diagram done; normalisation done |
| 2 | Query Processing and Optimisation | 7 | Not started |
| 3 | Transactions and Concurrency | 7 | Not started |
| 4 | NoSQL and Advanced Data Models | 7 | Not started |
| 5 | Distributed and Cloud Database Exercise | 6 | Not started |
| Final | Documentation and technical reflection | 6 | Not started |

*(Update this table as each portfolio is completed and committed.)*

---

## 4. Portfolio 1: Database Design and Modelling

**What was done:**
- Designed a relational model of 21 tables covering all five Oxygen X services.
- Drew the ER diagram in Mermaid (`er-diagram.mermaid`); an exported image is stored beside it.
- Implemented the schema in MySQL with primary keys, foreign keys (25), `UNIQUE`, `NOT NULL`, `CHECK`, and `ENUM` constraints.

**Key design decisions:**
- Loans are modelled as application → loan → repayment schedule → repayment, because an application may be rejected and never become a loan, and "amount owed" must be separate from "amount paid".
- `customer_employment` and `business_profile` are kept separate from `customer` to avoid sparse NULL columns and keep tables normalised.
- `investment_holding` uses a composite primary key `(customer_id, fund_id)`.
- Cards store only the last four digits, never the full card number.

**How to run and test:**

```bash
# Requires MySQL 8.0.16 or later (earlier versions parse but ignore CHECK constraints)
mysql -u root -p < portfolio-1-database-design/schema.sql

mysql -u root -p -e "USE oxygenx_finance; SHOW TABLES;"
```

**Expected result:** 21 tables and 25 foreign key constraints in the `oxygenx_finance` database.
Verify the counts with:

```sql
SELECT COUNT(*) FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'oxygenx_finance';

SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'oxygenx_finance';
```

**Evidence:** `portfolio-1-database-design/screenshots/` ` Screenshot`

---

## 5. Portfolios 2 to 5

Each remaining portfolio will have its own folder containing scripts, a README explaining how the work was implemented and tested, and supporting evidence (execution plans, screenshots, logs, configuration files).

*(Fill in a short section here as each one is completed.)*

---

## 6. Individual Technical Reflection

`Write after completing the work: design choices you made, challenges faced, and lessons learned. Use your own words.`

---

## 7. References

`List textbooks, MySQL documentation, tutorials, datasets, and libraries you used.`

- MySQL 8.0 Reference Manual: https://dev.mysql.com/doc/refman/8.0/en/
- Mermaid documentation (ER diagrams): https://mermaid.js.org/syntax/entityRelationshipDiagram.html

---
