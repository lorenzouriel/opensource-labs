-- Classification: Internal (no personal data). Retention: indefinite (reference data).
CREATE TABLE [master_data].[fx_rates]
(
    [base_currency]   CHAR(3)        NOT NULL,
    [quote_currency]  CHAR(3)        NOT NULL,
    [rate_date]       DATE           NOT NULL,
    [rate]            DECIMAL(18,8)  NOT NULL,
    CONSTRAINT [PK_fx_rates] PRIMARY KEY CLUSTERED ([base_currency], [quote_currency], [rate_date])
)
