# MIT 8103 Advanced Database Systems: Individual Portfolio

**Programme:** Master of Information Technology, MIVA Open University  
**Session:** 2026/2027, First Semester Continuous Assessment (40 marks)  
**Student:** `<your full name>` | **Matric/Student ID:** `<your ID>`  
**Database:** MySQL 8.0 (NoSQL component: `<MongoDB / Redis / other, decide in Portfolio 4>`)

---

## 1. Selected Case Study: Oxygen X Finance Company Ltd

- **Organisation / Scenario:** Oxygen X Finance Company Ltd, a simulated finance company used consistently across all five portfolio activities.
- **Nature of the Business:** A digital-first financial services company offering five core services:
  - Personal & Salary Loans
  - Business & SME Financing
  - Buy Now, Pay Later (BNPL / OxygenNow)
  - Investment & Fund Management
  - General Banking & Digital Services

### Users of the Database
- Customers (individuals and businesses)
- Loan officers and credit analysts (review applications)
- Relationship managers and tellers (customer and account servicing)
- Fund managers (manage investment funds)
- BNPL partner merchants
- Administrators and auditors

### Major Data Stored
Customers and KYC status, business profiles, employers and salaries, accounts, account transactions, transfers, cards, bill payments, loan applications, loans, repayment schedules, repayments, BNPL merchants/orders/installments, investment funds, investment orders, and customer fund holdings.

### Key Operations Supported
- Open accounts, deposit, withdraw, and transfer funds (with reversal of failed transfers)
- Submit, review, approve, and disburse loans; generate repayment schedules; record repayments
- Place BNPL orders and collect installments
- Buy and sell investment fund units and track holdings
- Audit account balances and detect overdue loans/installments

---

## 2. Repository Structure

```
advanced-database-portfolio/
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
## 3. Progress Tracker

| Portfolio	| Activity |	Marks |	Status |
| --- | --- | --- | --- |
| 1 | Database Design and Modelling | 7 | In progress: schema and ER diagram done; normalisation write-up pending|
| 2 | Query Processing and Optimisation | 7 | Not started |
| 3 | Transactions and Concurrency | 7 | Not started |
| 4 | NoSQL and Advanced Data Models | 7 | Not started |
| 5 | Distributed and Cloud Database Exercise | 6 | Not started |
| Final | Documentation and technical reflection | 6 | Not started |

## 4. Portfolio 1: Database Design and Modelling   
### What Was Done   
- Designed a relational model of 21 tables covering all five Oxygen X services.
- Drew the ER diagram in Mermaid (er-diagram.mermaid); an exported image is stored beside it.
- Implemented the schema in MySQL with primary keys, foreign keys (25), UNIQUE, NOT NULL, CHECK, and ENUM constraints.

### Key Design Decisions
- Loans Architecture: Loans are modelled as application → loan → repayment_schedule → repayment, because an application may be rejected and never become a loan, and "amount owed" must be separate from "amount paid".
- Table Normalisation: customer_employment and business_profile are kept separate from customer to avoid sparse NULL columns and keep tables normalised.
- Composite Primary Keys: investment_holding uses a composite primary key (customer_id, fund_id).
- Security: Cards store only the last four digits, never the full card number.

### How to Run and Test
```
# Requires MySQL 8.0.16 or later (earlier versions parse but ignore CHECK constraints)
mysql -u root -p < portfolio-1-database-design/schema.sql

mysql -u root -p -e "USE oxygenx_finance; SHOW TABLES;"
```
Expected Result: 21 tables and 25 foreign key constraints in the oxygenx_finance database. Verify the counts with:
```
SELECT COUNT(*) FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'oxygenx_finance';

SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'oxygenx_finance';
```
Evidence: portfolio-1-database-design/screenshots/
### 5. Portfolios 2 to 5   
Each remaining portfolio will have its own folder containing scripts, a README.md explaining how the work was implemented and tested, and supporting evidence (execution plans, screenshots, logs, configuration files).   

(Fill in a short section here as each one is completed.)

### 6. Individual Technical Reflection   
<Write after completing the work: design choices you made, challenges faced, and lessons learned. Use your own words.>
