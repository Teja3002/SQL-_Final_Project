-- CSE 4/560 Bonus: SQL used by the Streamlit dashboard (PostgreSQL)
-- Run these against the music_streaming schema after create + load.

-- KPI: total stream events
SELECT COUNT(*) AS total_streams FROM streaming_history;

-- KPI: active subscriptions count
SELECT COUNT(*) AS active_subscriptions
FROM subscriptions WHERE is_active = TRUE;

-- KPI: estimated monthly revenue from active subscriptions (sum of prices)
SELECT COALESCE(SUM(price), 0) AS mrr_estimate
FROM subscriptions WHERE is_active = TRUE;

-- Chart: Top songs by number of stream events
SELECT s.title AS song_title, COUNT(*) AS stream_events
FROM streaming_history h
JOIN songs s ON h.song_id = s.song_id
GROUP BY s.song_id, s.title
ORDER BY stream_events DESC
LIMIT 15;

-- Chart: Revenue and subscriber counts by plan type (active only)
SELECT plan_type,
       COUNT(*) AS subscriber_rows,
       SUM(price) AS plan_revenue
FROM subscriptions
WHERE is_active = TRUE
GROUP BY plan_type
ORDER BY plan_revenue DESC;

-- Chart: Streams per calendar month
SELECT date_trunc('month', streamed_at)::date AS month,
       COUNT(*) AS streams
FROM streaming_history
GROUP BY 1
ORDER BY 1;

-- Chart: Top genres by stream count (many-to-many via song_genres)
SELECT g.name AS genre_name, COUNT(*) AS stream_events
FROM streaming_history h
JOIN songs s ON h.song_id = s.song_id
JOIN song_genres sg ON s.song_id = sg.song_id
JOIN genres g ON sg.genre_id = g.genre_id
GROUP BY g.genre_id, g.name
ORDER BY stream_events DESC
LIMIT 12;
