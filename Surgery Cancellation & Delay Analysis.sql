USE Hospital_Operations;
GO

-- Surgery Status Overview
SELECT 
    Status,
    COUNT(*) as Count,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Surgeries) AS DECIMAL(5,2)) as Percentage
FROM Surgeries
GROUP BY Status
ORDER BY Count DESC;

-- Cancellation/Delay Reasons
SELECT 
    DelayReason,
    COUNT(*) as Count,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Surgeries WHERE DelayReason IS NOT NULL) AS DECIMAL(5,2)) as Percentage
FROM Surgeries
WHERE DelayReason IS NOT NULL
GROUP BY DelayReason
ORDER BY Count DESC;

-- Department-wise Surgery Performance
SELECT 
    Department,
    COUNT(*) as TotalSurgeries,
    SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) as OnTimeCompletions,
    SUM(CASE WHEN Status = 'Completed-Delayed' THEN 1 ELSE 0 END) as DelayedCompletions,
    SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) as Cancellations,
    CAST(SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as CancellationRate
FROM Surgeries
GROUP BY Department
ORDER BY Cancellations DESC;

-- Average Delay Duration
SELECT 
    Department,
    AVG(DATEDIFF(DAY, ScheduledDate, ActualDate)) as AvgDelayDays,
    MAX(DATEDIFF(DAY, ScheduledDate, ActualDate)) as MaxDelayDays
FROM Surgeries
WHERE Status = 'Completed-Delayed'
GROUP BY Department
ORDER BY AvgDelayDays DESC;

-- Revenue Impact Calculation
SELECT 
    SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) as CancelledSurgeries,
    SUM(CASE WHEN Status = 'Cancelled' AND DelayReason = 'Bed Unavailable' THEN 1 ELSE 0 END) as BedRelatedCancellations,
    SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) * 150000 as TotalRevenueLoss,
    SUM(CASE WHEN Status = 'Cancelled' AND DelayReason = 'Bed Unavailable' THEN 1 ELSE 0 END) * 150000 as BedRelatedRevenueLoss
FROM Surgeries;

-- Monthly Trend of Cancellations
SELECT 
    YEAR(ScheduledDate) as Year,
    MONTH(ScheduledDate) as Month,
    COUNT(*) as TotalSurgeries,
    SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) as Cancellations,
    CAST(SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as CancellationRate
FROM Surgeries
GROUP BY YEAR(ScheduledDate), MONTH(ScheduledDate)
ORDER BY Year, Month;

-- Summary
SELECT 'Total Surgeries' as Metric, CAST(COUNT(*) as VARCHAR) as Value FROM Surgeries
UNION ALL
SELECT 'Cancellations', 
    CAST(SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) as VARCHAR) + ' (' +
    CAST(CAST(SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,1)) as VARCHAR) + '%)'
FROM Surgeries
UNION ALL
SELECT 'Estimated Revenue Loss',
    '₹' + CAST(SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) * 150000 / 10000000.0 as VARCHAR) + ' Cr'
FROM Surgeries;