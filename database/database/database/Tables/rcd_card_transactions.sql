-- Classification: Restricted. Retention: 5 years, tokenized card_id only — no raw PAN ever
-- stored (see data-privacy-lgpd.md §5).
CREATE TABLE [finance].[rcd_card_transactions]
(
    [id]                 UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_rcd_card_transactions_id] DEFAULT NEWSEQUENTIALID(),
    [card_id]            VARCHAR(20)      NOT NULL, -- synthetic CARD-###### token, not a real PAN
    [customer_id]        UNIQUEIDENTIFIER NOT NULL,
    [merchant_category]  VARCHAR(20)      NOT NULL,
    [amount]             DECIMAL(12,2)    NOT NULL,
    [currency]           CHAR(3)          NOT NULL CONSTRAINT [DF_rcd_card_transactions_currency] DEFAULT ('BRL'),
    [status]             VARCHAR(10)      NOT NULL,
    [posted_at]          DATETIME2(0)     NOT NULL,
    CONSTRAINT [PK_rcd_card_transactions] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_rcd_card_transactions_customers] FOREIGN KEY ([customer_id]) REFERENCES [master_data].[customers] ([id]),
    CONSTRAINT [CK_rcd_card_transactions_merchant_category] CHECK ([merchant_category] IN ('electronics', 'restaurants', 'travel', 'fuel', 'grocery', 'entertainment', 'utilities', 'healthcare', 'clothing', 'online_retail')),
    CONSTRAINT [CK_rcd_card_transactions_status] CHECK ([status] IN ('approved', 'declined', 'pending'))
)
