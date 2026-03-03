USE Hospital_Operations;
GO

-- ER Wait Time Analysis
WITH ER_Times AS (
    SELECT 
        VisitID,
        PatientID,
        Severity,
        Disposition,
        DATEDIFF(MINUTE, ArrivalTime, TriageTime) as TriageWaitMinutes,
        DATEDIFF(MINUTE, TriageTime, BedAssignmentTime) as BedWaitMinutes,
        DATEDIFF(MINUTE, ArrivalTime, BedAssignmentTime) as TotalWaitMinutes
    FROM ER_Visits
)
SELECT 
    Severity,
    COUNT(*) as TotalVisits,
    AVG(TriageWaitMinutes) as AvgTriageWait_Minutes,
    AVG(BedWaitMinutes) as AvgBedWait_Minutes,
    AVG(TotalWaitMinutes) as AvgTotalWait_Minutes,
    AVG(TotalWaitMinutes) / 60.0 as AvgTotalWait_Hours,
    MAX(TotalWaitMinutes) / 60.0 as MaxWait_Hours
FROM ER_Times
GROUP BY Severity
ORDER BY AvgTotalWait_Minutes DESC;

-- Hourly ER Arrivals (Peak Hours)
SELECT 
    DATEPART(HOUR, ArrivalTime) as Hour,
    COUNT(*) as Arrivals,
    AVG(DATEDIFF(MINUTE, ArrivalTime, BedAssignmentTime)) as AvgWaitMinutes
FROM ER_Visits
GROUP BY DATEPART(HOUR, ArrivalTime)
ORDER BY Arrivals DESC;

-- Disposition Analysis
SELECT 
    Disposition,
    COUNT(*) as Count,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ER_Visits) AS DECIMAL(5,2)) as Percentage,
    AVG(DATEDIFF(MINUTE, ArrivalTime, BedAssignmentTime)) / 60.0 as AvgWaitHours
FROM ER_Visits
GROUP BY Disposition
ORDER BY Count DESC;

-- Critical Patients with High Wait Times
SELECT TOP 100
    VisitID,
    PatientID,
    Severity,
    DATEDIFF(MINUTE, ArrivalTime, BedAssignmentTime) as TotalWaitMinutes,
    DATEDIFF(MINUTE, ArrivalTime, BedAssignmentTime) / 60.0 as TotalWaitHours,
    Disposition
FROM ER_Visits
WHERE Severity IN ('High', 'Critical')
    AND DATEDIFF(MINUTE, ArrivalTime, BedAssignmentTime) > 240
ORDER BY TotalWaitMinutes DESC;

-- Summary: Key Bottleneck Metrics
SELECT 'Average ER Wait Time' as Metric,
    CAST(AVG(DATEDIFF(MINUTE, ArrivalTime, BedAssignmentTime)) / 60.0 as VARCHAR) + ' hours' as Value
FROM ER_Visits
UNION ALL
SELECT 'Visits with >6 Hour Wait',
    CAST(COUNT(*) as VARCHAR) + ' (' + 
    CAST(CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ER_Visits) AS DECIMAL(5,1)) as VARCHAR) + '%)'
FROM ER_Visits
WHERE DATEDIFF(MINUTE, ArrivalTime, BedAssignmentTime) > 360
UNION ALL
SELECT 'Peak Hour',
    (SELECT TOP 1 CAST(DATEPART(HOUR, ArrivalTime) as VARCHAR) + ':00'
     FROM ER_Visits
     GROUP BY DATEPART(HOUR, ArrivalTime)
     ORDER BY COUNT(*) DESC);
