-- True Session-Based Funnel Analysis
-- Counts sessions that progressed through each funnel step

WITH session_events AS (

  -- Creating one row per session and identifying the highest funnel step reached by the session    
  SELECT
    CONCAT(
      user_pseudo_id,
      CAST(
        (
          SELECT value.int_value
          FROM UNNEST(event_params)
          WHERE key = 'ga_session_id'
        ) AS STRING
      )
    ) AS session_id,

    MAX(
      CASE event_name
        WHEN 'session_start'  THEN 1
        WHEN 'page_view'      THEN 2
        WHEN 'view_item'      THEN 3
        WHEN 'add_to_cart'    THEN 4
        WHEN 'begin_checkout' THEN 5
        WHEN 'purchase'       THEN 6
        ELSE 0
      END
    ) AS max_step

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name IN (
      'session_start',
      'page_view',
      'view_item',
      'add_to_cart',
      'begin_checkout',
      'purchase'
    )

  GROUP BY
    session_id

),

funnel_counts AS (

  -- Counting number of sessions that reached each funnel stage
  SELECT
    1 AS funnel_step,
    'session_start' AS step_name,
    COUNTIF(max_step >= 1) AS sessions_at_step
  FROM session_events

  UNION ALL

  SELECT
    2,
    'page_view',
    COUNTIF(max_step >= 2)
  FROM session_events

  UNION ALL

  SELECT
    3,
    'view_item',
    COUNTIF(max_step >= 3)
  FROM session_events

  UNION ALL

  SELECT
    4,
    'add_to_cart',
    COUNTIF(max_step >= 4)
  FROM session_events

  UNION ALL

  SELECT
    5,
    'begin_checkout',
    COUNTIF(max_step >= 5)
  FROM session_events

  UNION ALL

  SELECT
    6,
    'purchase',
    COUNTIF(max_step >= 6)
  FROM session_events

)

SELECT
  funnel_step,
  step_name,
  sessions_at_step,

  LAG(sessions_at_step) OVER (ORDER BY funnel_step) AS sessions_prev_step,

  LAG(sessions_at_step) OVER (ORDER BY funnel_step)
    - sessions_at_step AS dropped_off,

  ROUND(
    sessions_at_step * 100.0 /
    NULLIF(
      LAG(sessions_at_step) OVER (ORDER BY funnel_step),
      0
    ),
    2
  ) AS step_conversion_rate_pct,

  ROUND(
    sessions_at_step * 100.0 /
    FIRST_VALUE(sessions_at_step) OVER (ORDER BY funnel_step),
    2
  ) AS overall_conversion_rate_pct

FROM funnel_counts

ORDER BY funnel_step;