/* =====================================================================
   ShopSphere - 02_seed.sql
   Demo data: users (BCrypt), catalogue, images, inventory, promotions,
   orders in every status, payments, shipments, deliveries, stock movements.
   Re-runnable: does nothing if the database is already seeded.
   All demo passwords: Demo@123
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
GO
USE ShopSphereDB;
GO
IF EXISTS (SELECT 1 FROM dbo.Roles)
BEGIN
    PRINT 'Seed data already present - nothing to do. (Use RESET_DATABASE.bat to restore the original state.)';
    RETURN;
END

BEGIN TRANSACTION;

DECLARE @pwd NVARCHAR(100) = N'$2a$10$ooueDp7gc0j9QFEnI37oheXYQClkqZ.Jc34iOrLhdPMj2b1M9fWO.';
DECLARE @today DATE = CAST(GETDATE() AS DATE);

/* ---------- Roles & users ---------- */
SET IDENTITY_INSERT dbo.Roles ON;
INSERT dbo.Roles (id, name) VALUES (1, N'ADMIN'), (2, N'STAFF'), (3, N'WAREHOUSE'), (4, N'DELIVERY'), (5, N'CUSTOMER');
SET IDENTITY_INSERT dbo.Roles OFF;

SET IDENTITY_INSERT dbo.Users ON;
INSERT dbo.Users (id, email, password_hash, first_name, last_name, phone, role_id, created_at) VALUES
 (1, N'admin@shopsphere.lk',     @pwd, N'Amara',   N'Jayawardena', N'0771234501', 1, DATEADD(day, -90, GETDATE())),
 (2, N'staff@shopsphere.lk',     @pwd, N'Dilan',   N'Wickramasinghe', N'0771234502', 2, DATEADD(day, -90, GETDATE())),
 (3, N'warehouse@shopsphere.lk', @pwd, N'Chamara', N'Bandara', N'0771234503', 3, DATEADD(day, -90, GETDATE())),
 (4, N'delivery@shopsphere.lk',  @pwd, N'Suresh',  N'Kumar', N'0771234504', 4, DATEADD(day, -90, GETDATE())),
 (5, N'customer@shopsphere.lk',  @pwd, N'Nimal',   N'Perera', N'0771234505', 5, DATEADD(day, -60, GETDATE())),
 (6, N'kavindi@shopsphere.lk',   @pwd, N'Kavindi', N'Silva', N'0771234506', 5, DATEADD(day, -50, GETDATE())),
 (7, N'ruwan@shopsphere.lk',     @pwd, N'Ruwan',   N'Fernando', N'0771234507', 5, DATEADD(day, -45, GETDATE())),
 (8, N'delivery2@shopsphere.lk', @pwd, N'Prasad',  N'Rathnayake', N'0771234508', 4, DATEADD(day, -90, GETDATE()));
SET IDENTITY_INSERT dbo.Users OFF;

INSERT dbo.Addresses (user_id, label, address, apartment, city, postal_code, country, phone, is_default) VALUES
 (5, N'Home', N'45 Galle Road', N'Apt 3B', N'Colombo', N'00300', N'Sri Lanka', N'0771234505', 1),
 (5, N'Office', N'12 Duplication Road', NULL, N'Colombo', N'00400', N'Sri Lanka', N'0112345678', 0),
 (6, N'Home', N'88 Peradeniya Road', NULL, N'Kandy', N'20000', N'Sri Lanka', N'0771234506', 1),
 (7, N'Home', N'7 Lighthouse Street', N'Unit 2', N'Galle', N'80000', N'Sri Lanka', N'0771234507', 1);

/* ---------- Categories & brands ---------- */
SET IDENTITY_INSERT dbo.Categories ON;
INSERT dbo.Categories (id, name, description) VALUES
 (1, N'Fashion',            N'Clothing and everyday wear for men and women.'),
 (2, N'Electronics',        N'Audio, wearables, computer accessories and gadgets.'),
 (3, N'Accessories',        N'Bags, watches, eyewear and small everyday carry.'),
 (4, N'Home & Living',      N'Homeware, office and stationery essentials.'),
 (5, N'Sports & Outdoors',  N'Footwear and gear for workouts and the outdoors.'),
 (6, N'Beauty & Care',      N'Fragrances and personal care.');
