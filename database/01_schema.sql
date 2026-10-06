/* =====================================================================
   ShopSphere - 01_schema.sql
   Creates ShopSphereDB and every table used by the six modules.
   Idempotent: safe to run any number of times (never drops data).
   Run with: sqlcmd -S localhost\SQLEXPRESS -U sa -P <pwd> -C -I -b -i 01_schema.sql
   ===================================================================== */
SET NOCOUNT ON;
GO
IF DB_ID(N'ShopSphereDB') IS NULL
    CREATE DATABASE ShopSphereDB;
GO
USE ShopSphereDB;
GO

/* ---------- Auth / users ---------- */
IF OBJECT_ID(N'dbo.Roles', N'U') IS NULL
CREATE TABLE dbo.Roles (
    id    BIGINT IDENTITY(1,1) CONSTRAINT PK_Roles PRIMARY KEY,
    name  NVARCHAR(30) NOT NULL CONSTRAINT UQ_Roles_name UNIQUE
);
GO
IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
CREATE TABLE dbo.Users (
    id             BIGINT IDENTITY(1,1) CONSTRAINT PK_Users PRIMARY KEY,
    email          NVARCHAR(150) NOT NULL CONSTRAINT UQ_Users_email UNIQUE,
    password_hash  NVARCHAR(100) NOT NULL,
    first_name     NVARCHAR(60)  NOT NULL,
    last_name      NVARCHAR(60)  NOT NULL,
    phone          NVARCHAR(20)  NULL,
    role_id        BIGINT NOT NULL CONSTRAINT FK_Users_Roles REFERENCES dbo.Roles(id),
    active         BIT NOT NULL CONSTRAINT DF_Users_active DEFAULT 1,
    created_at     DATETIME2(0) NOT NULL CONSTRAINT DF_Users_created DEFAULT GETDATE()
);
GO
IF OBJECT_ID(N'dbo.Addresses', N'U') IS NULL
CREATE TABLE dbo.Addresses (
    id           BIGINT IDENTITY(1,1) CONSTRAINT PK_Addresses PRIMARY KEY,
    user_id      BIGINT NOT NULL CONSTRAINT FK_Addresses_Users REFERENCES dbo.Users(id) ON DELETE CASCADE,
    label        NVARCHAR(40)  NOT NULL,
    address      NVARCHAR(200) NOT NULL,
    apartment    NVARCHAR(100) NULL,
    city         NVARCHAR(80)  NOT NULL,
    postal_code  NVARCHAR(20)  NOT NULL,
    country      NVARCHAR(60)  NOT NULL CONSTRAINT DF_Addresses_country DEFAULT N'Sri Lanka',
    phone        NVARCHAR(20)  NULL,
    is_default   BIT NOT NULL CONSTRAINT DF_Addresses_default DEFAULT 0
);
GO

/* ---------- FR-01 Product & Catalog ---------- */
IF OBJECT_ID(N'dbo.Categories', N'U') IS NULL
CREATE TABLE dbo.Categories (
    id           BIGINT IDENTITY(1,1) CONSTRAINT PK_Categories PRIMARY KEY,
    name         NVARCHAR(80)  NOT NULL CONSTRAINT UQ_Categories_name UNIQUE,
    description  NVARCHAR(300) NULL
);
GO
IF OBJECT_ID(N'dbo.Brands', N'U') IS NULL
CREATE TABLE dbo.Brands (
    id           BIGINT IDENTITY(1,1) CONSTRAINT PK_Brands PRIMARY KEY,
    name         NVARCHAR(80)  NOT NULL CONSTRAINT UQ_Brands_name UNIQUE,
    description  NVARCHAR(300) NULL
);
GO
IF OBJECT_ID(N'dbo.Products', N'U') IS NULL
CREATE TABLE dbo.Products (
    id           BIGINT IDENTITY(1,1) CONSTRAINT PK_Products PRIMARY KEY,
    name         NVARCHAR(150) NOT NULL,
    description  NVARCHAR(1500) NULL,
    price        DECIMAL(12,2) NOT NULL CONSTRAINT CK_Products_price CHECK (price > 0),
    sku          NVARCHAR(40)  NOT NULL CONSTRAINT UQ_Products_sku UNIQUE,
    category_id  BIGINT NOT NULL CONSTRAINT FK_Products_Categories REFERENCES dbo.Categories(id),
    brand_id     BIGINT NOT NULL CONSTRAINT FK_Products_Brands REFERENCES dbo.Brands(id),
    status       NVARCHAR(20) NOT NULL CONSTRAINT DF_Products_status DEFAULT N'ACTIVE'
                 CONSTRAINT CK_Products_status CHECK (status IN (N'ACTIVE', N'INACTIVE')),
    deleted      BIT NOT NULL CONSTRAINT DF_Products_deleted DEFAULT 0,   -- soft delete
    created_at   DATETIME2(0) NOT NULL CONSTRAINT DF_Products_created DEFAULT GETDATE(),
    updated_at   DATETIME2(0) NOT NULL CONSTRAINT DF_Products_updated DEFAULT GETDATE()
);
GO
IF OBJECT_ID(N'dbo.ProductImages', N'U') IS NULL
CREATE TABLE dbo.ProductImages (
    id            BIGINT IDENTITY(1,1) CONSTRAINT PK_ProductImages PRIMARY KEY,
    product_id    BIGINT NOT NULL CONSTRAINT FK_ProductImages_Products REFERENCES dbo.Products(id) ON DELETE CASCADE,
    image_path    NVARCHAR(260) NOT NULL,
    uploaded_date DATETIME2(0) NOT NULL CONSTRAINT DF_ProductImages_date DEFAULT GETDATE()
);
GO

