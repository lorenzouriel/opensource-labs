-- Classification: Internal (no personal data). Retention: indefinite (reference data).
CREATE TABLE [master_data].[warehouses]
(
    [id]            UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_warehouses_id] DEFAULT NEWSEQUENTIALID(),
    [name]          NVARCHAR(150)    NOT NULL,
    [location]      NVARCHAR(100)    NULL,
    [country]       CHAR(2)          NOT NULL,
    [capacity_m3]   INT              NOT NULL,
    [manager_id]    UNIQUEIDENTIFIER NULL, -- always NULL at the source today; same gap as stores.manager_employee_id
    [type]          VARCHAR(10)      NOT NULL,
    CONSTRAINT [PK_warehouses] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_warehouses_employees] FOREIGN KEY ([manager_id]) REFERENCES [master_data].[employees] ([id]),
    CONSTRAINT [CK_warehouses_country] CHECK ([country] IN ('BR', 'MX', 'PT', 'US')),
    CONSTRAINT [CK_warehouses_capacity_m3] CHECK ([capacity_m3] BETWEEN 1000 AND 50000),
    CONSTRAINT [CK_warehouses_type] CHECK ([type] IN ('central', 'regional', 'dark_store'))
)
