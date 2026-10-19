# Portfolio 1: Normalisation Explanation (Oxygen X Finance Company Ltd)

This document shows how the Oxygen X relational schema (`schema.sql`) was reached by normalising a single flat "loan record", step by step from unnormalised form (UNF) to Third Normal Form (3NF), with a BCNF check at the end.

**Why normalise?** Normalisation removes redundancy so that each fact is stored once. That prevents three kinds of anomaly:
- **Update anomaly:** one fact is stored in many rows, so changing it means editing all of them. Miss one and the data contradicts itself.
- **Insertion anomaly:** a fact cannot be recorded until an unrelated fact exists.
- **Deletion anomaly:** deleting one fact accidentally destroys another.

---

## 0. Starting point: the unnormalised loan record

Before any design, the loan team might track everything about a loan in one spreadsheet-style table:

```
LOAN_RECORD(
  loan_id, principal, loan_tenor, disbursed_at,
  customer_name, customer_email, customer_phone,
  employer_name, employer_industry, monthly_salary,
  product_code, product_name, product_rate,
  officer_name, officer_email,
  account_number,
  { installment_no, due_date, principal_due, interest_due, installment_status }   <-- repeating group
)
```

Sample data (the braces are a repeating group, so one loan holds several installments in one row):

| loan_id | customer_name | customer_phone | employer_name | employer_industry | product_code | product_name | product_rate | officer_name | installments |
|---|---|---|---|---|---|---|---|---|---|
| L001 | Christopher Akinsanmi | 0806455****, 07011112222 | Swapdevs Telecoms | Telecom | SAL-01 | Salary Loan | 24.00 | T. Bello | (1, 2026-11-01, ...), (2, 2026-12-01, ...), (3, 2027-01-01, ...) |
| L002 | Ada Obi | 0803123****, 07011112222 | Lagos Telecoms | Telecom | PER-01 | Personal Loan | 30.00 | T. Bello | (1, 2026-11-15, ...), (2, 2026-12-15, ...) |
| L003 | Suleiman Hammed | 0809988**** | Hammid Farms | Agriculture | SME-01 | SME Financing | 22.00 | K. Musa | (1, 2026-11-20, ...) |

**Problems visible immediately:**
- The installments are a repeating group inside one row, and `customer_phone` holds two values in one cell.
- Ada's name, phone, employer and the officer's details are repeated on every loan row.
- Product details (name, rate) are repeated for every loan that uses the product.

---

## 1. First Normal Form (1NF)

**Rule:** every column holds a single atomic value, there are no repeating groups, and every row is uniquely identified by a primary key.

**Actions:**
1. Make `customer_phone` atomic (one phone per value, a single phone column).
2. Split `customer_name` into `first_name` and `last_name` so each value is atomic.
3. Remove the repeating group: each installment becomes its own row.
4. With one row per installment, the key must identify the installment, so the primary key becomes the composite **(loan_id, installment_no)**.

**Result (1NF):**

```
LOAN_INSTALLMENT_FLAT(
  loan_id, installment_no,                      <-- composite PK
  principal, loan_tenor, disbursed_at,
  first_name, last_name, customer_email, customer_phone,
  employer_name, employer_industry, monthly_salary,
  product_code, product_name, product_rate,
  officer_name, officer_email,
  account_number,
  due_date, principal_due, interest_due, installment_status
)
```

This table is in 1NF, but it is worse for redundancy than before: every loan-level fact (customer, product, officer) is now repeated once per installment. A 24-month loan stores Ada's details 24 times.

---

## 2. Second Normal Form (2NF)

**Rule:** the table is in 1NF **and** no non-key column depends on only *part* of a composite key (no partial dependencies).

**Functional dependencies in the 1NF table (key = loan_id + installment_no):**

- `loan_id` → principal, loan_tenor, disbursed_at, customer details, employer details, product details, officer details, account_number   **(partial: depends on only part of the key)**
- `(loan_id, installment_no)` → due_date, principal_due, interest_due, installment_status   **(full dependency)**

The first group violates 2NF, because loan facts depend on `loan_id` alone, not on the installment number.

**Action:** split into two tables.

```
LOAN_FLAT(
  loan_id PK,
  principal, loan_tenor, disbursed_at,
  first_name, last_name, customer_email, customer_phone,
  employer_name, employer_industry, monthly_salary,
  product_code, product_name, product_rate,
  officer_name, officer_email,
  account_number
)

REPAYMENT_SCHEDULE(
  loan_id FK, installment_no,        <-- composite PK
  due_date, principal_due, interest_due, installment_status
)
```

`REPAYMENT_SCHEDULE` is exactly the `repayment_schedule` table in `schema.sql` (enforced there by `UNIQUE KEY uq_loan_installment (loan_id, installment_no)` and the foreign key to `loan`).

`LOAN_FLAT` has a single-column primary key, so partial dependencies are impossible and it is in 2NF. But it still contains hidden redundancy, which 3NF removes.

