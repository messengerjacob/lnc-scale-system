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
-- Reference data (global — synced to all locations)
-- ---------------------------------------------------------------------------

CREATE TABLE SUPPLIER (
    id               INT IDENTITY(1,1) PRIMARY KEY,
    name             NVARCHAR(150)  NOT NULL,
    contact_name     NVARCHAR(150)  NULL,
    phone            NVARCHAR(30)   NULL,
    email            NVARCHAR(200)  NULL,
    address          NVARCHAR(300)  NULL,
    commodity_types  NVARCHAR(500)  NULL,
    active           BIT            NOT NULL DEFAULT 1,
    created_at       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE FREIGHT_SUPPLIER (
    id               INT IDENTITY(1,1) PRIMARY KEY,
    name             NVARCHAR(150)  NOT NULL,
    contact_name     NVARCHAR(100)  NULL,
    phone            NVARCHAR(30)   NULL,
    email            NVARCHAR(150)  NULL,
    address          NVARCHAR(255)  NULL,
    city             NVARCHAR(100)  NULL,
    state            NVARCHAR(50)   NULL,
    zip              NVARCHAR(20)   NULL,
    active           BIT            NOT NULL DEFAULT 1,
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
    active        BIT            NOT NULL DEFAULT 1,
    created_at    DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at    DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE DRIVER (
    id                  INT IDENTITY(1,1) PRIMARY KEY,
    name                NVARCHAR(150)  NOT NULL,
    license_number      NVARCHAR(50)   NULL,
    phone               NVARCHAR(30)   NULL,
    email               NVARCHAR(200)  NULL,
    -- Hashed PIN used by the future mobile app
    app_pin             NVARCHAR(100)  NULL,
    supplier_id         INT            NULL REFERENCES SUPPLIER(id),
    freight_supplier_id INT            NULL REFERENCES FREIGHT_SUPPLIER(id),
    active              BIT            NOT NULL DEFAULT 1,
    created_at          DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at          DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE TRUCK (
    id                  INT IDENTITY(1,1) PRIMARY KEY,
    license_plate       NVARCHAR(30)   NOT NULL UNIQUE,
    description         NVARCHAR(200)  NULL,
    tare_weight         DECIMAL(10,3)  NULL,
    tare_unit           NVARCHAR(10)   NULL CHECK (tare_unit IN ('lbs','kg','tons')),
    tare_certified_date DATE           NULL,
    supplier_id         INT            NULL REFERENCES SUPPLIER(id),
    freight_supplier_id INT            NULL REFERENCES FREIGHT_SUPPLIER(id),
    active              BIT            NOT NULL DEFAULT 1,
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
    active           BIT            NOT NULL DEFAULT 1,
    created_at       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

-- ---------------------------------------------------------------------------
-- PO / SO references  (synced from ERP via MuleSoft, location-specific)
-- ---------------------------------------------------------------------------

CREATE TABLE PURCHASE_ORDER_REF (
    id                INT IDENTITY(1,1) PRIMARY KEY,
    location_id       INT             NOT NULL REFERENCES LOCATION(id),
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
    location_id       INT             NOT NULL REFERENCES LOCATION(id),
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
-- Users & Security
-- ---------------------------------------------------------------------------

CREATE TABLE OPERATOR (
    id               INT IDENTITY(1,1) PRIMARY KEY,
    username         NVARCHAR(100)   NOT NULL UNIQUE,
    password_hash    NVARCHAR(255)   NOT NULL,
    location_id      INT             NULL REFERENCES LOCATION(id),
    -- 'location' = scale terminal operator (location_id required)
    -- 'admin'    = full system access (location_id NULL)
    -- 'merchandiser' = cloud read-only across all locations (location_id NULL)
    role             NVARCHAR(20)    NOT NULL CHECK (role IN ('location','admin','merchandiser')),
    active           BIT             NOT NULL DEFAULT 1,
    created_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
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
    is_split_load    BIT             NOT NULL DEFAULT 0,
    split_with       NVARCHAR(100)   NULL,
    split_from_bin   TINYINT         NULL CHECK (split_from_bin BETWEEN 1 AND 9),
    split_to_bin     TINYINT         NULL CHECK (split_to_bin BETWEEN 1 AND 9),
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
    is_split_load    BIT             NOT NULL DEFAULT 0,
    split_with       NVARCHAR(100)   NULL,
    split_from_bin   TINYINT         NULL CHECK (split_from_bin BETWEEN 1 AND 9),
    split_to_bin     TINYINT         NULL CHECK (split_to_bin BETWEEN 1 AND 9),
    notes            NVARCHAR(MAX)   NULL,
    synced           BIT             NOT NULL DEFAULT 0,
    created_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);

-- ---------------------------------------------------------------------------
-- Scale queue
-- ---------------------------------------------------------------------------

CREATE TABLE QUEUE_ENTRY (
    id                   INT IDENTITY(1,1) PRIMARY KEY,
    location_id          INT             NOT NULL REFERENCES LOCATION(id),
    load_number          NVARCHAR(100)   NOT NULL,
    -- 'inbound' or 'outbound'
    direction            NVARCHAR(10)    NOT NULL CHECK (direction IN ('inbound','outbound')),
    -- 'waitingInLine', 'weighing', 'loadingUnloading', 'secondWeighing', 'complete'
    status               NVARCHAR(25)    NOT NULL DEFAULT 'waitingInLine'
                             CHECK (status IN ('waitingInLine','weighing','loadingUnloading','secondWeighing','complete')),
    -- Ticket created on first weigh-in. Two nullable FKs because tickets live in
    -- separate tables per direction; only the matching one will ever be populated.
    inbound_ticket_id    INT             NULL REFERENCES INBOUND_TICKET(id),
    outbound_ticket_id   INT             NULL REFERENCES OUTBOUND_TICKET(id),
    -- Denormalized for quick display before and after ticket creation
    ticket_number        NVARCHAR(50)    NULL,
    -- Resolved from the load number at check-in time
    supplier_id          INT             NULL REFERENCES SUPPLIER(id),
    customer_id          INT             NULL REFERENCES CUSTOMER(id),
    product_id           INT             NULL REFERENCES PRODUCT(id),
    po_ref_id            INT             NULL REFERENCES PURCHASE_ORDER_REF(id),
    so_ref_id            INT             NULL REFERENCES SALES_ORDER_REF(id),
    -- Filled in when the truck drives on the scale
    truck_id             INT             NULL REFERENCES TRUCK(id),
    driver_id            INT             NULL REFERENCES DRIVER(id),
    terminal_id          INT             NULL REFERENCES SCALE_TERMINAL(id),
    -- 'manual' = operator added via terminal UI
    -- 'api'    = truck/dispatch checked in via API
    source               NVARCHAR(10)    NOT NULL DEFAULT 'manual'
                             CHECK (source IN ('manual','api')),
    entered_at           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    first_weigh_at       DATETIME2       NULL,
    second_weigh_at      DATETIME2       NULL,
    created_at           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);

-- ---------------------------------------------------------------------------
-- Sync & audit
-- ---------------------------------------------------------------------------

CREATE TABLE OUTBOX (
    id               INT IDENTITY(1,1) PRIMARY KEY,
    location_id      INT             NOT NULL REFERENCES LOCATION(id),
    -- 'INBOUND', 'OUTBOUND', or 'QUEUE'
    entity_type      NVARCHAR(10)    NOT NULL CHECK (entity_type IN ('INBOUND','OUTBOUND','QUEUE')),
    entity_id        INT             NOT NULL,
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
    -- 'inbound', 'outbound', 'queue', or 'both'
    ticket_direction  NVARCHAR(10)    NOT NULL CHECK (ticket_direction IN ('inbound','outbound','queue','both')),
    active            BIT             NOT NULL DEFAULT 1,
    created_at        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE WEBHOOK_LOG (
    id                  INT IDENTITY(1,1) PRIMARY KEY,
    inbound_ticket_id   INT             NULL REFERENCES INBOUND_TICKET(id),
    outbound_ticket_id  INT             NULL REFERENCES OUTBOUND_TICKET(id),
    queue_entry_id      INT             NULL REFERENCES QUEUE_ENTRY(id),
    config_id           INT             NOT NULL REFERENCES WEBHOOK_CONFIG(id),
    http_status         INT             NULL,
    response_body       NVARCHAR(MAX)   NULL,
    sent_at             DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    success             BIT             NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- Sync state — tracks last successful pull per location per entity type
-- (used by the sync service for incremental pulls from cloud)
-- ---------------------------------------------------------------------------

CREATE TABLE SYNC_STATE (
    id               INT IDENTITY(1,1) PRIMARY KEY,
    location_id      INT             NOT NULL REFERENCES LOCATION(id),
    entity_type      NVARCHAR(50)    NOT NULL,
    last_sync_at     DATETIME2       NOT NULL DEFAULT '2000-01-01',
    CONSTRAINT UQ_SYNC_STATE UNIQUE (location_id, entity_type)
);

-- ---------------------------------------------------------------------------
-- Indexes — covering the most common query patterns
-- ---------------------------------------------------------------------------

-- Outbox drain: pull oldest pending rows first per location
CREATE INDEX IX_OUTBOX_location_status_created
    ON OUTBOX (location_id, status, created_at)
    WHERE status IN ('pending','failed');

-- Ticket lookups by location, status, and date
CREATE INDEX IX_INBOUND_location_status_created
    ON INBOUND_TICKET (location_id, status, created_at DESC);

CREATE INDEX IX_OUTBOUND_location_status_created
    ON OUTBOUND_TICKET (location_id, status, created_at DESC);

-- Unsynced tickets (offline → online drain)
CREATE INDEX IX_INBOUND_synced
    ON INBOUND_TICKET (synced) WHERE synced = 0;

CREATE INDEX IX_OUTBOUND_synced
    ON OUTBOUND_TICKET (synced) WHERE synced = 0;

-- PO/SO lookups by location and status (most common query from location app)
CREATE INDEX IX_PO_location_status
    ON PURCHASE_ORDER_REF (location_id, status, updated_at DESC);

CREATE INDEX IX_SO_location_status
    ON SALES_ORDER_REF (location_id, status, updated_at DESC);

-- Incremental sync pull — rows updated after last_sync_at
CREATE INDEX IX_PO_updated
    ON PURCHASE_ORDER_REF (updated_at DESC);

CREATE INDEX IX_SO_updated
    ON SALES_ORDER_REF (updated_at DESC);

-- Inventory log per product
CREATE INDEX IX_INVENTORY_LOG_product_created
    ON INVENTORY_LOG (product_id, created_at DESC);

-- Webhook log lookups
CREATE INDEX IX_WEBHOOK_LOG_config_sent
    ON WEBHOOK_LOG (config_id, sent_at DESC);

-- Active queue for a location (the main polling query from the terminal app)
CREATE INDEX IX_QUEUE_ENTRY_location_status
    ON QUEUE_ENTRY (location_id, status, entered_at ASC)
    WHERE status <> 'complete';

-- Load number lookup — used by API check-in to detect duplicates
CREATE INDEX IX_QUEUE_ENTRY_load_number
    ON QUEUE_ENTRY (load_number, location_id)
    WHERE status <> 'complete';

-- Sync state lookup
CREATE INDEX IX_SYNC_STATE_location
    ON SYNC_STATE (location_id, entity_type);
