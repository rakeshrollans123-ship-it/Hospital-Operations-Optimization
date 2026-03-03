USE Hospital_Operations;
GO

-- Bed Utilization by Department
WITH Occupancy_Stats AS (
    SELECT 
        b.Department,
        COUNT(DISTINCT b.BedID) as TotalBeds,
        COUNT(DISTINCT bo.BedID) as OccupiedBeds,
        CAST(COUNT(DISTINCT bo.BedID) * 100.0 / COUNT(DISTINCT b.BedID) AS DECIMAL(5,2)) as OccupancyRate
    FROM Beds b
    LEFT JOIN Bed_Occupancy bo ON b.BedID = bo.BedID
    GROUP BY b.Department
)
SELECT 
    Department,
    TotalBeds,
    OccupiedBeds,
    OccupancyRate as OccupancyPercentage,
    CASE 
        WHEN OccupancyRate > 95 THEN 'Overbooked - Add Beds'
        WHEN OccupancyRate < 65 THEN 'Underutilized - Reallocate'
        ELSE 'Optimal'
    END as Status
FROM Occupancy_Stats
ORDER BY OccupancyRate DESC;

-- Occupancy by Hour of Day (Peak Analysis)
SELECT 
    DATEPART(HOUR, CAST(Date as DATETIME)) as Hour,
    COUNT(*) as OccupiedBeds,
    AVG(OccupiedHours) as AvgOccupiedHours
FROM Bed_Occupancy
GROUP BY DATEPART(HOUR, CAST(Date as DATETIME))
ORDER BY Hour;

-- Monthly Occupancy Trend
SELECT 
    YEAR(Date) as Year,
    MONTH(Date) as Month,
    COUNT(DISTINCT BedID) as OccupiedBeds,
    COUNT(*) as TotalOccupancyDays
FROM Bed_Occupancy
GROUP BY YEAR(Date), MONTH(Date)
ORDER BY Year, Month;

-- Summary Statistics
SELECT 
    'Total Beds' as Metric,
    CAST(COUNT(*) as VARCHAR) as Value
FROM Beds
UNION ALL
SELECT 
    'Avg Occupancy Rate',
    CAST(CAST(COUNT(DISTINCT bo.BedID) * 100.0 / (SELECT COUNT(*) FROM Beds) AS DECIMAL(5,2)) as VARCHAR) + '%'
FROM Bed_Occupancy bo
UNION ALL
SELECT 
    'Beds Needing Reallocation',
    CAST(SUM(CASE WHEN OccupancyRate < 65 OR OccupancyRate > 95 THEN TotalBeds ELSE 0 END) as VARCHAR)
FROM (
    SELECT 
        Department,
        COUNT(DISTINCT b.BedID) as TotalBeds,
        CAST(COUNT(DISTINCT bo.BedID) * 100.0 / COUNT(DISTINCT b.BedID) AS DECIMAL(5,2)) as OccupancyRate
    FROM Beds b
    LEFT JOIN Bed_Occupancy bo ON b.BedID = bo.BedID
    GROUP BY b.Department

) x;
