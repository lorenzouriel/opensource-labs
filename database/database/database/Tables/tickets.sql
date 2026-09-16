-- Classification: Confidential. Retention: 3 years (covers most consumer-protection complaint windows).
CREATE TABLE [support].[tickets]
(
    [id]           UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_tickets_id] DEFAULT NEWSEQUENTIALID(),
    [customer_id]  UNIQUEIDENTIFIER NOT NULL,
    [channel]      VARCHAR(15)      NOT NULL,
    [category]     VARCHAR(20)      NOT NULL,
    [subject]      NVARCHAR(200)    NOT NULL,
    [status]       VARCHAR(20)      NOT NULL, -- terminal state from TicketLifecycle, crisis-aware
    [priority]     VARCHAR(10)      NOT NULL,
    [sentiment]    VARCHAR(10)      NOT NULL, -- forced 'negative' on crisis days
    [created_at]   DATETIME2(0)     NOT NULL,
    [resolved_at]  DATETIME2(0)     NULL, -- only when status = 'closed'
    [csat_score]   TINYINT          NULL, -- only when closed
    [agent_id]     UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_tickets] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_tickets_customers] FOREIGN KEY ([customer_id]) REFERENCES [master_data].[customers] ([id]),
    CONSTRAINT [FK_tickets_employees] FOREIGN KEY ([agent_id]) REFERENCES [master_data].[employees] ([id]),
    CONSTRAINT [CK_tickets_channel] CHECK ([channel] IN ('email', 'chat', 'phone', 'social_media', 'app')),
    CONSTRAINT [CK_tickets_category] CHECK ([category] IN ('order_issue', 'delivery_problem', 'product_defect', 'billing', 'account_access', 'returns_refunds', 'technical_support', 'general_inquiry')),
    CONSTRAINT [CK_tickets_status] CHECK ([status] IN ('open', 'in_progress', 'waiting_customer', 'escalated', 'resolved', 'closed')),
    CONSTRAINT [CK_tickets_priority] CHECK ([priority] IN ('low', 'medium', 'high', 'critical')),
    CONSTRAINT [CK_tickets_sentiment] CHECK ([sentiment] IN ('positive', 'neutral', 'negative')),
    CONSTRAINT [CK_tickets_csat_score] CHECK ([csat_score] IS NULL OR [csat_score] BETWEEN 1 AND 5)
)