SET IDENTITY_INSERT dbo.Categories OFF;

SET IDENTITY_INSERT dbo.Brands ON;
INSERT dbo.Brands (id, name, description) VALUES
 (1, N'UrbanEdge', N'Contemporary streetwear and everyday essentials.'),
 (2, N'NovaTech',  N'Consumer electronics designed for daily life.'),
 (3, N'PeakFit',   N'Performance gear for active lifestyles.'),
 (4, N'Aurora',    N'Lifestyle, home and fragrance collections.');
SET IDENTITY_INSERT dbo.Brands OFF;

/* ---------- Products (LKR) ---------- */
SET IDENTITY_INSERT dbo.Products ON;
INSERT dbo.Products (id, name, description, price, sku, category_id, brand_id, created_at, updated_at) VALUES
 (1,  N'Premium Cotton T-Shirt',    N'Soft 100% combed cotton crew-neck tee with a relaxed fit. Pre-shrunk and breathable for all-day comfort.', 3490.00,  N'TSH-001', 1, 1, DATEADD(day,-80,GETDATE()), DATEADD(day,-80,GETDATE())),
 (2,  N'Wireless Headphones Pro',   N'Over-ear Bluetooth 5.3 headphones with active noise cancelling and 40 hours of battery life.',            18900.00, N'ELC-001', 2, 2, DATEADD(day,-79,GETDATE()), DATEADD(day,-79,GETDATE())),
 (3,  N'Smart Watch Series 5',      N'Fitness-focused smartwatch with heart-rate tracking, GPS, sleep monitoring and a bright AMOLED display.',  32500.00, N'ELC-002', 2, 2, DATEADD(day,-78,GETDATE()), DATEADD(day,-78,GETDATE())),
 (4,  N'Canvas Travel Backpack',    N'Durable waxed-canvas backpack with padded laptop compartment and water-resistant lining.',                8900.00,  N'BAG-001', 3, 1, DATEADD(day,-77,GETDATE()), DATEADD(day,-77,GETDATE())),
 (5,  N'Velocity Running Shoes',    N'Lightweight road-running shoes with responsive cushioning and a breathable mesh upper.',                  14500.00, N'SPT-001', 5, 3, DATEADD(day,-76,GETDATE()), DATEADD(day,-76,GETDATE())),
 (6,  N'LED Desk Lamp',             N'Dimmable LED desk lamp with three colour temperatures and a flexible arm. Energy efficient.',             6750.00,  N'HOM-001', 4, 4, DATEADD(day,-75,GETDATE()), DATEADD(day,-75,GETDATE())),
 (7,  N'Ceramic Coffee Mug',        N'Hand-glazed 350ml ceramic mug with a comfortable handle. Dishwasher and microwave safe.',                 1850.00,  N'HOM-002', 4, 4, DATEADD(day,-74,GETDATE()), DATEADD(day,-74,GETDATE())),
 (8,  N'Slim Phone Case',           N'Shock-absorbing slim case with soft-touch finish and raised edges for screen and camera protection.',     1950.00,  N'ACC-001', 3, 2, DATEADD(day,-73,GETDATE()), DATEADD(day,-73,GETDATE())),
 (9,  N'Classic Analog Watch',      N'Stainless-steel analog wristwatch with sapphire-coated glass and a genuine leather strap.',               24500.00, N'ACC-002', 3, 4, DATEADD(day,-72,GETDATE()), DATEADD(day,-72,GETDATE())),
 (10, N'Winter Puffer Jacket',      N'Insulated water-repellent puffer jacket with a packable hood and zip pockets.',                           21900.00, N'FSH-002', 1, 1, DATEADD(day,-71,GETDATE()), DATEADD(day,-71,GETDATE())),
 (11, N'Slim-Fit Denim Jeans',      N'Stretch denim jeans with a modern slim fit and five-pocket styling.',                                     7900.00,  N'FSH-003', 1, 1, DATEADD(day,-70,GETDATE()), DATEADD(day,-70,GETDATE())),
 (12, N'Classic Sunglasses',        N'UV400-protection polarised sunglasses with a lightweight durable frame.',                                 4200.00,  N'ACC-003', 3, 4, DATEADD(day,-69,GETDATE()), DATEADD(day,-69,GETDATE())),
 (13, N'Laptop Sleeve 15"',         N'Padded neoprene-lined sleeve that fits laptops up to 15 inches. Includes a front accessory pocket.',      3900.00,  N'ACC-004', 3, 2, DATEADD(day,-68,GETDATE()), DATEADD(day,-68,GETDATE())),
 (14, N'Portable Bluetooth Speaker',N'Compact waterproof speaker with 360-degree sound and 12 hours of playtime.',                              9800.00,  N'ELC-003', 2, 2, DATEADD(day,-67,GETDATE()), DATEADD(day,-67,GETDATE())),
 (15, N'Steel Water Bottle 750ml',  N'Double-wall vacuum-insulated stainless-steel bottle. Keeps drinks cold for 24 hours and hot for 12.',      2650.00,  N'SPT-002', 5, 3, DATEADD(day,-66,GETDATE()), DATEADD(day,-66,GETDATE())),
 (16, N'Pro Yoga Mat',              N'6mm non-slip eco-friendly yoga mat with alignment guides and a carry strap.',                             4800.00,  N'SPT-003', 5, 3, DATEADD(day,-65,GETDATE()), DATEADD(day,-65,GETDATE())),
 (17, N'Mechanical Keyboard',       N'Tenkeyless mechanical keyboard with tactile switches, backlighting and a detachable USB-C cable.',        15900.00, N'ELC-004', 2, 2, DATEADD(day,-64,GETDATE()), DATEADD(day,-64,GETDATE())),
 (18, N'Wireless Mouse',            N'Ergonomic 2.4GHz wireless mouse with silent clicks and adjustable DPI. Up to 12 months of battery.',      3950.00,  N'ELC-005', 2, 2, DATEADD(day,-63,GETDATE()), DATEADD(day,-63,GETDATE())),
 (19, N'Casual White Sneakers',     N'Clean low-top leather sneakers with a cushioned insole. Goes with everything.',                           11500.00, N'FSH-004', 1, 1, DATEADD(day,-62,GETDATE()), DATEADD(day,-62,GETDATE())),
 (20, N'Grey Cotton Hoodie',        N'Heavyweight fleece-lined pullover hoodie with kangaroo pocket and adjustable drawstring hood.',           6400.00,  N'FSH-005', 1, 1, DATEADD(day,-61,GETDATE()), DATEADD(day,-61,GETDATE())),
 (21, N'Leather Wallet',            N'Slim bifold wallet in full-grain leather with RFID-blocking lining and six card slots.',                  4500.00,  N'ACC-005', 3, 4, DATEADD(day,-60,GETDATE()), DATEADD(day,-60,GETDATE())),
 (22, N'Eau de Parfum 50ml',        N'Long-lasting floral-woody fragrance with notes of jasmine, sandalwood and amber.',                        12500.00, N'BTY-001', 6, 4, DATEADD(day,-59,GETDATE()), DATEADD(day,-59,GETDATE())),
 (23, N'Power Bank 20000mAh',       N'High-capacity power bank with dual USB output and 22.5W fast charging. Charges most phones 4 times.',      7200.00,  N'ELC-006', 2, 2, DATEADD(day,-58,GETDATE()), DATEADD(day,-58,GETDATE())),
 (24, N'Hardcover Notebook',        N'A5 dotted hardcover notebook with 192 pages of thick, ink-friendly paper and a ribbon marker.',           1250.00,  N'HOM-003', 4, 4, DATEADD(day,-57,GETDATE()), DATEADD(day,-57,GETDATE()));