/* ---------- FR-04 Inventory & Stock ---------- */
IF OBJECT_ID(N'dbo.Inventory', N'U') IS NULL
CREATE TABLE dbo.Inventory (
    id             BIGINT IDENTITY(1,1) CONSTRAINT PK_Inventory PRIMARY KEY,
    product_id     BIGINT NOT NULL CONSTRAINT UQ_Inventory_product UNIQUE
                   CONSTRAINT FK_Inventory_Products REFERENCES dbo.Products(id) ON DELETE CASCADE,
    quantity       INT NOT NULL CONSTRAINT CK_Inventory_qty CHECK (quantity >= 0),  -- stock can never go negative
    reorder_level  INT NOT NULL CONSTRAINT DF_Inventory_reorder DEFAULT 10 CONSTRAINT CK_Inventory_reorder CHECK (reorder_level >= 0),
    last_updated   DATETIME2(0) NOT NULL CONSTRAINT DF_Inventory_updated DEFAULT GETDATE()
);
GO
IF OBJECT_ID(N'dbo.StockMovements', N'U') IS NULL
CREATE TABLE dbo.StockMovements (
    id             BIGINT IDENTITY(1,1) CONSTRAINT PK_StockMovements PRIMARY KEY,
    product_id     BIGINT NOT NULL CONSTRAINT FK_StockMovements_Products REFERENCES dbo.Products(id) ON DELETE CASCADE,
    movement_type  NVARCHAR(20) NOT NULL CONSTRAINT CK_StockMovements_type CHECK (movement_type IN (N'IN', N'OUT', N'ADJUSTMENT')),
    quantity       INT NOT NULL,                 -- signed change (negative = stock removed)
    quantity_after INT NOT NULL,
    reason         NVARCHAR(200) NOT NULL,
    created_by     BIGINT NULL CONSTRAINT FK_StockMovements_Users REFERENCES dbo.Users(id),
    created_date   DATETIME2(0) NOT NULL CONSTRAINT DF_StockMovements_date DEFAULT GETDATE()
);
GO

/* ---------- FR-05 Promotions ---------- */
IF OBJECT_ID(N'dbo.Promotions', N'U') IS NULL
CREATE TABLE dbo.Promotions (
    id             BIGINT IDENTITY(1,1) CONSTRAINT PK_Promotions PRIMARY KEY,
    coupon_code    NVARCHAR(20) NOT NULL CONSTRAINT UQ_Promotions_code UNIQUE,
    discount_type  NVARCHAR(12) NOT NULL CONSTRAINT CK_Promotions_type CHECK (discount_type IN (N'PERCENTAGE', N'FIXED')),
    discount_value DECIMAL(12,2) NOT NULL CONSTRAINT CK_Promotions_value CHECK (discount_value > 0),
    start_date     DATE NOT NULL,
    end_date       DATE NOT NULL,
    is_active      BIT NOT NULL CONSTRAINT DF_Promotions_active DEFAULT 1,
    usage_limit    INT NULL CONSTRAINT CK_Promotions_limit CHECK (usage_limit IS NULL OR usage_limit > 0),
    usage_count    INT NOT NULL CONSTRAINT DF_Promotions_count DEFAULT 0,
    deleted        BIT NOT NULL CONSTRAINT DF_Promotions_deleted DEFAULT 0,  -- soft delete
    created_date   DATETIME2(0) NOT NULL CONSTRAINT DF_Promotions_created DEFAULT GETDATE(),
    CONSTRAINT CK_Promotions_dates CHECK (start_date <= end_date),
    CONSTRAINT CK_Promotions_pct CHECK (discount_type <> N'PERCENTAGE' OR discount_value <= 100)
);
GO

