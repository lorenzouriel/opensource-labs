-- Classification: Restricted. Retention: 5 years (fiscal/financial record-keeping obligation).
CREATE TABLE [finance].[transactions]
(
    [id]            UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_transactions_id] DEFAULT NEWSEQUENTIALID(),
    [type]          VARCHAR(10)      NOT NULL,
    [amount]        DECIMAL(12,2)    NOT NULL,
    [currency]      CHAR(3)          NOT NULL, -- random per row, same caveat as invoices.currency
    [from_account]  VARCHAR(20)      NOT NULL, -- synthetic ACC-#### ledger code, not linked to any other table
    [to_account]    VARCHAR(20)      NOT NULL, -- synthetic ACC-#### ledger code, not linked to any other table
    [created_at]    DATETIME2(0)     NOT NULL,
    [status]        VARCHAR(10)      NOT NULL,
    [reference]     VARCHAR(20)      NOT NULL, -- synthetic TXN-######
    CONSTRAINT [PK_transactions] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [CK_transactions_type] CHECK ([type] IN ('sale', 'refund', 'adjustment', 'fee', 'transfer')),
    CONSTRAINT [CK_transactions_status] CHECK ([status] IN ('completed', 'pending', 'failed'))
)
