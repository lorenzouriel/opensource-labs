-- Classification: Internal (legal-entity data, not personal data). Retention: contract duration + 5 years.
CREATE TABLE [master_data].[suppliers]
(
    [id]              UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_suppliers_id] DEFAULT NEWSEQUENTIALID(),
    [name]            NVARCHAR(200)    NOT NULL,
    [country]         CHAR(2)          NOT NULL,
    [rating]          DECIMAL(2,1)     NOT NULL,
    [lead_time_days]  INT              NOT NULL,
    [payment_terms]   VARCHAR(10)      NOT NULL,
    [category]        VARCHAR(20)      NOT NULL,
    CONSTRAINT [PK_suppliers] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [CK_suppliers_country] CHECK ([country] IN ('BR', 'MX', 'PT', 'US')),
    CONSTRAINT [CK_suppliers_rating] CHECK ([rating] BETWEEN 1.0 AND 5.0),
    CONSTRAINT [CK_suppliers_lead_time_days] CHECK ([lead_time_days] BETWEEN 3 AND 60),
    CONSTRAINT [CK_suppliers_payment_terms] CHECK ([payment_terms] IN ('net_30', 'net_60', 'net_90', 'prepaid')),
    CONSTRAINT [CK_suppliers_category] CHECK ([category] IN ('electronics', 'appliances', 'packaging', 'logistics', 'components', 'raw_materials'))
)