SET IDENTITY_INSERT dbo.Products OFF;

INSERT dbo.ProductImages (product_id, image_path) VALUES
 (1,  N'/images/products/tshirt-premium.jpg'),   (2,  N'/images/products/headphones-wireless.jpg'),
 (3,  N'/images/products/smartwatch-001.jpg'),   (4,  N'/images/products/backpack-canvas.jpg'),
 (5,  N'/images/products/shoes-running.jpg'),    (6,  N'/images/products/lamp-desk.jpg'),
 (7,  N'/images/products/mug-coffee.jpg'),       (8,  N'/images/products/phone-case.jpg'),
 (9,  N'/images/products/watch-analog.jpg'),     (10, N'/images/products/jacket-winter.jpg'),
 (11, N'/images/products/jeans-denim.jpg'),      (12, N'/images/products/sunglasses-classic.jpg'),
 (13, N'/images/products/laptop-sleeve.jpg'),    (14, N'/images/products/bluetooth-speaker.jpg'),
 (15, N'/images/products/water-bottle.jpg'),     (16, N'/images/products/yoga-mat.jpg'),
 (17, N'/images/products/keyboard-mechanical.jpg'), (18, N'/images/products/mouse-wireless.jpg'),
 (19, N'/images/products/sneakers-casual.jpg'),  (20, N'/images/products/hoodie-grey.jpg'),
 (21, N'/images/products/wallet-leather.jpg'),   (22, N'/images/products/perfume-bottle.jpg'),
 (23, N'/images/products/powerbank-20000.jpg'),  (24, N'/images/products/notebook-hardcover.jpg');

