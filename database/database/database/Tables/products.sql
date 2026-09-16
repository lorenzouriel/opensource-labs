-- Classification: Internal (no personal data). Retention: indefinite (reference data).
CREATE TABLE [master_data].[products]
(
    [sku]          VARCHAR(20)      NOT NULL,
    [name]         NVARCHAR(200)    NOT NULL,
    [category]     NVARCHAR(100)    NOT NULL,
    [subcategory]  NVARCHAR(100)    NULL,
    [brand]        NVARCHAR(100)    NOT NULL,
    [cost]         DECIMAL(12,2)    NOT NULL,
    [price]        DECIMAL(12,2)    NOT NULL,
    [currency]     CHAR(3)          NOT NULL CONSTRAINT [DF_products_currency] DEFAULT ('BRL'), -- all product pricing is BRL-denominated at the source
    [margin]       AS (CAST(([price] - [cost]) AS DECIMAL(12,4)) / NULLIF([price], 0)) PERSISTED,
    [supplier_id]  UNIQUEIDENTIFIER NOT NULL,
    [weight_kg]    DECIMAL(10,3)    NULL,
    [launch_date]  DATE             NOT NULL,
    [is_active]    BIT              NOT NULL CONSTRAINT [DF_products_is_active] DEFAULT (1),
    CONSTRAINT [PK_products] PRIMARY KEY CLUSTERED ([sku]),
    CONSTRAINT [FK_products_suppliers] FOREIGN KEY ([supplier_id]) REFERENCES [master_data].[suppliers] ([id]),
    CONSTRAINT [CK_products_currency] CHECK ([currency] = 'BRL')
)
