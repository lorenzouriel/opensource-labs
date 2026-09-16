-- Classification: Confidential. Retention: 1 year from decision for non-hires; converts to
-- employees retention on hire. Note: hired candidates are not linked forward into employees —
-- there's no candidate_id/employee_id bridge.
CREATE TABLE [hr].[recruitment_pipeline]
(
    [id]               UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_recruitment_pipeline_id] DEFAULT NEWSEQUENTIALID(),
    [position]         VARCHAR(30)      NOT NULL,
    [department]       VARCHAR(20)      NOT NULL,
    [candidate_name]   NVARCHAR(50)     NOT NULL, -- placeholder synthetic value, not a real name
    [candidate_email]  NVARCHAR(100)    NOT NULL, -- placeholder synthetic value
    [status]           VARCHAR(15)      NOT NULL, -- terminal state from RecruitmentFunnel
    [applied_at]       DATETIME2(0)     NOT NULL,
    [hired_at]         DATETIME2(0)     NULL, -- only when status = 'hired'
    [recruiter_id]     UNIQUEIDENTIFIER NOT NULL,
    [source]           VARCHAR(15)      NOT NULL,
    CONSTRAINT [PK_recruitment_pipeline] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_recruitment_pipeline_employees] FOREIGN KEY ([recruiter_id]) REFERENCES [master_data].[employees] ([id]),
    CONSTRAINT [CK_recruitment_pipeline_position] CHECK ([position] IN ('Software Engineer', 'Data Engineer', 'Product Manager', 'Marketing Analyst', 'Sales Representative', 'Customer Success Manager', 'Supply Chain Analyst', 'HR Business Partner', 'Financial Analyst', 'DevOps Engineer', 'Security Analyst')),
    CONSTRAINT [CK_recruitment_pipeline_department] CHECK ([department] IN ('Engineering', 'Product', 'Data & Analytics', 'Marketing', 'Sales', 'Customer Success', 'Supply Chain', 'Manufacturing', 'Finance', 'HR', 'IT')),
    CONSTRAINT [CK_recruitment_pipeline_status] CHECK ([status] IN ('applied', 'screening', 'interview', 'technical', 'offer', 'hired', 'rejected', 'declined')),
    CONSTRAINT [CK_recruitment_pipeline_source] CHECK ([source] IN ('linkedin', 'referral', 'job_board', 'direct', 'agency'))
)