/* ---------- Promotions ---------- */
SET IDENTITY_INSERT dbo.Promotions ON;
INSERT dbo.Promotions (id, coupon_code, discount_type, discount_value, start_date, end_date, is_active, usage_limit, usage_count) VALUES
 (1, N'SUMMER10',   N'PERCENTAGE', 10.00,  DATEADD(day,-60,@today), DATEADD(day,120,@today), 1, NULL, 1),
 (2, N'WINTER20',   N'PERCENTAGE', 20.00,  DATEADD(day,-30,@today), DATEADD(day,90,@today),  1, 200,  1),
 (3, N'LKR500OFF',  N'FIXED',      500.00, DATEADD(day,-30,@today), DATEADD(day,60,@today),  1, NULL, 1),
 (4, N'WELCOME15',  N'PERCENTAGE', 15.00,  DATEADD(day,-10,@today), DATEADD(day,180,@today), 1, 100,  0),
 (5, N'FLASH25',    N'PERCENTAGE', 25.00,  DATEADD(day,-40,@today), DATEADD(day,-10,@today), 1, NULL, 0),   -- expired
 (6, N'MEGA30',     N'PERCENTAGE', 30.00,  DATEADD(day,-10,@today), DATEADD(day,60,@today),  0, NULL, 0),   -- inactive
 (7, N'LIMITED5',   N'FIXED',      1000.00,DATEADD(day,-20,@today), DATEADD(day,60,@today),  1, 5,    5);   -- usage limit reached
SET IDENTITY_INSERT dbo.Promotions OFF;

/* ---------- Inventory (initial stock; sold quantities are deducted below) ---------- */
INSERT dbo.Inventory (product_id, quantity, reorder_level, last_updated)
SELECT v.pid, v.qty, v.reorder, DATEADD(day, -60, GETDATE())
FROM (VALUES
 (1, 120, 20), (2, 45, 10), (3, 30, 8),  (4, 60, 10), (5, 50, 10), (6, 40, 10),
 (7, 150, 25), (8, 200, 30), (9, 6, 8),  (10, 35, 8), (11, 70, 15), (12, 1, 5),
 (13, 80, 15), (14, 40, 10), (15, 90, 15), (16, 55, 10), (17, 9, 10), (18, 100, 20),
 (19, 45, 10), (20, 65, 12), (21, 75, 15), (22, 4, 5),  (23, 5, 10), (24, 180, 30)
) AS v(pid, qty, reorder);

INSERT dbo.StockMovements (product_id, movement_type, quantity, quantity_after, reason, created_by, created_date)
SELECT product_id, N'IN', quantity, quantity, N'INITIAL_STOCK', 3, DATEADD(day, -60, GETDATE()) FROM dbo.Inventory;

/* ---------- Orders (one per status) ---------- */
SET IDENTITY_INSERT dbo.Orders ON;
INSERT dbo.Orders (id, order_number, user_id, total_amount, discount_applied, final_amount, promotion_id, status,
                   email, first_name, last_name, address, apartment, city, postal_code, country, phone, created_date, updated_date)
