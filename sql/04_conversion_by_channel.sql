-- Combining acquisition source with purchase behavior

WITH session_channel AS (
  -- Getting channel for each session (from session_start event)
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    COALESCE(traffic_source.medium, '(none)') AS channel
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name = 'session_start'
),

purchase_data AS (
  -- Getting revenue from purchase events
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,

    -- Extracting revenue from event parameters
    (SELECT value.double_value FROM UNNEST(event_params) WHERE key = 'value') AS revenue

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name = 'purchase'
)

-- Joining channel data with purchase data
SELECT
  sc.channel,
  COUNT(DISTINCT sc.user_pseudo_id) AS total_users,
  COUNT(DISTINCT sc.session_id) AS total_sessions,
  COUNT(DISTINCT pd.session_id) AS converting_sessions,

  -- Calculating conversion rate per channel
  ROUND(
    COUNT(DISTINCT pd.session_id) * 100.0 /
    NULLIF(COUNT(DISTINCT sc.session_id), 0),
  2) AS conversion_rate_pct,

  -- Calculating total revenue from this channel
  ROUND(SUM(pd.revenue), 2) AS total_revenue,

  -- Calculating revenue per session
  ROUND(SUM(pd.revenue) / NULLIF(COUNT(DISTINCT sc.session_id), 0), 2) AS revenue_per_session

FROM
  session_channel sc

  -- LEFT JOINing to purchase data keeps all sessions, even those without a purchase
  LEFT JOIN purchase_data pd
    ON sc.user_pseudo_id = pd.user_pseudo_id
    AND sc.session_id = pd.session_id

GROUP BY
  sc.channel

ORDER BY
  total_revenue DESC;