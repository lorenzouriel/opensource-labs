-- Classification: Confidential (tied to orders). Retention: 5 years.
CREATE TABLE [sales].[order_items]
(
    [id]            UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_order_items_id] DEFAULT NEWSEQUENTIALID(),
    [order_id]      UNIQUEIDENTIFIER NOT NULL,
    [product_id]    VARCHAR(20)      NOT NULL, -- holds products.sku despite the name
    [quantity]      INT              NOT NULL,
    [unit_price]    DECIMAL(12,2)    NOT NULL, -- snapshot of products.price at order time
    [discount_pct]  DECIMAL(5,2)     NOT NULL CONSTRAINT [DF_order_items_discount_pct] DEFAULT (0),
    [line_total]    DECIMAL(12,2)    NOT NULL,
    CONSTRAINT [PK_order_items] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_order_items_orders] FOREIGN KEY ([order_id]) REFERENCES [sales].[orders] ([id]),
    CONSTRAINT [FK_order_items_products] FOREIGN KEY ([product_id]) REFERENCES [master_data].[products] ([sku]),
    CONSTRAINT [CK_order_items_quantity] CHECK ([quantity] BETWEEN 1 AND 3),
    CONSTRAINT [CK_order_items_discount_pct] CHECK ([discount_pct] IN (0, 5, 10, 15, 20))
)
