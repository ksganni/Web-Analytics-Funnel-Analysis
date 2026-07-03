-- Understanding session behavior metrics

WITH session_data AS (
  -- Building one row per session with key metrics
  SELECT
    user_pseudo_id,

    -- Extracting session ID from event parameters
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,

    -- Extracting session start and end timestamps (in microseconds — divide by 1M for seconds)
    MIN(event_timestamp) AS session_start_ts,
    MAX(event_timestamp) AS session_end_ts,

    -- Calculating duration in seconds
    (MAX(event_timestamp) - MIN(event_timestamp)) / 1000000 AS session_duration_seconds,

    -- Counting page views in this session
    COUNTIF(event_name = 'page_view') AS pageviews,

    -- Checking if there was any engagement beyond the first page (bounce = only 1 page viewed)
    CASE WHEN COUNTIF(event_name = 'page_view') <= 1 THEN 1 ELSE 0 END AS is_bounce,

    -- Checking if this session resulted in a purchase
    CASE WHEN COUNTIF(event_name = 'purchase') > 0 THEN 1 ELSE 0 END AS converted

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'

  GROUP BY
    user_pseudo_id, session_id
)

-- Aggregating session metrics
SELECT
  COUNT(*) AS total_sessions,
  ROUND(AVG(session_duration_seconds), 2) AS avg_session_duration_seconds,
  ROUND(AVG(session_duration_seconds) / 60, 2) AS avg_session_duration_minutes,
  ROUND(AVG(pageviews), 2) AS avg_pages_per_session,

  -- Calculating bounce rate = % of sessions where user viewed only 1 page
  ROUND(SUM(is_bounce) * 100.0 / COUNT(*), 2) AS bounce_rate_pct,

  -- Calculating conversion rate = % of sessions that ended in purchase
  ROUND(SUM(converted) * 100.0 / COUNT(*), 2) AS session_conversion_rate_pct,

  -- Calculating total purchases
  SUM(converted) AS total_conversions

FROM
  session_data;