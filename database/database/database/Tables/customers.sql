-- Classification: Confidential. Retention: active relationship + 5 years after last order/account
-- closure (tied to fiscal retention on invoices; anonymize rather than hard-delete if still linked).
CREATE TABLE [master_data].[customers]
(
    [id]                 UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_customers_id] DEFAULT NEWSEQUENTIALID(),
    [name]               NVARCHAR(200)    NOT NULL, -- PII
    [email]              NVARCHAR(320)    NOT NULL, -- PII
    [phone]              NVARCHAR(30)     NULL,     -- PII
    [cpf_or_cnpj]        NVARCHAR(20)     NULL,     -- PII, synthetic values only
    [segment]            VARCHAR(3)       NOT NULL,
    [country]            CHAR(2)          NOT NULL,
    [state]              NVARCHAR(100)    NULL,
    [city]               NVARCHAR(100)    NULL,
    [signup_date]        DATE             NOT NULL,
    [ltv_tier]           NVARCHAR(20)     NULL,
    [preferred_channel]  VARCHAR(20)      NULL,
    [loyalty_points]     INT              NOT NULL CONSTRAINT [DF_customers_loyalty_points] DEFAULT (0),
    CONSTRAINT [PK_customers] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [CK_customers_segment] CHECK ([segment] IN ('B2C', 'B2B', 'VIP')),
    CONSTRAINT [CK_customers_country] CHECK ([country] IN ('BR', 'MX', 'PT', 'US')),
    CONSTRAINT [CK_customers_preferred_channel] CHECK ([preferred_channel] IN ('web', 'mobile_app', 'in_store', 'marketplace', 'phone')),
    CONSTRAINT [CK_customers_loyalty_points] CHECK ([loyalty_points] BETWEEN 0 AND 50000)
)
