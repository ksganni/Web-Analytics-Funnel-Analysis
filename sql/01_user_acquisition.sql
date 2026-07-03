-- Understanding which channels bring users to the site

-- Counting distinct users, sessions, and new users per traffic channel
SELECT
  -- Traffic source channel grouping (e.g., Organic Search, Paid, Direct)
  COALESCE(traffic_source.medium, '(none)') AS channel,

  -- Counting unique visitors
  COUNT(DISTINCT user_pseudo_id) AS total_users,

  -- Counting total sessions (each visit = one session)
  COUNT(
    DISTINCT CONCAT(
      user_pseudo_id,
      CAST(
        (SELECT value.int_value
         FROM UNNEST(event_params)
         WHERE key = 'ga_session_id') AS STRING
      )
    )
  ) AS total_sessions,

  -- Counting users who visited for the first time
  COUNT(DISTINCT CASE
    WHEN (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') = 1
    THEN user_pseudo_id
  END) AS new_users,

  -- Calculating returning users
  COUNT(DISTINCT user_pseudo_id) -
  COUNT(DISTINCT CASE
    WHEN (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') = 1
    THEN user_pseudo_id
  END) AS returning_users,

  -- Calculating percentage of new users
  ROUND(
    COUNT(DISTINCT CASE
      WHEN (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') = 1
      THEN user_pseudo_id
    END) * 100.0 / NULLIF(COUNT(DISTINCT user_pseudo_id), 0),
  2) AS new_user_pct

FROM
  -- Using the public Google Analytics sample dataset in BigQuery
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
  -- Filtering to one month of data (November 2020 is available in this dataset)
  _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'

GROUP BY
  channel

ORDER BY
  total_users DESC;