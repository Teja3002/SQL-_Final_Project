
\restrict VhJjONtpeWsfF7YVVLg7kAvs5QtofkftJm9uE7Q6mjaQeRssZ5vjWOpERRn4PyW



SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE PROCEDURE public.add_user(IN u_email character varying, IN u_username character varying, IN u_password character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
INSERT INTO users (email, username, password_hash)
VALUES (u_email, u_username, u_password);
END;
$$;


ALTER PROCEDURE public.add_user(IN u_email character varying, IN u_username character varying, IN u_password character varying) OWNER TO postgres;


CREATE PROCEDURE public.delete_user(IN u_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
DELETE FROM users
WHERE user_id = u_id;
END;
$$;


ALTER PROCEDURE public.delete_user(IN u_id integer) OWNER TO postgres;


CREATE FUNCTION public.get_user_streams(u_id integer) RETURNS TABLE(song_title character varying, streamed_at timestamp without time zone)
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


ALTER FUNCTION public.get_user_streams(u_id integer) OWNER TO postgres;


CREATE FUNCTION public.increment_play_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE songs SET play_count = play_count + 1 WHERE song_id = NEW.song_id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.increment_play_count() OWNER TO postgres;


CREATE FUNCTION public.log_insert_attempt() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
INSERT INTO transaction_log (message)
VALUES ('Insert attempted for user: ' || NEW.email);

RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_insert_attempt() OWNER TO postgres;


CREATE FUNCTION public.update_playlist_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE playlists SET updated_at = CURRENT_TIMESTAMP WHERE playlist_id = NEW.playlist_id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_playlist_timestamp() OWNER TO postgres;


CREATE PROCEDURE public.update_subscription(IN u_id integer, IN new_plan character varying, IN new_price numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
UPDATE subscriptions
SET plan_type = new_plan,
    price = new_price
WHERE user_id = u_id;
END;
$$;


ALTER PROCEDURE public.update_subscription(IN u_id integer, IN new_plan character varying, IN new_price numeric) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;


CREATE TABLE public.albums (
    album_id integer NOT NULL,
    artist_id integer NOT NULL,
    title character varying(255) NOT NULL,
    release_date date,
    album_type character varying(20) DEFAULT 'album'::character varying,
    total_tracks integer DEFAULT 0,
    duration_seconds integer DEFAULT 0,
    cover_image_url character varying(500),
    CONSTRAINT chk_album_duration CHECK ((duration_seconds >= 0)),
    CONSTRAINT chk_album_type CHECK (((album_type)::text = ANY ((ARRAY['single'::character varying, 'EP'::character varying, 'album'::character varying, 'compilation'::character varying])::text[]))),
    CONSTRAINT chk_total_tracks CHECK ((total_tracks >= 0))
);


ALTER TABLE public.albums OWNER TO postgres;


CREATE SEQUENCE public.albums_album_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.albums_album_id_seq OWNER TO postgres;


ALTER SEQUENCE public.albums_album_id_seq OWNED BY public.albums.album_id;



CREATE TABLE public.artists (
    artist_id integer NOT NULL,
    name character varying(255) NOT NULL,
    bio text,
    country character varying(100),
    formed_year integer,
    monthly_listeners bigint DEFAULT 0,
    verified boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_formed_year CHECK (((formed_year IS NULL) OR ((formed_year >= 1900) AND ((formed_year)::numeric <= EXTRACT(year FROM CURRENT_DATE))))),
    CONSTRAINT chk_monthly_listeners CHECK ((monthly_listeners >= 0))
);


ALTER TABLE public.artists OWNER TO postgres;


CREATE SEQUENCE public.artists_artist_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.artists_artist_id_seq OWNER TO postgres;


ALTER SEQUENCE public.artists_artist_id_seq OWNED BY public.artists.artist_id;



CREATE TABLE public.genres (
    genre_id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text
);


ALTER TABLE public.genres OWNER TO postgres;


CREATE SEQUENCE public.genres_genre_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.genres_genre_id_seq OWNER TO postgres;


ALTER SEQUENCE public.genres_genre_id_seq OWNED BY public.genres.genre_id;



CREATE TABLE public.playlist_songs (
    playlist_id integer NOT NULL,
    song_id integer NOT NULL,
    added_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "position" integer NOT NULL,
    CONSTRAINT chk_position CHECK (("position" > 0))
);


ALTER TABLE public.playlist_songs OWNER TO postgres;


CREATE TABLE public.playlists (
    playlist_id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    is_public boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_playlist_name CHECK ((length((name)::text) >= 1))
);


ALTER TABLE public.playlists OWNER TO postgres;


CREATE SEQUENCE public.playlists_playlist_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.playlists_playlist_id_seq OWNER TO postgres;


ALTER SEQUENCE public.playlists_playlist_id_seq OWNED BY public.playlists.playlist_id;



CREATE TABLE public.song_genres (
    song_id integer NOT NULL,
    genre_id integer NOT NULL
);


ALTER TABLE public.song_genres OWNER TO postgres;


CREATE TABLE public.songs (
    song_id integer NOT NULL,
    album_id integer NOT NULL,
    title character varying(255) NOT NULL,
    track_number integer,
    duration_seconds integer NOT NULL,
    explicit boolean DEFAULT false,
    play_count bigint DEFAULT 0,
    release_date date,
    CONSTRAINT chk_play_count CHECK ((play_count >= 0)),
    CONSTRAINT chk_song_duration CHECK (((duration_seconds > 0) AND (duration_seconds < 36000))),
    CONSTRAINT chk_track_number CHECK (((track_number IS NULL) OR (track_number > 0)))
);


ALTER TABLE public.songs OWNER TO postgres;


CREATE SEQUENCE public.songs_song_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.songs_song_id_seq OWNER TO postgres;


ALTER SEQUENCE public.songs_song_id_seq OWNED BY public.songs.song_id;



CREATE TABLE public.streaming_history (
    stream_id integer NOT NULL,
    user_id integer NOT NULL,
    song_id integer NOT NULL,
    streamed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    duration_played integer DEFAULT 0,
    device_type character varying(20) DEFAULT 'unknown'::character varying,
    CONSTRAINT chk_device_type CHECK (((device_type)::text = ANY ((ARRAY['mobile'::character varying, 'desktop'::character varying, 'tablet'::character varying, 'smart_tv'::character varying, 'smart_speaker'::character varying, 'web'::character varying, 'unknown'::character varying])::text[]))),
    CONSTRAINT chk_duration_played CHECK ((duration_played >= 0))
);


ALTER TABLE public.streaming_history OWNER TO postgres;


CREATE SEQUENCE public.streaming_history_stream_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.streaming_history_stream_id_seq OWNER TO postgres;


ALTER SEQUENCE public.streaming_history_stream_id_seq OWNED BY public.streaming_history.stream_id;



CREATE TABLE public.subscriptions (
    subscription_id integer NOT NULL,
    user_id integer NOT NULL,
    plan_type character varying(20) NOT NULL,
    start_date date NOT NULL,
    end_date date,
    price numeric(10,2) NOT NULL,
    is_active boolean DEFAULT true,
    payment_method character varying(20),
    CONSTRAINT chk_end_date CHECK (((end_date IS NULL) OR (end_date >= start_date))),
    CONSTRAINT chk_payment_method CHECK (((payment_method IS NULL) OR ((payment_method)::text = ANY ((ARRAY['credit_card'::character varying, 'debit_card'::character varying, 'paypal'::character varying, 'apple_pay'::character varying, 'google_pay'::character varying, 'bank_transfer'::character varying])::text[])))),
    CONSTRAINT chk_plan_type CHECK (((plan_type)::text = ANY ((ARRAY['free'::character varying, 'premium'::character varying, 'family'::character varying, 'student'::character varying, 'duo'::character varying])::text[]))),
    CONSTRAINT chk_price CHECK ((price >= (0)::numeric))
);


ALTER TABLE public.subscriptions OWNER TO postgres;


CREATE SEQUENCE public.subscriptions_subscription_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscriptions_subscription_id_seq OWNER TO postgres;


ALTER SEQUENCE public.subscriptions_subscription_id_seq OWNED BY public.subscriptions.subscription_id;



CREATE TABLE public.transaction_log (
    log_id integer NOT NULL,
    message text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.transaction_log OWNER TO postgres;


CREATE SEQUENCE public.transaction_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transaction_log_log_id_seq OWNER TO postgres;


ALTER SEQUENCE public.transaction_log_log_id_seq OWNED BY public.transaction_log.log_id;



CREATE TABLE public.users (
    user_id integer NOT NULL,
    email character varying(255) NOT NULL,
    username character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    date_of_birth date,
    country character varying(100) DEFAULT 'Unknown'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true,
    CONSTRAINT chk_dob_valid CHECK (((date_of_birth IS NULL) OR (date_of_birth < CURRENT_DATE))),
    CONSTRAINT chk_email_format CHECK (((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text)),
    CONSTRAINT chk_username_length CHECK ((length((username)::text) >= 3))
);


ALTER TABLE public.users OWNER TO postgres;


CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO postgres;


ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;



ALTER TABLE ONLY public.albums ALTER COLUMN album_id SET DEFAULT nextval('public.albums_album_id_seq'::regclass);



ALTER TABLE ONLY public.artists ALTER COLUMN artist_id SET DEFAULT nextval('public.artists_artist_id_seq'::regclass);



ALTER TABLE ONLY public.genres ALTER COLUMN genre_id SET DEFAULT nextval('public.genres_genre_id_seq'::regclass);



ALTER TABLE ONLY public.playlists ALTER COLUMN playlist_id SET DEFAULT nextval('public.playlists_playlist_id_seq'::regclass);



ALTER TABLE ONLY public.songs ALTER COLUMN song_id SET DEFAULT nextval('public.songs_song_id_seq'::regclass);



ALTER TABLE ONLY public.streaming_history ALTER COLUMN stream_id SET DEFAULT nextval('public.streaming_history_stream_id_seq'::regclass);



ALTER TABLE ONLY public.subscriptions ALTER COLUMN subscription_id SET DEFAULT nextval('public.subscriptions_subscription_id_seq'::regclass);



ALTER TABLE ONLY public.transaction_log ALTER COLUMN log_id SET DEFAULT nextval('public.transaction_log_log_id_seq'::regclass);



ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);



ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_pkey PRIMARY KEY (album_id);



ALTER TABLE ONLY public.artists
    ADD CONSTRAINT artists_pkey PRIMARY KEY (artist_id);



ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_name_key UNIQUE (name);



ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (genre_id);



ALTER TABLE ONLY public.playlist_songs
    ADD CONSTRAINT playlist_songs_pkey PRIMARY KEY (playlist_id, song_id);



ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_pkey PRIMARY KEY (playlist_id);



ALTER TABLE ONLY public.song_genres
    ADD CONSTRAINT song_genres_pkey PRIMARY KEY (song_id, genre_id);



ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_pkey PRIMARY KEY (song_id);



ALTER TABLE ONLY public.streaming_history
    ADD CONSTRAINT streaming_history_pkey PRIMARY KEY (stream_id);



ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (subscription_id);



ALTER TABLE ONLY public.transaction_log
    ADD CONSTRAINT transaction_log_pkey PRIMARY KEY (log_id);



ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);



ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);



ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);



CREATE INDEX idx_albums_artist ON public.albums USING btree (artist_id);



CREATE INDEX idx_albums_release_date ON public.albums USING btree (release_date);



CREATE INDEX idx_artists_country ON public.artists USING btree (country);



CREATE INDEX idx_artists_name ON public.artists USING btree (name);



CREATE INDEX idx_playlist_songs_song ON public.playlist_songs USING btree (song_id);



CREATE INDEX idx_playlists_public ON public.playlists USING btree (is_public);



CREATE INDEX idx_playlists_user ON public.playlists USING btree (user_id);



CREATE INDEX idx_ps_playlist ON public.playlist_songs USING btree (playlist_id);



CREATE INDEX idx_ps_song ON public.playlist_songs USING btree (song_id);



CREATE INDEX idx_song_genres_genre ON public.song_genres USING btree (genre_id);



CREATE INDEX idx_songs_album ON public.songs USING btree (album_id);



CREATE INDEX idx_songs_play_count ON public.songs USING btree (play_count DESC);



CREATE INDEX idx_songs_title ON public.songs USING btree (title);



CREATE INDEX idx_stream_song ON public.streaming_history USING btree (song_id);



CREATE INDEX idx_stream_user ON public.streaming_history USING btree (user_id);



CREATE INDEX idx_streaming_date ON public.streaming_history USING btree (streamed_at);



CREATE INDEX idx_streaming_song ON public.streaming_history USING btree (song_id);



CREATE INDEX idx_streaming_user ON public.streaming_history USING btree (user_id);



CREATE INDEX idx_subscriptions_active ON public.subscriptions USING btree (is_active);



CREATE INDEX idx_subscriptions_user ON public.subscriptions USING btree (user_id);



CREATE INDEX idx_users_country ON public.users USING btree (country);



CREATE INDEX idx_users_email ON public.users USING btree (email);



CREATE TRIGGER trg_increment_play_count AFTER INSERT ON public.streaming_history FOR EACH ROW EXECUTE FUNCTION public.increment_play_count();



CREATE TRIGGER trg_log_user_insert BEFORE INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.log_insert_attempt();



CREATE TRIGGER trg_update_playlist_timestamp AFTER INSERT ON public.playlist_songs FOR EACH ROW EXECUTE FUNCTION public.update_playlist_timestamp();



ALTER TABLE ONLY public.albums
    ADD CONSTRAINT fk_albums_artist FOREIGN KEY (artist_id) REFERENCES public.artists(artist_id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY public.playlist_songs
    ADD CONSTRAINT fk_playlist_songs_playlist FOREIGN KEY (playlist_id) REFERENCES public.playlists(playlist_id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY public.playlist_songs
    ADD CONSTRAINT fk_playlist_songs_song FOREIGN KEY (song_id) REFERENCES public.songs(song_id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT fk_playlists_user FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY public.song_genres
    ADD CONSTRAINT fk_song_genres_genre FOREIGN KEY (genre_id) REFERENCES public.genres(genre_id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY public.song_genres
    ADD CONSTRAINT fk_song_genres_song FOREIGN KEY (song_id) REFERENCES public.songs(song_id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY public.songs
    ADD CONSTRAINT fk_songs_album FOREIGN KEY (album_id) REFERENCES public.albums(album_id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY public.streaming_history
    ADD CONSTRAINT fk_streaming_song FOREIGN KEY (song_id) REFERENCES public.songs(song_id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY public.streaming_history
    ADD CONSTRAINT fk_streaming_user FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_subscriptions_user FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;




\unrestrict VhJjONtpeWsfF7YVVLg7kAvs5QtofkftJm9uE7Q6mjaQeRssZ5vjWOpERRn4PyW
