-- =============================================================================
-- ScaleFlow — SQL Server Express
-- Migration V1: Initial schema
--
-- Run against your local SQL Server Express instance:
--   sqlcmd -S localhost\SQLEXPRESS -d ScaleFlow -i V1__initial_schema.sql
--
-- All tables include created_at / updated_at audit columns.
-- Tickets are append-only; voids create a new ticket referencing the original.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Location & equipment
-- ---------------------------------------------------------------------------

CREATE TABLE LOCATION (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    name        NVARCHAR(150)  NOT NULL,
    address     NVARCHAR(255)  NOT NULL,
    city        NVARCHAR(100)  NOT NULL,
    state       NVARCHAR(50)   NOT NULL,
    zip         NVARCHAR(20)   NOT NULL,
    timezone    NVARCHAR(60)   NOT NULL,
    phone       NVARCHAR(30)   NULL,
    active      BIT            NOT NULL DEFAULT 1,
    created_at  DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at  DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE SCALE_TERMINAL (
    id                INT IDENTITY(1,1) PRIMARY KEY,
    location_id       INT            NOT NULL REFERENCES LOCATION(id),
    name              NVARCHAR(100)  NOT NULL,
    terminal_id       NVARCHAR(50)   NOT NULL UNIQUE,
    make              NVARCHAR(100)  NULL,
    model             NVARCHAR(100)  NULL,
    serial_number     NVARCHAR(100)  NULL,
    -- 'rs232' or 'tcp'
    connection_type   NVARCHAR(10)   NOT NULL CHECK (connection_type IN ('rs232','tcp')),
    -- JSON: RS-232 => {"port":"COM3","baud":9600,"dataBits":8,"parity":"N","stopBits":1}
    --       TCP    => {"host":"192.168.1.50","port":10001}
    connection_config NVARCHAR(500)  NOT NULL,
    -- 'lbs', 'kg', 'tons'
    weight_unit       NVARCHAR(10)   NOT NULL CHECK (weight_unit IN ('lbs','kg','tons')),
    data_format       NVARCHAR(100)  NULL,
    active            BIT            NOT NULL DEFAULT 1,
    last_seen_at      DATETIME2      NULL,
    created_at        DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at        DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

-- ---------------------------------------------------------------------------
-- Reference data
-- ---------------------------------------------------------------------------

CREATE TABLE SUPPLIER (
    id               INT IDENTITY(1,1) PRIMARY KEY,
    name             NVARCHAR(150)  NOT NULL,
    contact_name     NVARCHAR(150)  NULL,
    phone            NVARCHAR(30)   NULL,
    email            NVARCHAR(200)  NULL,
    address          NVARCHAR(300)  NULL,
    commodity_types  NVARCHAR(500)  NULL,
    created_at       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE CUSTOMER (
    id            INT IDENTITY(1,1) PRIMARY KEY,
    name          NVARCHAR(150)  NOT NULL,
    contact_name  NVARCHAR(150)  NULL,
    phone         NVARCHAR(30)   NULL,
    email         NVARCHAR(200)  NULL,
    address       NVARCHAR(300)  NULL,
    created_at    DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at    DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE DRIVER (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    name            NVARCHAR(150)  NOT NULL,
    license_number  NVARCHAR(50)   NULL,
    phone           NVARCHAR(30)   NULL,
    email           NVARCHAR(200)  NULL,
    -- Hashed PIN used by the future mobile app
    app_pin         NVARCHAR(100)  NULL,
    created_at      DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at      DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE TRUCK (
    id                  INT IDENTITY(1,1) PRIMARY KEY,
    license_plate       NVARCHAR(30)   NOT NULL UNIQUE,
    description         NVARCHAR(200)  NULL,
    tare_weight         DECIMAL(10,3)  NULL,
    tare_unit           NVARCHAR(10)   NULL CHECK (tare_unit IN ('lbs','kg','tons')),
    tare_certified_date DATE           NULL,
    created_at          DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at          DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE PRODUCT (
    id               INT IDENTITY(1,1) PRIMARY KEY,
    name             NVARCHAR(150)  NOT NULL,
    category         NVARCHAR(100)  NOT NULL,
    unit             NVARCHAR(30)   NOT NULL,
    current_stock    DECIMAL(14,3)  NOT NULL DEFAULT 0,
    min_stock_alert  DECIMAL(14,3)  NULL,
    created_at       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

-- ---------------------------------------------------------------------------
-- PO / SO references  (synced from ERP via MuleSoft, not managed here)
-- ---------------------------------------------------------------------------

CREATE TABLE PURCHASE_ORDER_REF (
    id                INT IDENTITY(1,1) PRIMARY KEY,
    supplier_id       INT             NOT NULL REFERENCES SUPPLIER(id),
    product_id        INT             NOT NULL REFERENCES PRODUCT(id),
    po_number         NVARCHAR(100)   NOT NULL,
    quantity_ordered  DECIMAL(14,3)   NOT NULL,
    quantity_received DECIMAL(14,3)   NOT NULL DEFAULT 0,
    unit              NVARCHAR(30)    NOT NULL,
    external_system   NVARCHAR(100)   NOT NULL,
    external_ref_id   NVARCHAR(100)   NULL,
    -- 'open', 'partial', 'received', 'cancelled'
    status            NVARCHAR(20)    NOT NULL DEFAULT 'open'
                          CHECK (status IN ('open','partial','received','cancelled')),
    notes             NVARCHAR(MAX)   NULL,
    created_at        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE SALES_ORDER_REF (
    id                INT IDENTITY(1,1) PRIMARY KEY,
    customer_id       INT             NOT NULL REFERENCES CUSTOMER(id),
    product_id        INT             NOT NULL REFERENCES PRODUCT(id),
    so_number         NVARCHAR(100)   NOT NULL,
    quantity_ordered  DECIMAL(14,3)   NOT NULL,
    quantity_shipped  DECIMAL(14,3)   NOT NULL DEFAULT 0,
    unit              NVARCHAR(30)    NOT NULL,
    external_system   NVARCHAR(100)   NOT NULL,
    external_ref_id   NVARCHAR(100)   NULL,
    -- 'open', 'partial', 'shipped', 'cancelled'
    status            NVARCHAR(20)    NOT NULL DEFAULT 'open'
                          CHECK (status IN ('open','partial','shipped','cancelled')),
    notes             NVARCHAR(MAX)   NULL,
    created_at        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);

-- ---------------------------------------------------------------------------
-- Transactions
-- ---------------------------------------------------------------------------

CREATE TABLE INBOUND_TICKET (
    id               INT IDENTITY(1,1) PRIMARY KEY,
    ticket_number    NVARCHAR(50)    NOT NULL UNIQUE,
    location_id      INT             NOT NULL REFERENCES LOCATION(id),
    terminal_id      INT             NOT NULL REFERENCES SCALE_TERMINAL(id),
    supplier_id      INT             NOT NULL REFERENCES SUPPLIER(id),
    truck_id         INT             NOT NULL REFERENCES TRUCK(id),
    driver_id        INT             NULL     REFERENCES DRIVER(id),
    product_id       INT             NOT NULL REFERENCES PRODUCT(id),
    po_ref_id        INT             NULL     REFERENCES PURCHASE_ORDER_REF(id),
    gross_weight     DECIMAL(10,3)   NULL,
    tare_weight      DECIMAL(10,3)   NULL,
    net_weight       DECIMAL(10,3)   NULL,
    weight_unit      NVARCHAR(10)    NOT NULL CHECK (weight_unit IN ('lbs','kg','tons')),
    gross_time       DATETIME2       NULL,
    tare_time        DATETIME2       NULL,
    -- Raw strings from serial/TCP port for audit
    raw_serial_gross NVARCHAR(200)   NULL,
    raw_serial_tare  NVARCHAR(200)   NULL,
    -- 'open', 'complete', 'voided'
    status           NVARCHAR(20)    NOT NULL DEFAULT 'open'
                         CHECK (status IN ('open','complete','voided')),
    notes            NVARCHAR(MAX)   NULL,
    -- 0 = pending outbox sync, 1 = successfully synced to cloud
    synced           BIT             NOT NULL DEFAULT 0,
    created_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE OUTBOUND_TICKET (
    id               INT IDENTITY(1,1) PRIMARY KEY,
    ticket_number    NVARCHAR(50)    NOT NULL UNIQUE,
    location_id      INT             NOT NULL REFERENCES LOCATION(id),
    terminal_id      INT             NOT NULL REFERENCES SCALE_TERMINAL(id),
    customer_id      INT             NOT NULL REFERENCES CUSTOMER(id),
    truck_id         INT             NOT NULL REFERENCES TRUCK(id),
    driver_id        INT             NULL     REFERENCES DRIVER(id),
    product_id       INT             NOT NULL REFERENCES PRODUCT(id),
    so_ref_id        INT             NULL     REFERENCES SALES_ORDER_REF(id),
    gross_weight     DECIMAL(10,3)   NULL,
    tare_weight      DECIMAL(10,3)   NULL,
    net_weight       DECIMAL(10,3)   NULL,
    weight_unit      NVARCHAR(10)    NOT NULL CHECK (weight_unit IN ('lbs','kg','tons')),
    gross_time       DATETIME2       NULL,
    tare_time        DATETIME2       NULL,
    raw_serial_gross NVARCHAR(200)   NULL,
    raw_serial_tare  NVARCHAR(200)   NULL,
    status           NVARCHAR(20)    NOT NULL DEFAULT 'open'
                         CHECK (status IN ('open','complete','voided')),
    notes            NVARCHAR(MAX)   NULL,
    synced           BIT             NOT NULL DEFAULT 0,
    created_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);

-- ---------------------------------------------------------------------------
-- Sync & audit
-- ---------------------------------------------------------------------------

CREATE TABLE OUTBOX (
    id               INT IDENTITY(1,1) PRIMARY KEY,
    -- 'INBOUND' or 'OUTBOUND'
    ticket_type      NVARCHAR(10)    NOT NULL CHECK (ticket_type IN ('INBOUND','OUTBOUND')),
    ticket_id        INT             NOT NULL,
    payload_json     NVARCHAR(MAX)   NOT NULL,
    -- 'pending', 'sent', 'failed'
    status           NVARCHAR(10)    NOT NULL DEFAULT 'pending'
                         CHECK (status IN ('pending','sent','failed')),
    attempt_count    INT             NOT NULL DEFAULT 0,
    last_attempt_at  DATETIME2       NULL,
    error_message    NVARCHAR(MAX)   NULL,
    created_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE INVENTORY_LOG (
    id                  INT IDENTITY(1,1) PRIMARY KEY,
    product_id          INT             NOT NULL REFERENCES PRODUCT(id),
    location_id         INT             NOT NULL REFERENCES LOCATION(id),
    inbound_ticket_id   INT             NULL     REFERENCES INBOUND_TICKET(id),
    outbound_ticket_id  INT             NULL     REFERENCES OUTBOUND_TICKET(id),
    quantity_change     DECIMAL(14,3)   NOT NULL,
    balance_after       DECIMAL(14,3)   NOT NULL,
    reason              NVARCHAR(200)   NOT NULL,
    created_at          DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE WEBHOOK_CONFIG (
    id                INT IDENTITY(1,1) PRIMARY KEY,
    name              NVARCHAR(100)   NOT NULL,
    url               NVARCHAR(500)   NOT NULL,
    -- 'get', 'post', 'put', 'patch'
    method            NVARCHAR(10)    NOT NULL CHECK (method IN ('get','post','put','patch')),
    headers_json      NVARCHAR(MAX)   NULL,
    trigger_event     NVARCHAR(100)   NOT NULL,
    -- 'inbound', 'outbound', or future: 'both' (handled in app logic)
    ticket_direction  NVARCHAR(10)    NOT NULL CHECK (ticket_direction IN ('inbound','outbound')),
    active            BIT             NOT NULL DEFAULT 1,
    created_at        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE WEBHOOK_LOG (
    id                  INT IDENTITY(1,1) PRIMARY KEY,
    inbound_ticket_id   INT             NULL REFERENCES INBOUND_TICKET(id),
    outbound_ticket_id  INT             NULL REFERENCES OUTBOUND_TICKET(id),
    config_id           INT             NOT NULL REFERENCES WEBHOOK_CONFIG(id),
    http_status         INT             NULL,
    response_body       NVARCHAR(MAX)   NULL,
    sent_at             DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    success             BIT             NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- Indexes — covering the most common query patterns
-- ---------------------------------------------------------------------------

-- Outbox drain: pull oldest pending rows first
CREATE INDEX IX_OUTBOX_status_created
    ON OUTBOX (status, created_at)
    WHERE status IN ('pending','failed');

-- Ticket lookups by status and date
CREATE INDEX IX_INBOUND_status_created
    ON INBOUND_TICKET (status, created_at DESC);

CREATE INDEX IX_OUTBOUND_status_created
    ON OUTBOUND_TICKET (status, created_at DESC);

-- Unsynced tickets (offline → online drain)
CREATE INDEX IX_INBOUND_synced
    ON INBOUND_TICKET (synced) WHERE synced = 0;

CREATE INDEX IX_OUTBOUND_synced
    ON OUTBOUND_TICKET (synced) WHERE synced = 0;

-- Inventory log per product
CREATE INDEX IX_INVENTORY_LOG_product_created
    ON INVENTORY_LOG (product_id, created_at DESC);

-- Webhook log lookups
CREATE INDEX IX_WEBHOOK_LOG_config_sent
    ON WEBHOOK_LOG (config_id, sent_at DESC);
