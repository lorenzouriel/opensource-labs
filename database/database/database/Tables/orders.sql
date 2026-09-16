-- Classification: Confidential. Retention: 5 years (aligned to Brazilian fiscal document
-- retention; tax authorities may audit up to 5 years, CTN Art. 173/174).
CREATE TABLE [sales].[orders]
(
    [id]           UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_orders_id] DEFAULT NEWSEQUENTIALID(),
    [customer_id]  UNIQUEIDENTIFIER NOT NULL,
    [store_id]     UNIQUEIDENTIFIER NOT NULL,
    [channel]      VARCHAR(15)      NOT NULL,
    [marketplace]  VARCHAR(20)      NULL, -- only set when channel = 'marketplace'
    [status]       VARCHAR(20)      NOT NULL, -- terminal state from OrderLifecycle; crisis days skew toward cancelled/lost
    [subtotal]     DECIMAL(12,2)    NOT NULL,
    [shipping]     DECIMAL(12,2)    NOT NULL,
    [tax]          DECIMAL(12,2)    NOT NULL, -- 12% flat on subtotal
    [total]        DECIMAL(12,2)    NOT NULL,
    [currency]     CHAR(3)          NOT NULL, -- derived from store_id's country
    [promo_code]   VARCHAR(30)      NULL,
    [created_at]   DATETIME2(0)     NOT NULL,
    [date]         AS (CAST([created_at] AS DATE)) PERSISTED,
    CONSTRAINT [PK_orders] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_orders_customers] FOREIGN KEY ([customer_id]) REFERENCES [master_data].[customers] ([id]),
    CONSTRAINT [FK_orders_stores] FOREIGN KEY ([store_id]) REFERENCES [master_data].[stores] ([id]),
    CONSTRAINT [CK_orders_channel] CHECK ([channel] IN ('web', 'mobile_app', 'pos', 'marketplace', 'call_center')),
    CONSTRAINT [CK_orders_marketplace] CHECK ([marketplace] IS NULL OR [marketplace] IN ('MercadoLivre', 'Amazon', 'Shopee')),
    CONSTRAINT [CK_orders_status] CHECK ([status] IN ('pending', 'paid', 'picked', 'shipped', 'returned', 'cancelled', 'delivered', 'refunded', 'lost'))
)
