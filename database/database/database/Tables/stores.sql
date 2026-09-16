-- Classification: Internal (no personal data). Retention: indefinite (reference data).
CREATE TABLE [master_data].[stores]
(
    [id]                   UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_stores_id] DEFAULT NEWSEQUENTIALID(),
    [name]                 NVARCHAR(150)    NOT NULL,
    [region]               NVARCHAR(100)    NULL,
    [country]              CHAR(2)          NOT NULL,
    [city]                 NVARCHAR(100)    NULL,
    [type]                 VARCHAR(10)      NOT NULL,
    [opening_date]         DATE             NOT NULL,
    [size_sqm]             INT              NULL,
    [manager_employee_id]  UNIQUEIDENTIFIER NULL, -- always NULL at the source today; no store-to-manager assignment logic exists yet
    CONSTRAINT [PK_stores] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_stores_employees] FOREIGN KEY ([manager_employee_id]) REFERENCES [master_data].[employees] ([id]),
    CONSTRAINT [CK_stores_country] CHECK ([country] IN ('BR', 'MX', 'PT', 'US')),
    CONSTRAINT [CK_stores_type] CHECK ([type] IN ('flagship', 'standard', 'outlet', 'pop_up', 'online', 'warehouse'))
)
