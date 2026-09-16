-- Classification: Internal. Retention: 5 years (aligned to fiscal retention for consistency
-- with orders/invoices).
CREATE TABLE [supply_chain].[stock_movements]
(
    [id]             UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_stock_movements_id] DEFAULT NEWSEQUENTIALID(),
    [product_sku]    VARCHAR(20)      NOT NULL,
    [warehouse_id]   UNIQUEIDENTIFIER NOT NULL,
    [movement_type]  VARCHAR(20)      NOT NULL,
    [quantity]       INT              NOT NULL,
    [unit_cost]      DECIMAL(12,2)    NOT NULL,
    [reason]         NVARCHAR(200)    NULL,
    [reference_id]   UNIQUEIDENTIFIER NOT NULL, -- independently generated, not an FK to any other table's PK
    [created_at]     DATETIME2(0)     NOT NULL,
    CONSTRAINT [PK_stock_movements] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_stock_movements_products] FOREIGN KEY ([product_sku]) REFERENCES [master_data].[products] ([sku]),
    CONSTRAINT [FK_stock_movements_warehouses] FOREIGN KEY ([warehouse_id]) REFERENCES [master_data].[warehouses] ([id]),
    CONSTRAINT [CK_stock_movements_movement_type] CHECK ([movement_type] IN ('inbound', 'outbound', 'transfer', 'adjustment', 'return', 'damage_write_off'))
)
