-- Classification: Confidential. Retention: employment + 5 years. Should be reported in
-- aggregate wherever possible to reduce individual-level exposure.
CREATE TABLE [hr].[engagement_surveys]
(
    [id]                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_engagement_surveys_id] DEFAULT NEWSEQUENTIALID(),
    [employee_id]         UNIQUEIDENTIFIER NOT NULL, -- sampled with replacement, up to 2,000 responses
    [period]              VARCHAR(10)      NOT NULL,
    [engagement_score]    DECIMAL(3,2)     NOT NULL,
    [satisfaction_score]  DECIMAL(3,2)     NOT NULL,
    [nps]                 SMALLINT         NOT NULL,
    [would_recommend]     BIT              NOT NULL,
    [submitted_at]        DATE             NOT NULL,
    CONSTRAINT [PK_engagement_surveys] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_engagement_surveys_employees] FOREIGN KEY ([employee_id]) REFERENCES [master_data].[employees] ([id]),
    CONSTRAINT [CK_engagement_surveys_engagement_score] CHECK ([engagement_score] BETWEEN 1 AND 5),
    CONSTRAINT [CK_engagement_surveys_satisfaction_score] CHECK ([satisfaction_score] BETWEEN 1 AND 5),
    CONSTRAINT [CK_engagement_surveys_nps] CHECK ([nps] BETWEEN -100 AND 100)
)