/* ---------- FR-02 Cart & Checkout ---------- */
IF OBJECT_ID(N'dbo.Carts', N'U') IS NULL
CREATE TABLE dbo.Carts (
    id            BIGINT IDENTITY(1,1) CONSTRAINT PK_Carts PRIMARY KEY,
    user_id       BIGINT NOT NULL CONSTRAINT UQ_Carts_user UNIQUE
                  CONSTRAINT FK_Carts_Users REFERENCES dbo.Users(id) ON DELETE CASCADE,
    created_date  DATETIME2(0) NOT NULL CONSTRAINT DF_Carts_created DEFAULT GETDATE(),
    updated_date  DATETIME2(0) NOT NULL CONSTRAINT DF_Carts_updated DEFAULT GETDATE()
);
GO
IF OBJECT_ID(N'dbo.CartItems', N'U') IS NULL
CREATE TABLE dbo.CartItems (
    id          BIGINT IDENTITY(1,1) CONSTRAINT PK_CartItems PRIMARY KEY,
    cart_id     BIGINT NOT NULL CONSTRAINT FK_CartItems_Carts REFERENCES dbo.Carts(id) ON DELETE CASCADE,
    product_id  BIGINT NOT NULL CONSTRAINT FK_CartItems_Products REFERENCES dbo.Products(id),
    quantity    INT NOT NULL CONSTRAINT CK_CartItems_qty CHECK (quantity >= 1),
    added_date  DATETIME2(0) NOT NULL CONSTRAINT DF_CartItems_added DEFAULT GETDATE(),
    CONSTRAINT UQ_CartItems_cart_product UNIQUE (cart_id, product_id)
);
GO

