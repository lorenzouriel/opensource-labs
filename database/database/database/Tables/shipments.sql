-- Classification: Internal. Retention: 5 years (aligned to fiscal retention for consistency
-- with orders/invoices).
CREATE TABLE [supply_chain].[shipments]
(
    [id]               UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_shipments_id] DEFAULT NEWSEQUENTIALID(),
    [order_id]         UNIQUEIDENTIFIER NOT NULL,
    [warehouse_id]     UNIQUEIDENTIFIER NOT NULL,
    [carrier]          VARCHAR(20)      NOT NULL,
    [tracking_number]  VARCHAR(40)      NOT NULL,
    [status]           VARCHAR(20)      NOT NULL, -- terminal state from ShipmentTracking
    [weight_kg]        DECIMAL(10,3)    NOT NULL,
    [created_at]       DATE             NOT NULL,
    [delivered_at]     DATE             NULL, -- only when status = 'delivered' and within profile range
    CONSTRAINT [PK_shipments] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_shipments_orders] FOREIGN KEY ([order_id]) REFERENCES [sales].[orders] ([id]),
    CONSTRAINT [FK_shipments_warehouses] FOREIGN KEY ([warehouse_id]) REFERENCES [master_data].[warehouses] ([id]),
    CONSTRAINT [CK_shipments_carrier] CHECK ([carrier] IN ('Correios', 'DHL', 'FedEx', 'UPS', 'Rappi', 'Loggi')),
    CONSTRAINT [CK_shipments_status] CHECK ([status] IN ('created', 'picked_up', 'in_transit', 'delayed', 'out_for_delivery', 'failed_delivery', 'delivered', 'returned_to_sender', 'cancelled'))
)
