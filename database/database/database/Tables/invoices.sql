-- Classification: Restricted. Retention: 5 years (fiscal/financial record-keeping obligation).
CREATE TABLE [finance].[invoices]
(
    [id]              UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_invoices_id] DEFAULT NEWSEQUENTIALID(),
    [order_id]        UNIQUEIDENTIFIER NOT NULL, -- sampled independently at the source; not guaranteed 1:1 with a real order, so no FK
    [customer_id]     UNIQUEIDENTIFIER NOT NULL,
    [amount]          DECIMAL(12,2)    NOT NULL,
    [currency]        CHAR(3)          NOT NULL, -- random per row, not derived from customer_id's actual country
    [issued_at]       DATE             NOT NULL,
    [due_at]          DATE             NOT NULL, -- issued_at + 30 days
    [status]          VARCHAR(10)      NOT NULL,
    [payment_method]  VARCHAR(15)      NOT NULL,
    CONSTRAINT [PK_invoices] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_invoices_customers] FOREIGN KEY ([customer_id]) REFERENCES [master_data].[customers] ([id]),
    CONSTRAINT [CK_invoices_status] CHECK ([status] IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
    CONSTRAINT [CK_invoices_payment_method] CHECK ([payment_method] IN ('credit_card', 'pix', 'boleto', 'rcd_card'))
)