/* ---------- FR-03 Orders & Delivery ---------- */
IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
CREATE TABLE dbo.Orders (
    id               BIGINT IDENTITY(1,1) CONSTRAINT PK_Orders PRIMARY KEY,
    order_number     NVARCHAR(30) NOT NULL CONSTRAINT UQ_Orders_number UNIQUE,
    user_id          BIGINT NOT NULL CONSTRAINT FK_Orders_Users REFERENCES dbo.Users(id),
    total_amount     DECIMAL(12,2) NOT NULL,   -- items subtotal before discount
    discount_applied DECIMAL(12,2) NOT NULL CONSTRAINT DF_Orders_discount DEFAULT 0,
    final_amount     DECIMAL(12,2) NOT NULL,   -- amount charged
    promotion_id     BIGINT NULL CONSTRAINT FK_Orders_Promotions REFERENCES dbo.Promotions(id),
    coupon_code      NVARCHAR(20) NULL,
    status           NVARCHAR(30) NOT NULL CONSTRAINT DF_Orders_status DEFAULT N'PENDING'
                     CONSTRAINT CK_Orders_status CHECK (status IN (N'PENDING', N'CONFIRMED', N'PROCESSING',
                         N'READY_FOR_DISPATCH', N'DISPATCHED', N'OUT_FOR_DELIVERY', N'DELIVERED', N'CANCELLED')),
    email            NVARCHAR(150) NOT NULL,
    first_name       NVARCHAR(60)  NOT NULL,
    last_name        NVARCHAR(60)  NOT NULL,
    address          NVARCHAR(200) NOT NULL,
    apartment        NVARCHAR(100) NULL,
    city             NVARCHAR(80)  NOT NULL,
    postal_code      NVARCHAR(20)  NOT NULL,
    country          NVARCHAR(60)  NOT NULL,
    phone            NVARCHAR(20)  NOT NULL,
    secondary_phone  NVARCHAR(20)  NULL,
    created_date     DATETIME2(0) NOT NULL CONSTRAINT DF_Orders_created DEFAULT GETDATE(),
    updated_date     DATETIME2(0) NOT NULL CONSTRAINT DF_Orders_updated DEFAULT GETDATE(),
    CONSTRAINT CK_Orders_amounts CHECK (total_amount >= 0 AND discount_applied >= 0 AND final_amount >= 0)
);
GO
IF OBJECT_ID(N'dbo.OrderItems', N'U') IS NULL
CREATE TABLE dbo.OrderItems (
    id             BIGINT IDENTITY(1,1) CONSTRAINT PK_OrderItems PRIMARY KEY,
    order_id       BIGINT NOT NULL CONSTRAINT FK_OrderItems_Orders REFERENCES dbo.Orders(id) ON DELETE CASCADE,
    product_id     BIGINT NOT NULL CONSTRAINT FK_OrderItems_Products REFERENCES dbo.Products(id),
    product_name   NVARCHAR(150) NOT NULL,
    quantity       INT NOT NULL CONSTRAINT CK_OrderItems_qty CHECK (quantity >= 1),
    price_at_order DECIMAL(12,2) NOT NULL
);
GO
IF OBJECT_ID(N'dbo.Payments', N'U') IS NULL
CREATE TABLE dbo.Payments (
    id              BIGINT IDENTITY(1,1) CONSTRAINT PK_Payments PRIMARY KEY,
    order_id        BIGINT NOT NULL CONSTRAINT FK_Payments_Orders REFERENCES dbo.Orders(id) ON DELETE CASCADE,
    amount          DECIMAL(12,2) NOT NULL,
    payment_method  NVARCHAR(30) NOT NULL,          -- TEST_CARD (sandbox only)
    card_brand      NVARCHAR(20) NULL,
    card_last4      NVARCHAR(4) NULL,                 -- never store full card numbers / CVV
    transaction_id  NVARCHAR(60) NOT NULL,
    status          NVARCHAR(20) NOT NULL CONSTRAINT CK_Payments_status CHECK (status IN (N'SUCCESS', N'FAILED', N'REFUNDED')),
    payment_time    DATETIME2(0) NOT NULL CONSTRAINT DF_Payments_time DEFAULT GETDATE()
);
GO
IF OBJECT_ID(N'dbo.Shipments', N'U') IS NULL
CREATE TABLE dbo.Shipments (
    id                 BIGINT IDENTITY(1,1) CONSTRAINT PK_Shipments PRIMARY KEY,
    order_id           BIGINT NOT NULL CONSTRAINT UQ_Shipments_order UNIQUE
                       CONSTRAINT FK_Shipments_Orders REFERENCES dbo.Orders(id) ON DELETE CASCADE,
    tracking_number    NVARCHAR(40) NOT NULL CONSTRAINT UQ_Shipments_tracking UNIQUE,
    status             NVARCHAR(30) NOT NULL CONSTRAINT CK_Shipments_status
                       CHECK (status IN (N'PREPARING', N'DISPATCHED', N'OUT_FOR_DELIVERY', N'DELIVERED', N'CANCELLED')),
    estimated_delivery DATE NULL,
    created_date       DATETIME2(0) NOT NULL CONSTRAINT DF_Shipments_created DEFAULT GETDATE()
);
GO
IF OBJECT_ID(N'dbo.DeliveryAssignments', N'U') IS NULL
CREATE TABLE dbo.DeliveryAssignments (
    id             BIGINT IDENTITY(1,1) CONSTRAINT PK_DeliveryAssignments PRIMARY KEY,
    shipment_id    BIGINT NOT NULL CONSTRAINT FK_DeliveryAssignments_Shipments REFERENCES dbo.Shipments(id) ON DELETE CASCADE,
    staff_id       BIGINT NOT NULL CONSTRAINT FK_DeliveryAssignments_Users REFERENCES dbo.Users(id),
    assigned_date  DATETIME2(0) NOT NULL CONSTRAINT DF_DeliveryAssignments_date DEFAULT GETDATE(),
    status         NVARCHAR(20) NOT NULL CONSTRAINT CK_DeliveryAssignments_status
                   CHECK (status IN (N'ASSIGNED', N'IN_PROGRESS', N'COMPLETED', N'FAILED'))
);
GO
IF OBJECT_ID(N'dbo.PromotionUsages', N'U') IS NULL
CREATE TABLE dbo.PromotionUsages (
    id             BIGINT IDENTITY(1,1) CONSTRAINT PK_PromotionUsages PRIMARY KEY,
    promotion_id   BIGINT NOT NULL CONSTRAINT FK_PromotionUsages_Promotions REFERENCES dbo.Promotions(id),
    order_id       BIGINT NOT NULL CONSTRAINT FK_PromotionUsages_Orders REFERENCES dbo.Orders(id) ON DELETE CASCADE,
    user_id        BIGINT NOT NULL CONSTRAINT FK_PromotionUsages_Users REFERENCES dbo.Users(id),
    applied_amount DECIMAL(12,2) NOT NULL,
    used_date      DATETIME2(0) NOT NULL CONSTRAINT DF_PromotionUsages_date DEFAULT GETDATE()
);
GO

