-- Classification: Confidential. Retention: employment + 5 years (same basis as employees).
CREATE TABLE [hr].[training_records]
(
    [id]            UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_training_records_id] DEFAULT NEWSEQUENTIALID(),
    [employee_id]   UNIQUEIDENTIFIER NOT NULL, -- sampled with replacement; an employee can appear multiple times
    [course_name]   NVARCHAR(200)    NOT NULL,
    [provider]      VARCHAR(30)      NOT NULL,
    [started_at]    DATE             NOT NULL,
    [completed_at]  DATE             NULL, -- ~85% completion rate
    [score]         DECIMAL(5,2)     NULL, -- only set if completed
    [passed]        BIT              NOT NULL, -- score >= 70; false when not completed
    [credits]       TINYINT          NOT NULL,
    CONSTRAINT [PK_training_records] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_training_records_employees] FOREIGN KEY ([employee_id]) REFERENCES [master_data].[employees] ([id]),
    CONSTRAINT [CK_training_records_provider] CHECK ([provider] IN ('Coursera', 'Udemy', 'LinkedIn Learning', 'Internal', 'AWS Training', 'Google Cloud', 'Databricks Academy')),
    CONSTRAINT [CK_training_records_credits] CHECK ([credits] BETWEEN 1 AND 9)
)
