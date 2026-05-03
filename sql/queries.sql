INSERT INTO users (email, username, password_hash)
VALUE ('task5@test.com','taskuser','abc123');

SELECT * FROM users WHERE email = 'task5@test.com';

INSERT INTO playlists (user_id, name, is_public)
VALUES (1, 'Phase2 playlist', TRUE);

SELECT * FROM playlists WHERE name = 'Phase2 playlist';

UPDATE users 
SET username = 'elizabeth_music',
country = 'United States'
WHERE user_id = 3;

SELECT user_id, email, username, country
FROM users
WHERE user_id = 3;

UPDATE subscriptions
SET plan_type = 'premium',
price = 9.99,
is_active = TRUE
WHERE user_id = 5;

SELECT user_id, plan_type, price, is_active
FROM subscriptions WHERE user_id = 5;

SELECT s.title AS song, a.name AS artist, COUNT(*) AS stream_count
FROM streaming_history h
JOIN songs s ON h.song_id = s.song_id 
JOIN albums al ON s.album_id = al.album_id
JOIN artists a ON al.artist_id = a.artist_id 
GROUP BY s.title, a.name
ORDER BY stream_count DESC;

SELECT plan_type, COUNT(*) AS total_users, SUM(price) AS total_revenue
FROM subscriptions
GROUP BY plan_type
ORDER BY total_revenue DESC;

SELECT user_id
FROM streaming_history
GROUP BY user_id
HAVING COUNT(*) >
(
    SELECT AVG(stream_count)
    FROM (
        SELECT COUNT(*) AS stream_count
        FROM streaming_history
        GROUP BY user_id
    )AS sub
);

SELECT p.name AS playlist, s.title AS song, a.name AS artist
FROM playlists p
JOIN playlist_songs ps ON p.playlist_id = ps.playlist_id
JOIN songs s ON ps.song_id = s.song_id
JOIN albums al ON s.album_id = al.album_id
JOIN artists a ON al.artist_id = a.artist_id 
ORDER BY p.name;

CREATE OR REPLACE PROCEDURE add_user(
    u_email VARCHAR,
    u_username VARCHAR,
    u_password VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
INSERT INTO users (email, username, password_hash)
VALUES (u_email, u_username, u_password);
END;
$$;

CALL add_user ('john.doe@test.com','john_doe','pass123')

CREATE OR REPLACE PROCEDURE update_subscription(
    u_id INT,
    new_plan VARCHAR,
    new_price DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
UPDATE subscriptions
SET plan_type = new_plan,
    price = new_price
WHERE user_id = u_id;
END;
$$;

CALL update_subscription(1,'premium',9.99);

CREATE OR REPLACE FUNCTION get_user_streams(u_id INT)
RETURNS TABLE (song_title VARCHAR, streamed_at TIMESTAMP)
LANGUAGE plpgsql
AS $$
BEGIN
RETURN QUERY
SELECT s.title, h.streamed_at
FROM streaming_history h
JOIN songs s ON h.song_id = s.song_id
WHERE h.user_id = u_id;
END;
$$;

SELECT * FROM get_user_streams(1);

CREATE OR REPLACE PROCEDURE delete_user(u_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
DELETE FROM users
WHERE user_id = u_id;
END;
$$;

CALL delete_user(1);


CREATE TABLE translation_log(
    log_id SERIAL PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_insert_attempt()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN 
INSERT INTO transaction_log (message)
VALUES ('Insert attempted for user: ' || NEW.email);

RETURN NEW;
END;
$$;

CREATE TRIGGER trg_log_user_insert
BEFORE INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION log_insert_attempt();

BEGIN;
INSERT INTO users (email,username,password_hash)
VALUES ('duplicate@test.com','user1','abc');
INSERT INTO users (email, username, password_hash)
VALUES ('duplicate@test.com','user2','xyz');
COMMIT;

SELECT * FROM users WHERE email = 'duplicate@test.com';
SELECT * FROM transaction_log;

EXPLAIN ANALYZE
SELECT * 
FROM streaming_history
WHERE user_id = 5;
CREATE INDEX idx_stream_user
ON streaming_history(user_id);
EXPLAIN ANALYZE
SELECT * 
FROM streaming_history
WHERE user_id = 5;

EXPLAIN ANALYZE
SELECT p.name, s.title
FROM playlist_songs ps
JOIN playlists p ON ps.playlist_id = p.playlist_id
JOIN songs s ON ps.song_id = s.song_id;
CREATE INDEX idx_ps_playlist
ON playlist_songs(playlist_id);
CREATE INDEX idx_ps_song
ON playlist_songs(song_id);
EXPLAIN ANALYZE
SELECT p.name, s.title
FROM playlist_songs ps
JOIN playlists p ON ps.playlist_id = p.playlist_id
JOIN songs s ON ps.song_id = s.song_id;

EXPLAIN ANALYZE
SELECT song_id, COUNT(*)
FROM streaming_history
GROUP BY song_id;
CREATE INDEX idx_stream_song
ON streaming_history(song_id);
EXPLAIN ANALYZE
SELECT song_id, COUNT(*)
FROM streaming_history
GROUP BY song_id;
