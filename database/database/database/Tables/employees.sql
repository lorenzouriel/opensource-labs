-- Classification: Restricted (contains salary). Retention: employment + 5 years post-termination
-- (confirm shorter, country-specific labor-claim windows with Legal per employees.country).
CREATE TABLE [master_data].[employees]
(
    [id]               UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_employees_id] DEFAULT NEWSEQUENTIALID(),
    [name]             NVARCHAR(200)    NOT NULL, -- PII
    [email]            NVARCHAR(320)    NOT NULL, -- PII
    [department]       NVARCHAR(20)     NOT NULL,
    [role]             NVARCHAR(150)    NOT NULL,
    [manager_id]       UNIQUEIDENTIFIER NULL,
    [hire_date]        DATE             NOT NULL,
    [salary]           DECIMAL(12,2)    NOT NULL, -- Restricted
    [location]         NVARCHAR(100)    NULL,
    [employment_type]  VARCHAR(15)      NOT NULL,
    [level]            VARCHAR(3)       NOT NULL,
    [country]          CHAR(2)          NOT NULL,
    CONSTRAINT [PK_employees] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_employees_manager] FOREIGN KEY ([manager_id]) REFERENCES [master_data].[employees] ([id]),
    CONSTRAINT [CK_employees_employment_type] CHECK ([employment_type] IN ('full_time', 'part_time', 'contractor')),
    CONSTRAINT [CK_employees_level] CHECK ([level] IN ('IC1', 'IC2', 'IC3', 'IC4', 'IC5', 'IC6', 'IC7', 'M1', 'M2', 'M3', 'M4', 'M5')),
    CONSTRAINT [CK_employees_country] CHECK ([country] IN ('BR', 'MX', 'PT', 'US')),
    CONSTRAINT [CK_employees_department] CHECK ([department] IN ('Engineering', 'Product', 'Data & Analytics', 'Marketing', 'Sales', 'Customer Success', 'Supply Chain', 'Manufacturing', 'Finance', 'HR', 'Legal', 'IT', 'Security'))
)