/* ---------- FR-06 Analytics (saved report configurations) ---------- */
IF OBJECT_ID(N'dbo.SalesReports', N'U') IS NULL
CREATE TABLE dbo.SalesReports (
    id              BIGINT IDENTITY(1,1) CONSTRAINT PK_SalesReports PRIMARY KEY,
    report_name     NVARCHAR(120) NOT NULL,
    report_type     NVARCHAR(30)  NOT NULL CONSTRAINT CK_SalesReports_type CHECK (report_type IN (N'SALES_SUMMARY', N'PRODUCT_PERFORMANCE', N'CATEGORY_PERFORMANCE')),
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    product_id      BIGINT NULL CONSTRAINT FK_SalesReports_Products REFERENCES dbo.Products(id) ON DELETE SET NULL,
    category_id     BIGINT NULL CONSTRAINT FK_SalesReports_Categories REFERENCES dbo.Categories(id) ON DELETE SET NULL,
    order_status    NVARCHAR(30) NULL,
    export_format   NVARCHAR(10) NOT NULL CONSTRAINT DF_SalesReports_fmt DEFAULT N'CSV' CONSTRAINT CK_SalesReports_fmt CHECK (export_format IN (N'CSV', N'JSON')),
    created_by      BIGINT NOT NULL CONSTRAINT FK_SalesReports_Users REFERENCES dbo.Users(id),
    created_date    DATETIME2(0) NOT NULL CONSTRAINT DF_SalesReports_created DEFAULT GETDATE(),
    CONSTRAINT CK_SalesReports_dates CHECK (start_date <= end_date)
);
GO

/* ---------- Indexes on frequently queried columns ---------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Products_category' AND object_id = OBJECT_ID(N'dbo.Products'))
    CREATE INDEX IX_Products_category ON dbo.Products(category_id) INCLUDE (brand_id, status, deleted);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Products_brand' AND object_id = OBJECT_ID(N'dbo.Products'))
    CREATE INDEX IX_Products_brand ON dbo.Products(brand_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ProductImages_product' AND object_id = OBJECT_ID(N'dbo.ProductImages'))
    CREATE INDEX IX_ProductImages_product ON dbo.ProductImages(product_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Orders_user' AND object_id = OBJECT_ID(N'dbo.Orders'))
    CREATE INDEX IX_Orders_user ON dbo.Orders(user_id, created_date DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Orders_status' AND object_id = OBJECT_ID(N'dbo.Orders'))
    CREATE INDEX IX_Orders_status ON dbo.Orders(status, created_date);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_OrderItems_order' AND object_id = OBJECT_ID(N'dbo.OrderItems'))
    CREATE INDEX IX_OrderItems_order ON dbo.OrderItems(order_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_OrderItems_product' AND object_id = OBJECT_ID(N'dbo.OrderItems'))
    CREATE INDEX IX_OrderItems_product ON dbo.OrderItems(product_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_StockMovements_product' AND object_id = OBJECT_ID(N'dbo.StockMovements'))
    CREATE INDEX IX_StockMovements_product ON dbo.StockMovements(product_id, created_date DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CartItems_cart' AND object_id = OBJECT_ID(N'dbo.CartItems'))
    CREATE INDEX IX_CartItems_cart ON dbo.CartItems(cart_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_DeliveryAssignments_staff' AND object_id = OBJECT_ID(N'dbo.DeliveryAssignments'))
    CREATE INDEX IX_DeliveryAssignments_staff ON dbo.DeliveryAssignments(staff_id, status);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PromotionUsages_promo' AND object_id = OBJECT_ID(N'dbo.PromotionUsages'))
    CREATE INDEX IX_PromotionUsages_promo ON dbo.PromotionUsages(promotion_id);
GO
PRINT 'ShopSphereDB schema is ready.';
GO
