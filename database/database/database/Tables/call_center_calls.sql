-- Classification: Confidential (metadata), 3 years. recording_url is Restricted — delete the
-- audio file at 180 days even if the row (sans URL) is kept for the 3-year metadata window.
CREATE TABLE [support].[call_center_calls]
(
    [id]             UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_call_center_calls_id] DEFAULT NEWSEQUENTIALID(),
    [customer_id]    UNIQUEIDENTIFIER NOT NULL,
    [agent_id]       UNIQUEIDENTIFIER NOT NULL,
    [duration_s]     INT              NOT NULL,
    [direction]      VARCHAR(10)      NOT NULL,
    [call_type]      VARCHAR(10)      NOT NULL,
    [sentiment]      VARCHAR(10)      NOT NULL,
    [resolution]     VARCHAR(15)      NOT NULL,
    [created_at]     DATETIME2(0)     NOT NULL,
    [recording_url]  NVARCHAR(300)    NULL, -- Restricted; ~70% of calls; 180-day retention independent of the row
    [wait_time_s]    INT              NOT NULL,
    CONSTRAINT [PK_call_center_calls] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_call_center_calls_customers] FOREIGN KEY ([customer_id]) REFERENCES [master_data].[customers] ([id]),
    CONSTRAINT [FK_call_center_calls_employees] FOREIGN KEY ([agent_id]) REFERENCES [master_data].[employees] ([id]),
    CONSTRAINT [CK_call_center_calls_direction] CHECK ([direction] IN ('inbound', 'outbound')),
    CONSTRAINT [CK_call_center_calls_call_type] CHECK ([call_type] IN ('inbound', 'outbound', 'callback')),
    CONSTRAINT [CK_call_center_calls_sentiment] CHECK ([sentiment] IN ('positive', 'neutral', 'negative')),
    CONSTRAINT [CK_call_center_calls_resolution] CHECK ([resolution] IN ('resolved', 'escalated', 'no_answer', 'voicemail', 'transferred')),
    CONSTRAINT [CK_call_center_calls_duration_s] CHECK ([duration_s] BETWEEN 30 AND 2400),
    CONSTRAINT [CK_call_center_calls_wait_time_s] CHECK ([wait_time_s] BETWEEN 10 AND 600)
)