SELECT o.id,
       N'SS-' + CONVERT(NVARCHAR(8), DATEADD(minute, -(o.daysAgo * 1440 + o.id * 37), GETDATE()), 112) + N'-' + RIGHT(N'00000' + CAST(o.id AS NVARCHAR(5)), 5),
       o.uid, 0, 0, 0, o.promo, o.status,
       u.email, u.first_name, u.last_name, a.address, a.apartment, a.city, a.postal_code, a.country, ISNULL(a.phone, u.phone),
       DATEADD(minute, -(o.daysAgo * 1440 + o.id * 37), GETDATE()),
       DATEADD(minute, -(o.daysAgo * 1440 + o.id * 37) + 600, GETDATE())
FROM (VALUES
 (1,  5, 40, N'DELIVERED',          NULL), (2,  6, 34, N'DELIVERED',          NULL),
 (3,  7, 28, N'DELIVERED',          1),    (4,  5, 21, N'DELIVERED',          NULL),
 (5,  6, 16, N'DELIVERED',          2),    (6,  5, 4,  N'OUT_FOR_DELIVERY',   NULL),
 (7,  7, 3,  N'DISPATCHED',         NULL), (8,  6, 2,  N'READY_FOR_DISPATCH', NULL),
 (9,  5, 2,  N'PROCESSING',         NULL), (10, 7, 1,  N'CONFIRMED',          NULL),
 (11, 6, 1,  N'CONFIRMED',          3),    (12, 5, 0,  N'PENDING',            NULL),
 (13, 7, 12, N'CANCELLED',          NULL), (14, 5, 8,  N'DELIVERED',          NULL)
) AS o(id, uid, daysAgo, status, promo)
JOIN dbo.Users u ON u.id = o.uid
JOIN dbo.Addresses a ON a.user_id = o.uid AND a.is_default = 1;
SET IDENTITY_INSERT dbo.Orders OFF;

INSERT dbo.OrderItems (order_id, product_id, product_name, quantity, price_at_order)
SELECT i.oid, p.id, p.name, i.qty, p.price
FROM (VALUES
 (1, 1, 2), (1, 11, 1),
 (2, 2, 1), (2, 18, 1),
 (3, 5, 1), (3, 16, 1), (3, 15, 1),
 (4, 3, 1),
 (5, 10, 1), (5, 20, 1),
 (6, 9, 1), (6, 12, 1),
 (7, 14, 1), (7, 23, 2),
 (8, 17, 1),
 (9, 19, 1), (9, 7, 2),
 (10, 22, 1),
 (11, 4, 1), (11, 13, 1),
 (12, 21, 1), (12, 24, 3),
 (13, 8, 2),
 (14, 6, 1), (14, 7, 1)
) AS i(oid, pid, qty)
JOIN dbo.Products p ON p.id = i.pid;

UPDATE o SET total_amount = t.subtotal
FROM dbo.Orders o
JOIN (SELECT order_id, SUM(quantity * price_at_order) AS subtotal FROM dbo.OrderItems GROUP BY order_id) t ON t.order_id = o.id;

UPDATE o SET coupon_code = p.coupon_code,
             discount_applied = CASE p.discount_type WHEN N'PERCENTAGE' THEN ROUND(o.total_amount * p.discount_value / 100, 2) ELSE p.discount_value END
FROM dbo.Orders o JOIN dbo.Promotions p ON p.id = o.promotion_id;

UPDATE dbo.Orders SET final_amount = total_amount - discount_applied;

INSERT dbo.PromotionUsages (promotion_id, order_id, user_id, applied_amount, used_date)
SELECT promotion_id, id, user_id, discount_applied, created_date FROM dbo.Orders WHERE promotion_id IS NOT NULL;

/* ---------- Payments (sandbox card payments) ---------- */
INSERT dbo.Payments (order_id, amount, payment_method, card_brand, card_last4, transaction_id, status, payment_time)
SELECT id, final_amount, N'TEST_CARD', CASE WHEN id % 2 = 0 THEN N'MASTERCARD' ELSE N'VISA' END,
       CASE WHEN id % 2 = 0 THEN N'4444' ELSE N'1111' END,
       N'TXN-' + order_number,
       CASE WHEN status = N'CANCELLED' THEN N'REFUNDED' ELSE N'SUCCESS' END,
       created_date
