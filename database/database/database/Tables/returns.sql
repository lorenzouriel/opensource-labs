-- Classification: Confidential. Retention: 5 years (tied to the originating order's fiscal retention).
CREATE TABLE [supply_chain].[returns]
(
    [id]             UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_returns_id] DEFAULT NEWSEQUENTIALID(),
    [order_id]       UNIQUEIDENTIFIER NOT NULL,
    [customer_id]    UNIQUEIDENTIFIER NOT NULL,
    [product_sku]    VARCHAR(20)      NOT NULL,
    [reason]         VARCHAR(20)      NOT NULL,
    [quantity]       INT              NOT NULL,
    [status]         VARCHAR(10)      NOT NULL,
    [created_at]     DATETIME2(0)     NOT NULL,
    [refund_amount]  DECIMAL(12,2)    NOT NULL,
    [currency]       CHAR(3)          NOT NULL CONSTRAINT [DF_returns_currency] DEFAULT ('BRL'),
    CONSTRAINT [PK_returns] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_returns_orders] FOREIGN KEY ([order_id]) REFERENCES [sales].[orders] ([id]),
    CONSTRAINT [FK_returns_customers] FOREIGN KEY ([customer_id]) REFERENCES [master_data].[customers] ([id]),
    CONSTRAINT [FK_returns_products] FOREIGN KEY ([product_sku]) REFERENCES [master_data].[products] ([sku]),
    CONSTRAINT [CK_returns_reason] CHECK ([reason] IN ('defective', 'wrong_item', 'changed_mind', 'damaged_in_transit', 'not_as_described', 'late_delivery', 'duplicate_order')),
    CONSTRAINT [CK_returns_quantity] CHECK ([quantity] BETWEEN 1 AND 3),
    CONSTRAINT [CK_returns_status] CHECK ([status] IN ('requested', 'approved', 'received', 'refunded', 'rejected'))
)
