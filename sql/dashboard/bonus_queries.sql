
SELECT COUNT(*) AS total_streams FROM streaming_history;

SELECT COUNT(*) AS active_subscriptions
FROM subscriptions WHERE is_active = TRUE;

SELECT COALESCE(SUM(price), 0) AS mrr_estimate
FROM subscriptions WHERE is_active = TRUE;

SELECT s.title AS song_title, COUNT(*) AS stream_events
FROM streaming_history h
JOIN songs s ON h.song_id = s.song_id
GROUP BY s.song_id, s.title
ORDER BY stream_events DESC
LIMIT 15;

SELECT plan_type,
       COUNT(*) AS subscriber_rows,
       SUM(price) AS plan_revenue
FROM subscriptions
WHERE is_active = TRUE
GROUP BY plan_type
ORDER BY plan_revenue DESC;

SELECT date_trunc('month', streamed_at)::date AS month,
       COUNT(*) AS streams
FROM streaming_history
GROUP BY 1
ORDER BY 1;

SELECT g.name AS genre_name, COUNT(*) AS stream_events
FROM streaming_history h
JOIN songs s ON h.song_id = s.song_id
JOIN song_genres sg ON s.song_id = sg.song_id
JOIN genres g ON sg.genre_id = g.genre_id
GROUP BY g.genre_id, g.name
ORDER BY stream_events DESC
LIMIT 12;