FROM dbo.Orders WHERE status <> N'PENDING';

/* ---------- Shipments & delivery assignments ---------- */
INSERT dbo.Shipments (order_id, tracking_number, status, estimated_delivery, created_date)
SELECT id, N'TRK' + RIGHT(N'000000' + CAST(id AS NVARCHAR(6)), 6) + N'LK',
       CASE status WHEN N'DELIVERED' THEN N'DELIVERED' WHEN N'OUT_FOR_DELIVERY' THEN N'OUT_FOR_DELIVERY'
                   WHEN N'DISPATCHED' THEN N'DISPATCHED' ELSE N'PREPARING' END,
       CAST(DATEADD(day, 5, created_date) AS DATE), created_date
FROM dbo.Orders WHERE status NOT IN (N'PENDING', N'CANCELLED');

INSERT dbo.DeliveryAssignments (shipment_id, staff_id, assigned_date, status)
SELECT s.id, CASE WHEN o.id % 2 = 0 THEN 8 ELSE 4 END, DATEADD(hour, 20, o.created_date),
       CASE o.status WHEN N'DELIVERED' THEN N'COMPLETED' WHEN N'OUT_FOR_DELIVERY' THEN N'IN_PROGRESS' ELSE N'ASSIGNED' END
FROM dbo.Orders o JOIN dbo.Shipments s ON s.order_id = o.id
WHERE o.status IN (N'DELIVERED', N'OUT_FOR_DELIVERY', N'DISPATCHED');

/* ---------- Stock movements for seeded orders, then deduct from inventory ---------- */
INSERT dbo.StockMovements (product_id, movement_type, quantity, quantity_after, reason, created_by, created_date)
SELECT m.product_id, N'OUT', -m.quantity,
       inv.quantity - SUM(m.quantity) OVER (PARTITION BY m.product_id ORDER BY m.created_date, m.order_id ROWS UNBOUNDED PRECEDING),
       N'ORDER_PLACED: ' + m.order_number, NULL, m.created_date
FROM (SELECT oi.product_id, oi.quantity, o.id AS order_id, o.order_number, o.created_date
      FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id = oi.order_id WHERE o.status <> N'CANCELLED') m
JOIN dbo.Inventory inv ON inv.product_id = m.product_id;

UPDATE inv SET quantity = inv.quantity - s.sold, last_updated = GETDATE()
FROM dbo.Inventory inv
JOIN (SELECT oi.product_id, SUM(oi.quantity) AS sold
      FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id = oi.order_id WHERE o.status <> N'CANCELLED'
      GROUP BY oi.product_id) s ON s.product_id = inv.product_id;

/* a supplier restock and a write-off so the movement history shows every type */
UPDATE dbo.Inventory SET quantity = quantity + 30, last_updated = GETDATE() WHERE product_id = 1;
INSERT dbo.StockMovements (product_id, movement_type, quantity, quantity_after, reason, created_by, created_date)
SELECT 1, N'IN', 30, quantity, N'Supplier restock PO-1042', 3, DATEADD(day, -5, GETDATE()) FROM dbo.Inventory WHERE product_id = 1;

UPDATE dbo.Inventory SET quantity = quantity - 2, last_updated = GETDATE() WHERE product_id = 15;
INSERT dbo.StockMovements (product_id, movement_type, quantity, quantity_after, reason, created_by, created_date)
SELECT 15, N'ADJUSTMENT', -2, quantity, N'Damaged stock write-off', 3, DATEADD(day, -3, GETDATE()) FROM dbo.Inventory WHERE product_id = 15;

/* ---------- Saved reports ---------- */
INSERT dbo.SalesReports (report_name, report_type, start_date, end_date, order_status, export_format, created_by)
VALUES (N'Last 60 days - Sales Summary', N'SALES_SUMMARY', DATEADD(day, -60, @today), @today, NULL, N'CSV', 1),
       (N'Category Performance (Delivered only)', N'CATEGORY_PERFORMANCE', DATEADD(day, -60, @today), @today, N'DELIVERED', N'JSON', 1);

COMMIT TRANSACTION;
PRINT 'ShopSphereDB seed data inserted.';
GO
