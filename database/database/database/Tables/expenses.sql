-- Classification: Confidential (contains employee_id/approved_by). Retention: 5 years
-- (fiscal record-keeping basis).
CREATE TABLE [finance].[expenses]
(
    [id]           UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_expenses_id] DEFAULT NEWSEQUENTIALID(),
    [category]     VARCHAR(20)      NOT NULL,
    [amount]       DECIMAL(12,2)    NOT NULL,
    [currency]     CHAR(3)          NOT NULL CONSTRAINT [DF_expenses_currency] DEFAULT ('BRL'),
    [department]   VARCHAR(20)      NOT NULL, -- narrower ad-hoc list, not the 13-value company.departments list
    [employee_id]  UNIQUEIDENTIFIER NOT NULL, -- submitter
    [approved_by]  UNIQUEIDENTIFIER NOT NULL, -- approver, sampled independently of any approval hierarchy
    [date]         DATE             NOT NULL,
    [description]  NVARCHAR(200)    NULL,
    [status]       VARCHAR(10)      NOT NULL,
    CONSTRAINT [PK_expenses] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_expenses_employees] FOREIGN KEY ([employee_id]) REFERENCES [master_data].[employees] ([id]),
    CONSTRAINT [FK_expenses_approved_by] FOREIGN KEY ([approved_by]) REFERENCES [master_data].[employees] ([id]),
    CONSTRAINT [CK_expenses_category] CHECK ([category] IN ('travel', 'software', 'hardware', 'marketing', 'office_supplies', 'consulting', 'training', 'meals', 'utilities', 'miscellaneous')),
    CONSTRAINT [CK_expenses_department] CHECK ([department] IN ('Engineering', 'Marketing', 'Sales', 'Finance', 'HR', 'Other')),
    CONSTRAINT [CK_expenses_status] CHECK ([status] IN ('approved', 'pending', 'rejected'))
)
