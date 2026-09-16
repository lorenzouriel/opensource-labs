-- Classification: Internal. Retention: 5 years (aligned to fiscal retention for consistency
-- with orders/invoices).
CREATE TABLE [supply_chain].[purchase_orders]
(
    [id]            UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_purchase_orders_id] DEFAULT NEWSEQUENTIALID(),
    [supplier_id]   UNIQUEIDENTIFIER NOT NULL,
    [warehouse_id]  UNIQUEIDENTIFIER NOT NULL,
    [status]        VARCHAR(10)      NOT NULL,
    [total_amount]  DECIMAL(14,2)    NOT NULL,
    [currency]      CHAR(3)          NOT NULL CONSTRAINT [DF_purchase_orders_currency] DEFAULT ('BRL'),
    [ordered_at]    DATE             NOT NULL,
    [expected_at]   DATE             NOT NULL, -- ordered_at + 3-45 days
    [received_at]   DATE             NULL, -- only when status = 'received'
    [notes]         NVARCHAR(500)    NULL, -- always NULL at the source today; no free-text notes are ever generated
    CONSTRAINT [PK_purchase_orders] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_purchase_orders_suppliers] FOREIGN KEY ([supplier_id]) REFERENCES [master_data].[suppliers] ([id]),
    CONSTRAINT [FK_purchase_orders_warehouses] FOREIGN KEY ([warehouse_id]) REFERENCES [master_data].[warehouses] ([id]),
    CONSTRAINT [CK_purchase_orders_status] CHECK ([status] IN ('draft', 'submitted', 'approved', 'shipped', 'received', 'cancelled'))
)
