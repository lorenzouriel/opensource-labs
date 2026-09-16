-- Classification: Confidential (tied to tickets). Retention: 3 years.
CREATE TABLE [support].[ticket_messages]
(
    [id]                UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_ticket_messages_id] DEFAULT NEWSEQUENTIALID(),
    [ticket_id]         UNIQUEIDENTIFIER NOT NULL,
    [sender_type]       VARCHAR(10)      NOT NULL,
    [sender_id]         UNIQUEIDENTIFIER NOT NULL, -- tickets.customer_id or tickets.agent_id depending on sender_type; not populated for bot/system, so no single FK target
    [body]              NVARCHAR(MAX)    NOT NULL,
    [created_at]        DATETIME2(0)     NOT NULL,
    [is_internal_note]  BIT              NOT NULL CONSTRAINT [DF_ticket_messages_is_internal_note] DEFAULT (0),
    CONSTRAINT [PK_ticket_messages] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_ticket_messages_tickets] FOREIGN KEY ([ticket_id]) REFERENCES [support].[tickets] ([id]),
    CONSTRAINT [CK_ticket_messages_sender_type] CHECK ([sender_type] IN ('customer', 'agent', 'bot', 'system'))
)
