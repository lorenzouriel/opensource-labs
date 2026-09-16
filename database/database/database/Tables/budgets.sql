-- Classification: Internal (reference/planning data, no personal data). Retention: indefinite.
CREATE TABLE [finance].[budgets]
(
    [id]              UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_budgets_id] DEFAULT NEWSEQUENTIALID(),
    [department]      VARCHAR(20)      NOT NULL,
    [year]            SMALLINT         NOT NULL,
    [quarter]         TINYINT          NOT NULL,
    [category]        VARCHAR(10)      NOT NULL,
    [planned_amount]  DECIMAL(14,2)    NOT NULL,
    [actual_amount]   DECIMAL(14,2)    NOT NULL, -- planned * variance (normal around 1.0, floored at 0.5)
    [currency]        CHAR(3)          NOT NULL CONSTRAINT [DF_budgets_currency] DEFAULT ('BRL'),
    CONSTRAINT [PK_budgets] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [CK_budgets_department] CHECK ([department] IN ('Engineering', 'Product', 'Marketing', 'Sales', 'Customer Success', 'Finance', 'HR', 'IT', 'Security')),
    CONSTRAINT [CK_budgets_quarter] CHECK ([quarter] BETWEEN 1 AND 4),
    CONSTRAINT [CK_budgets_category] CHECK ([category] IN ('headcount', 'software', 'marketing', 'capex', 'opex'))
)
