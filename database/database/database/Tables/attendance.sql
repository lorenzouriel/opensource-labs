-- Classification: Confidential. Retention: employment + 5 years (same basis as employees).
CREATE TABLE [hr].[attendance]
(
    [id]            UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_attendance_id] DEFAULT NEWSEQUENTIALID(),
    [employee_id]   UNIQUEIDENTIFIER NOT NULL,
    [date]          DATE             NOT NULL, -- weekday-only (Mon-Fri)
    [check_in]      TIME(0)          NULL, -- only set for present/remote
    [check_out]     TIME(0)          NULL, -- only set for present/remote
    [status]        VARCHAR(10)      NOT NULL,
    [hours_worked]  DECIMAL(4,2)     NOT NULL,
    [overtime_h]    DECIMAL(4,2)     NOT NULL CONSTRAINT [DF_attendance_overtime_h] DEFAULT (0),
    CONSTRAINT [PK_attendance] PRIMARY KEY CLUSTERED ([id]),
    CONSTRAINT [FK_attendance_employees] FOREIGN KEY ([employee_id]) REFERENCES [master_data].[employees] ([id]),
    CONSTRAINT [CK_attendance_status] CHECK ([status] IN ('present', 'absent', 'late', 'remote', 'holiday', 'sick_leave'))
)
