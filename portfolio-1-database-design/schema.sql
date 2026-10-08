-- Oxygen X Finance Company Ltd - Relational schema (MySQL 8.0.16+)
-- MIT 8103 Advanced Database Systems - Portfolio 1

DROP DATABASE IF EXISTS oxygenx_finance;
CREATE DATABASE oxygenx_finance CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE oxygenx_finance;

-- ---------- Reference / people ----------
CREATE TABLE staff (
    staff_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    role        ENUM('LOAN_OFFICER','CREDIT_ANALYST','RELATIONSHIP_MANAGER','FUND_MANAGER','TELLER','ADMIN') NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE customer (
    customer_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_type ENUM('INDIVIDUAL','BUSINESS') NOT NULL DEFAULT 'INDIVIDUAL',
    first_name    VARCHAR(60) NOT NULL,
    last_name     VARCHAR(60) NOT NULL,
    email         VARCHAR(120) NOT NULL UNIQUE,
    phone         VARCHAR(20)  NOT NULL UNIQUE,
    date_of_birth DATE NOT NULL,
    kyc_status    ENUM('PENDING','VERIFIED','REJECTED') NOT NULL DEFAULT 'PENDING',
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE business_profile (
    business_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id   INT UNSIGNED NOT NULL UNIQUE,          -- 1:1 with a BUSINESS customer
    business_name VARCHAR(150) NOT NULL,
    rc_number     VARCHAR(20)  NOT NULL UNIQUE,          -- CAC registration number
    sector        VARCHAR(60)  NOT NULL,
    annual_revenue DECIMAL(15,2) NOT NULL DEFAULT 0 CHECK (annual_revenue >= 0),
    CONSTRAINT fk_bp_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
) ENGINE=InnoDB;

CREATE TABLE employer (
    employer_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(150) NOT NULL UNIQUE,
    industry    VARCHAR(60)
) ENGINE=InnoDB;

CREATE TABLE customer_employment (
    employment_id  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id    INT UNSIGNED NOT NULL,
    employer_id    INT UNSIGNED NOT NULL,
    monthly_salary DECIMAL(15,2) NOT NULL CHECK (monthly_salary > 0),
    start_date     DATE NOT NULL,
    end_date       DATE NULL,
    CONSTRAINT fk_emp_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    CONSTRAINT fk_emp_employer FOREIGN KEY (employer_id) REFERENCES employer(employer_id),
    CONSTRAINT chk_emp_dates CHECK (end_date IS NULL OR end_date >= start_date)
) ENGINE=InnoDB;

CREATE TABLE product (
    product_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_code  VARCHAR(20) NOT NULL UNIQUE,
    product_name  VARCHAR(100) NOT NULL,
    category      ENUM('PERSONAL_LOAN','SALARY_LOAN','SME_FINANCING','BNPL','INVESTMENT','GENERAL_BANKING') NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (interest_rate >= 0),  -- annual %
    min_amount    DECIMAL(15,2) NOT NULL DEFAULT 0 CHECK (min_amount >= 0),
    max_amount    DECIMAL(15,2) NOT NULL DEFAULT 0,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_prod_range CHECK (max_amount >= min_amount)
) ENGINE=InnoDB;

-- ---------- General banking & digital services ----------
CREATE TABLE account (
    account_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id    INT UNSIGNED NOT NULL,
    account_number CHAR(10) NOT NULL UNIQUE,
    account_type   ENUM('SAVINGS','CURRENT','WALLET') NOT NULL,
    balance        DECIMAL(15,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    status         ENUM('ACTIVE','DORMANT','FROZEN','CLOSED') NOT NULL DEFAULT 'ACTIVE',
    opened_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_acc_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
) ENGINE=InnoDB;

CREATE TABLE account_transaction (
    txn_id        BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id    INT UNSIGNED NOT NULL,
    txn_type      ENUM('DEPOSIT','WITHDRAWAL','TRANSFER_IN','TRANSFER_OUT','LOAN_DISBURSEMENT','LOAN_REPAYMENT','BNPL_PAYMENT','BILL_PAYMENT','FEE','INVESTMENT') NOT NULL,
    amount        DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    balance_after DECIMAL(15,2) NOT NULL,
    channel       ENUM('BRANCH','MOBILE_APP','WEB','USSD','ATM','SYSTEM') NOT NULL DEFAULT 'SYSTEM',
    reference     VARCHAR(40) NOT NULL UNIQUE,
    narration     VARCHAR(200),
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_txn_account FOREIGN KEY (account_id) REFERENCES account(account_id)
) ENGINE=InnoDB;

CREATE TABLE transfer (
    transfer_id     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    from_account_id INT UNSIGNED NOT NULL,
    to_account_id   INT UNSIGNED NOT NULL,
    amount          DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    status          ENUM('PENDING','COMPLETED','FAILED','REVERSED') NOT NULL DEFAULT 'PENDING',
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tr_from FOREIGN KEY (from_account_id) REFERENCES account(account_id),
    CONSTRAINT fk_tr_to   FOREIGN KEY (to_account_id)   REFERENCES account(account_id),
    CONSTRAINT chk_tr_diff CHECK (from_account_id <> to_account_id)
) ENGINE=InnoDB;

CREATE TABLE card (
    card_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id  INT UNSIGNED NOT NULL,
    last_four   CHAR(4) NOT NULL,                         -- never store full PAN
    card_type   ENUM('DEBIT','VIRTUAL') NOT NULL,
    expiry_date DATE NOT NULL,
    status      ENUM('ACTIVE','BLOCKED','EXPIRED') NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT fk_card_account FOREIGN KEY (account_id) REFERENCES account(account_id)
) ENGINE=InnoDB;

CREATE TABLE bill_payment (
    payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id INT UNSIGNED NOT NULL,
    biller     VARCHAR(80) NOT NULL,
    category   ENUM('AIRTIME','DATA','ELECTRICITY','CABLE_TV','WATER','OTHER') NOT NULL,
    amount     DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    status     ENUM('PENDING','SUCCESSFUL','FAILED') NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bill_account FOREIGN KEY (account_id) REFERENCES account(account_id)
) ENGINE=InnoDB;

-- ---------- Personal, salary and SME loans ----------
CREATE TABLE loan_application (
    application_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id      INT UNSIGNED NOT NULL,
    product_id       INT UNSIGNED NOT NULL,
    reviewed_by      INT UNSIGNED NULL,
    requested_amount DECIMAL(15,2) NOT NULL CHECK (requested_amount > 0),
    tenor_months     SMALLINT UNSIGNED NOT NULL CHECK (tenor_months BETWEEN 1 AND 60),
    purpose          VARCHAR(200),
    status           ENUM('SUBMITTED','UNDER_REVIEW','APPROVED','REJECTED','DISBURSED') NOT NULL DEFAULT 'SUBMITTED',
    submitted_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    decided_at       TIMESTAMP NULL,
    CONSTRAINT fk_la_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    CONSTRAINT fk_la_product  FOREIGN KEY (product_id)  REFERENCES product(product_id),
    CONSTRAINT fk_la_staff    FOREIGN KEY (reviewed_by) REFERENCES staff(staff_id)
) ENGINE=InnoDB;

CREATE TABLE loan (
    loan_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    application_id   INT UNSIGNED NOT NULL UNIQUE,        -- one loan per approved application
    account_id       INT UNSIGNED NOT NULL,               -- disbursement/repayment account
    principal        DECIMAL(15,2) NOT NULL CHECK (principal > 0),
    interest_rate    DECIMAL(5,2)  NOT NULL CHECK (interest_rate >= 0),
    tenor_months     SMALLINT UNSIGNED NOT NULL,
    outstanding_balance DECIMAL(15,2) NOT NULL CHECK (outstanding_balance >= 0),
    disbursed_at     DATE NOT NULL,
    maturity_date    DATE NOT NULL,
    status           ENUM('ACTIVE','PAID_OFF','OVERDUE','DEFAULTED','WRITTEN_OFF') NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT fk_loan_app     FOREIGN KEY (application_id) REFERENCES loan_application(application_id),
    CONSTRAINT fk_loan_account FOREIGN KEY (account_id)     REFERENCES account(account_id),
    CONSTRAINT chk_loan_dates  CHECK (maturity_date > disbursed_at)
) ENGINE=InnoDB;

CREATE TABLE repayment_schedule (
    schedule_id    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    loan_id        INT UNSIGNED NOT NULL,
    installment_no SMALLINT UNSIGNED NOT NULL,
    due_date       DATE NOT NULL,
    principal_due  DECIMAL(15,2) NOT NULL CHECK (principal_due >= 0),
    interest_due   DECIMAL(15,2) NOT NULL CHECK (interest_due >= 0),
    status         ENUM('PENDING','PAID','PARTIAL','OVERDUE') NOT NULL DEFAULT 'PENDING',
    UNIQUE KEY uq_loan_installment (loan_id, installment_no),
    CONSTRAINT fk_rs_loan FOREIGN KEY (loan_id) REFERENCES loan(loan_id)
) ENGINE=InnoDB;

CREATE TABLE loan_repayment (
    repayment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    schedule_id  BIGINT UNSIGNED NOT NULL,
    txn_id       BIGINT UNSIGNED NOT NULL UNIQUE,         -- the debit that paid it
    amount_paid  DECIMAL(15,2) NOT NULL CHECK (amount_paid > 0),
    paid_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_lr_schedule FOREIGN KEY (schedule_id) REFERENCES repayment_schedule(schedule_id),
    CONSTRAINT fk_lr_txn      FOREIGN KEY (txn_id)      REFERENCES account_transaction(txn_id)
) ENGINE=InnoDB;

-- ---------- BNPL (OxygenNow) ----------
CREATE TABLE bnpl_merchant (
    merchant_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(150) NOT NULL UNIQUE,
    category    VARCHAR(60) NOT NULL,
    status      ENUM('ACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE'
) ENGINE=InnoDB;

CREATE TABLE bnpl_order (
    bnpl_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id  INT UNSIGNED NOT NULL,
    merchant_id  INT UNSIGNED NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL CHECK (total_amount > 0),
    plan_months  TINYINT UNSIGNED NOT NULL CHECK (plan_months BETWEEN 1 AND 12),
    status       ENUM('ACTIVE','COMPLETED','DEFAULTED','CANCELLED') NOT NULL DEFAULT 'ACTIVE',
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bo_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    CONSTRAINT fk_bo_merchant FOREIGN KEY (merchant_id) REFERENCES bnpl_merchant(merchant_id)
) ENGINE=InnoDB;

CREATE TABLE bnpl_installment (
    installment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bnpl_id        INT UNSIGNED NOT NULL,
    installment_no TINYINT UNSIGNED NOT NULL,
    due_date       DATE NOT NULL,
    amount         DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    status         ENUM('PENDING','PAID','OVERDUE') NOT NULL DEFAULT 'PENDING',
    paid_at        TIMESTAMP NULL,
    UNIQUE KEY uq_bnpl_installment (bnpl_id, installment_no),
    CONSTRAINT fk_bi_order FOREIGN KEY (bnpl_id) REFERENCES bnpl_order(bnpl_id)
) ENGINE=InnoDB;

-- ---------- Investment & fund management ----------
CREATE TABLE investment_fund (
    fund_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fund_name  VARCHAR(100) NOT NULL UNIQUE,
    fund_type  ENUM('MONEY_MARKET','FIXED_INCOME','EQUITY','BALANCED') NOT NULL,
    risk_level ENUM('LOW','MEDIUM','HIGH') NOT NULL,
    unit_price DECIMAL(15,4) NOT NULL CHECK (unit_price > 0),
    managed_by INT UNSIGNED NOT NULL,
    CONSTRAINT fk_fund_manager FOREIGN KEY (managed_by) REFERENCES staff(staff_id)
) ENGINE=InnoDB;

CREATE TABLE investment_order (
    order_id    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    fund_id     INT UNSIGNED NOT NULL,
    order_type  ENUM('BUY','SELL') NOT NULL,
    units       DECIMAL(18,4) NOT NULL CHECK (units > 0),
    unit_price  DECIMAL(15,4) NOT NULL CHECK (unit_price > 0),
    status      ENUM('PENDING','EXECUTED','CANCELLED') NOT NULL DEFAULT 'PENDING',
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_io_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    CONSTRAINT fk_io_fund     FOREIGN KEY (fund_id)     REFERENCES investment_fund(fund_id)
) ENGINE=InnoDB;

CREATE TABLE investment_holding (
    customer_id INT UNSIGNED NOT NULL,
    fund_id     INT UNSIGNED NOT NULL,
    units_held  DECIMAL(18,4) NOT NULL CHECK (units_held >= 0),
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id, fund_id),                   -- composite key: one row per customer per fund
    CONSTRAINT fk_ih_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    CONSTRAINT fk_ih_fund     FOREIGN KEY (fund_id)     REFERENCES investment_fund(fund_id)
) ENGINE=InnoDB;
