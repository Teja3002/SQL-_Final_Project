-- ============================================================================
-- Music Streaming Platform Database
-- CSE 4/560 Data Models and Query Language - Semester Project
-- Data Loading Script
-- ============================================================================

-- IMPORTANT: Before running this script:
-- 1. Create the database: CREATE DATABASE music_streaming;
-- 2. Connect to the database: \c music_streaming
-- 3. Run create.sql to create the schema
-- 4. Update the file paths below to match your system

-- Temporarily disable triggers for faster loading
ALTER TABLE streaming_history DISABLE TRIGGER trg_increment_play_count;
ALTER TABLE playlist_songs DISABLE TRIGGER trg_update_playlist_timestamp;

-- ============================================================================
-- Load Users
-- ============================================================================
COPY users(user_id, email, username, password_hash, first_name, last_name, 
           date_of_birth, country, created_at, is_active)
FROM 'C:\\Users\\Teja Krishna\\Desktop\\New folder\\MusicStreamingDB\\data\\users.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- ============================================================================
-- Load Artists
-- ============================================================================
COPY artists(artist_id, name, bio, country, formed_year, monthly_listeners, 
             verified, created_at)
FROM 'C:/Users/Teja Krishna/Desktop/New folder/MusicStreamingDB/data/artists.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- ============================================================================
-- Load Albums
-- ============================================================================
COPY albums(album_id, artist_id, title, release_date, album_type, total_tracks,
            duration_seconds, cover_image_url)
FROM 'C:/Users/Teja Krishna/Desktop/New folder/MusicStreamingDB/data/albums.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- ============================================================================
-- Load Songs
-- ============================================================================
COPY songs(song_id, album_id, title, track_number, duration_seconds, explicit,
           play_count, release_date)
FROM 'C:/Users/Teja Krishna/Desktop/New folder/MusicStreamingDB/data/songs.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- ============================================================================
-- Load Genres
-- ============================================================================
COPY genres(genre_id, name, description)
FROM 'C:/Users/Teja Krishna/Desktop/New folder/MusicStreamingDB/data/genres.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- ============================================================================
-- Load Song Genres
-- ============================================================================
COPY song_genres(song_id, genre_id)
FROM 'C:/Users/Teja Krishna/Desktop/New folder/MusicStreamingDB/data/song_genres.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- ============================================================================
-- Load Playlists
-- ============================================================================
COPY playlists(playlist_id, user_id, name, description, is_public, created_at, updated_at)
FROM 'C:/Users/Teja Krishna/Desktop/New folder/MusicStreamingDB/data/playlists.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- ============================================================================
-- Load Playlist Songs
-- ============================================================================
COPY playlist_songs(playlist_id, song_id, added_at, position)
FROM 'C:/Users/Teja Krishna/Desktop/New folder/MusicStreamingDB/data/playlist_songs.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- ============================================================================
-- Load Streaming History
-- ============================================================================
COPY streaming_history(stream_id, user_id, song_id, streamed_at, duration_played, device_type)
FROM 'C:/Users/Teja Krishna/Desktop/New folder/MusicStreamingDB/data/streaming_history.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- ============================================================================
-- Load Subscriptions
-- ============================================================================
COPY subscriptions(subscription_id, user_id, plan_type, start_date, end_date, 
                   price, is_active, payment_method)
FROM 'C:/Users/Teja Krishna/Desktop/New folder/MusicStreamingDB/data/subscriptions.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

-- ============================================================================
-- Re-enable triggers
-- ============================================================================
ALTER TABLE streaming_history ENABLE TRIGGER trg_increment_play_count;
ALTER TABLE playlist_songs ENABLE TRIGGER trg_update_playlist_timestamp;

-- ============================================================================
-- Reset sequences to max values
-- ============================================================================
SELECT setval('users_user_id_seq', (SELECT MAX(user_id) FROM users));
SELECT setval('artists_artist_id_seq', (SELECT MAX(artist_id) FROM artists));
SELECT setval('albums_album_id_seq', (SELECT MAX(album_id) FROM albums));
SELECT setval('songs_song_id_seq', (SELECT MAX(song_id) FROM songs));
SELECT setval('genres_genre_id_seq', (SELECT MAX(genre_id) FROM genres));
SELECT setval('playlists_playlist_id_seq', (SELECT MAX(playlist_id) FROM playlists));
SELECT setval('streaming_history_stream_id_seq', (SELECT MAX(stream_id) FROM streaming_history));
SELECT setval('subscriptions_subscription_id_seq', (SELECT MAX(subscription_id) FROM subscriptions));

-- ============================================================================
-- Verification Queries
-- ============================================================================
SELECT 'Data Loading Complete!' AS status;

SELECT 'Record Counts:' AS info;
SELECT 'users' AS table_name, COUNT(*) AS record_count FROM users
UNION ALL SELECT 'artists', COUNT(*) FROM artists
UNION ALL SELECT 'albums', COUNT(*) FROM albums
UNION ALL SELECT 'songs', COUNT(*) FROM songs
UNION ALL SELECT 'genres', COUNT(*) FROM genres
UNION ALL SELECT 'song_genres', COUNT(*) FROM song_genres
UNION ALL SELECT 'playlists', COUNT(*) FROM playlists
UNION ALL SELECT 'playlist_songs', COUNT(*) FROM playlist_songs
UNION ALL SELECT 'streaming_history', COUNT(*) FROM streaming_history
UNION ALL SELECT 'subscriptions', COUNT(*) FROM subscriptions
ORDER BY table_name;

SELECT 'Total Records:' AS info, 
       (SELECT COUNT(*) FROM users) +
       (SELECT COUNT(*) FROM artists) +
       (SELECT COUNT(*) FROM albums) +
       (SELECT COUNT(*) FROM songs) +
       (SELECT COUNT(*) FROM genres) +
       (SELECT COUNT(*) FROM song_genres) +
       (SELECT COUNT(*) FROM playlists) +
       (SELECT COUNT(*) FROM playlist_songs) +
       (SELECT COUNT(*) FROM streaming_history) +
       (SELECT COUNT(*) FROM subscriptions) AS total;
