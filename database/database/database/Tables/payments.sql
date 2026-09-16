-- Classification: Restricted. Retention: 5 years (fiscal/financial record-keeping obligation,
-- LGPD Art. 7 II legal-obligation basis).
CREATE TABLE [sales].[payments]
(
    [id]              UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_payments_id] DEFAULT NEWSEQUENTIALID(),
    [order_id]        UNIQUEIDENTIFIER NOT NULL, -- only orders in a paid-or-later status get a payment row
    [method]          VARCHAR(15)      NOT NULL,
    [installments]    INT              NOT NULL CONSTRAINT [DF_payments_installments] DEFAULT (1), -- 1-12 for credit_card, else 1
    [status]          VARCHAR(15)      NOT NULL CONSTRAINT [DF_payments_status] DEFAULT ('approved'), -- always 'approved' at the source today
    [gateway]         VARCHAR(15)      NOT NULL,
    [processing_fee]  DECIMAL(12,2)    NOT NULL, -- 1-3.5% of order total
    [authorized_at]   DATETIME2(0)     NOT NULL,
    [currency]        CHAR(3)          NOT NULL, -- copied from orders.currency
    CONSTRAINT [PK_payments] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_payments_orders] FOREIGN KEY ([order_id]) REFERENCES [sales].[orders] ([id]),
    CONSTRAINT [CK_payments_method] CHECK ([method] IN ('credit_card', 'debit_card', 'pix', 'boleto', 'paypal', 'rcd_card', 'bnpl')),
    CONSTRAINT [CK_payments_installments] CHECK ([installments] BETWEEN 1 AND 12),
    CONSTRAINT [CK_payments_gateway] CHECK ([gateway] IN ('Stripe', 'Cielo', 'PagSeguro', 'MercadoPago', 'PayPal'))
)