---

## 3. Third Normal Form (3NF)

**Rule:** the table is in 2NF **and** no non-key column depends on another non-key column (no transitive dependencies). Every non-key column must depend on "the key, the whole key, and nothing but the key".

**Transitive dependencies in `LOAN_FLAT`:**

| Chain | Meaning | Extracted table |
|---|---|---|
| loan_id → customer → name, email, phone | Customer facts depend on *who the customer is*, not on the loan | `customer` |
| customer → employer → employer_industry; customer → monthly_salary | Employment facts depend on the customer and employer | `employer`, `customer_employment` |
| loan_id → product_code → product_name, product_rate | Product facts depend on the product, not the loan | `product` |
| loan_id → officer → officer_name, officer_email | Officer facts depend on the staff member | `staff` |
| loan_id → account_number → account details | Account facts depend on the account | `account` |
| loan_id → application → customer, product, officer | The decision workflow is its own entity | `loan_application` |

**Action:** extract each group into its own table, replacing the repeated columns with a foreign key.

**Result (3NF), matching `schema.sql`:**

```
customer(customer_id PK, first_name, last_name, email UK, phone UK, ...)
employer(employer_id PK, name UK, industry)
customer_employment(employment_id PK, customer_id FK, employer_id FK, monthly_salary, start_date, end_date)
product(product_id PK, product_code UK, product_name, category, interest_rate, ...)
staff(staff_id PK, full_name, email UK, role)
account(account_id PK, customer_id FK, account_number UK, account_type, balance, status)
loan_application(application_id PK, customer_id FK, product_id FK, reviewed_by FK, requested_amount, tenor_months, purpose, status)
loan(loan_id PK, application_id FK UK, account_id FK, principal, interest_rate, tenor_months, outstanding_balance, disbursed_at, maturity_date, status)
repayment_schedule(schedule_id PK, loan_id FK, installment_no, due_date, principal_due, interest_due, status)   -- UK (loan_id, installment_no)
loan_repayment(repayment_id PK, schedule_id FK, txn_id FK UK, amount_paid, paid_at)
```

### Anomalies before and after

| Anomaly | Before (flat table) | After (3NF) |
|---|---|---|
| **Update** | Changing "Salary Loan" to a new product name means editing every loan row that uses it. Missing one leaves contradictory names. | Edit one row in `product`. |
| **Insertion** | You cannot record a new loan product, or a new employer, until a loan exists that uses it. | Insert directly into `product` or `employer`. |
| **Deletion** | Deleting Chidi's only loan also deletes everything known about Eze Farms. | Deleting a loan leaves `employer` and `customer` intact. |

---

## 4. Boyce-Codd Normal Form (BCNF) check

BCNF requires that every determinant (a column or set of columns that determines others) is a candidate key. In the final schema each table's determinants are its primary key or a declared `UNIQUE` key:

- `customer`: `customer_id`, `email`, `phone` are all candidate keys (each declared PK or `UNIQUE`).
- `account`: `account_id` and `account_number` are both candidate keys and both identify the same row.
- `account_transaction`: `txn_id` and `reference` are candidate keys.
- `repayment_schedule`: `schedule_id` (surrogate PK) and `(loan_id, installment_no)` (`UNIQUE`) are candidate keys.
- `investment_holding`: the only determinant is the composite key `(customer_id, fund_id)`.

No table has a determinant that is not a candidate key, so the schema satisfies BCNF as well as 3NF.

---

## 5. Deliberate denormalisation (decisions I can defend)

A few columns are intentionally stored even though they could be derived or looked up. These are design choices, not oversights:

1. **`loan.interest_rate` vs `product.interest_rate`.** The product's rate can change over time, but a loan must keep the rate agreed when it was disbursed. It is a historical fact about the loan, not a transitive dependency on the product.
2. **`loan.tenor_months` vs `loan_application.tenor_months`.** The tenor requested can differ from the tenor approved.
3. **`account.balance` and `account_transaction.balance_after`.** The balance could be recomputed by summing transactions, but doing so for every balance check is slow. Storing it trades a little redundancy for performance, and it must be kept consistent inside transactions (this is explored in Portfolio 3).
4. **`loan.outstanding_balance`.** Derivable from `repayment_schedule` and `loan_repayment`, stored for fast reporting. Portfolio 2 will measure the query-performance effect of reading it directly instead of aggregating.

---

## 6. Summary

| Normal form | Problem removed | Key action in Oxygen X |
|---|---|---|
| 1NF | Repeating groups, non-atomic values | Installments became rows; names and phones made atomic; composite key defined |
| 2NF | Partial dependencies | Loan facts separated from installment facts |
| 3NF | Transitive dependencies | Customer, employer, product, staff, account and application extracted |
| BCNF | Non-key determinants | Verified: all determinants are candidate keys |
