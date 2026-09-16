-- Classification: Confidential. Retention: employment + 5 years (same basis as employees).
CREATE TABLE [hr].[performance_reviews]
(
    [id]           UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_performance_reviews_id] DEFAULT NEWSEQUENTIALID(),
    [employee_id]  UNIQUEIDENTIFIER NOT NULL, -- reviewee, at most one review per employee per run
    [reviewer_id]  UNIQUEIDENTIFIER NOT NULL, -- sampled independently, not validated against employees.manager_id
    [period]       VARCHAR(10)      NOT NULL,
    [score]        DECIMAL(3,2)     NOT NULL,
    [rating]       VARCHAR(25)      NOT NULL,
    [comments]     NVARCHAR(500)    NULL,
    [reviewed_at]  DATE             NOT NULL,
    CONSTRAINT [PK_performance_reviews] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_performance_reviews_employee] FOREIGN KEY ([employee_id]) REFERENCES [master_data].[employees] ([id]),
    CONSTRAINT [FK_performance_reviews_reviewer] FOREIGN KEY ([reviewer_id]) REFERENCES [master_data].[employees] ([id]),
    CONSTRAINT [CK_performance_reviews_score] CHECK ([score] BETWEEN 1 AND 5),
    CONSTRAINT [CK_performance_reviews_rating] CHECK ([rating] IN ('exceeds_expectations', 'meets_expectations', 'below_expectations', 'needs_improvement'))
)
