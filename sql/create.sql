--
-- PostgreSQL database dump
--

\restrict VhJjONtpeWsfF7YVVLg7kAvs5QtofkftJm9uE7Q6mjaQeRssZ5vjWOpERRn4PyW

-- Dumped from database version 18.2
-- Dumped by pg_dump version 18.2

-- Started on 2026-05-02 10:52:59

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

--
-- TOC entry 241 (class 1255 OID 25183)
-- Name: add_user(character varying, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.add_user(IN u_email character varying, IN u_username character varying, IN u_password character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
INSERT INTO users (email, username, password_hash)
VALUES (u_email, u_username, u_password);
END;
$$;


ALTER PROCEDURE public.add_user(IN u_email character varying, IN u_username character varying, IN u_password character varying) OWNER TO postgres;

--
-- TOC entry 244 (class 1255 OID 25187)
-- Name: delete_user(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.delete_user(IN u_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
DELETE FROM users
WHERE user_id = u_id;
END;
$$;


ALTER PROCEDURE public.delete_user(IN u_id integer) OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 25186)
-- Name: get_user_streams(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

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

--
-- TOC entry 240 (class 1255 OID 17213)
-- Name: increment_play_count(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.increment_play_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE songs SET play_count = play_count + 1 WHERE song_id = NEW.song_id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.increment_play_count() OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 25199)
-- Name: log_insert_attempt(); Type: FUNCTION; Schema: public; Owner: postgres
--

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

--
-- TOC entry 239 (class 1255 OID 17211)
-- Name: update_playlist_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_playlist_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE playlists SET updated_at = CURRENT_TIMESTAMP WHERE playlist_id = NEW.playlist_id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_playlist_timestamp() OWNER TO postgres;

--
-- TOC entry 242 (class 1255 OID 25184)
-- Name: update_subscription(integer, character varying, numeric); Type: PROCEDURE; Schema: public; Owner: postgres
--

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

--
-- TOC entry 224 (class 1259 OID 17032)
-- Name: albums; Type: TABLE; Schema: public; Owner: postgres
--

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

--
-- TOC entry 223 (class 1259 OID 17031)
-- Name: albums_album_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.albums_album_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.albums_album_id_seq OWNER TO postgres;

--
-- TOC entry 5174 (class 0 OID 0)
-- Dependencies: 223
-- Name: albums_album_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.albums_album_id_seq OWNED BY public.albums.album_id;


--
-- TOC entry 222 (class 1259 OID 17016)
-- Name: artists; Type: TABLE; Schema: public; Owner: postgres
--

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

--
-- TOC entry 221 (class 1259 OID 17015)
-- Name: artists_artist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.artists_artist_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.artists_artist_id_seq OWNER TO postgres;

--
-- TOC entry 5175 (class 0 OID 0)
-- Dependencies: 221
-- Name: artists_artist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.artists_artist_id_seq OWNED BY public.artists.artist_id;


--
-- TOC entry 228 (class 1259 OID 17076)
-- Name: genres; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genres (
    genre_id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text
);


ALTER TABLE public.genres OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 17075)
-- Name: genres_genre_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.genres_genre_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.genres_genre_id_seq OWNER TO postgres;

--
-- TOC entry 5176 (class 0 OID 0)
-- Dependencies: 227
-- Name: genres_genre_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.genres_genre_id_seq OWNED BY public.genres.genre_id;


--
-- TOC entry 232 (class 1259 OID 17126)
-- Name: playlist_songs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.playlist_songs (
    playlist_id integer NOT NULL,
    song_id integer NOT NULL,
    added_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "position" integer NOT NULL,
    CONSTRAINT chk_position CHECK (("position" > 0))
);


ALTER TABLE public.playlist_songs OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 17106)
-- Name: playlists; Type: TABLE; Schema: public; Owner: postgres
--

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

--
-- TOC entry 230 (class 1259 OID 17105)
-- Name: playlists_playlist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.playlists_playlist_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.playlists_playlist_id_seq OWNER TO postgres;

--
-- TOC entry 5177 (class 0 OID 0)
-- Dependencies: 230
-- Name: playlists_playlist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.playlists_playlist_id_seq OWNED BY public.playlists.playlist_id;


--
-- TOC entry 229 (class 1259 OID 17088)
-- Name: song_genres; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.song_genres (
    song_id integer NOT NULL,
    genre_id integer NOT NULL
);


ALTER TABLE public.song_genres OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 17055)
-- Name: songs; Type: TABLE; Schema: public; Owner: postgres
--

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

--
-- TOC entry 225 (class 1259 OID 17054)
-- Name: songs_song_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.songs_song_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.songs_song_id_seq OWNER TO postgres;

--
-- TOC entry 5178 (class 0 OID 0)
-- Dependencies: 225
-- Name: songs_song_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.songs_song_id_seq OWNED BY public.songs.song_id;


--
-- TOC entry 234 (class 1259 OID 17147)
-- Name: streaming_history; Type: TABLE; Schema: public; Owner: postgres
--

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

--
-- TOC entry 233 (class 1259 OID 17146)
-- Name: streaming_history_stream_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.streaming_history_stream_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.streaming_history_stream_id_seq OWNER TO postgres;

--
-- TOC entry 5179 (class 0 OID 0)
-- Dependencies: 233
-- Name: streaming_history_stream_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.streaming_history_stream_id_seq OWNED BY public.streaming_history.stream_id;


--
-- TOC entry 236 (class 1259 OID 17172)
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

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

--
-- TOC entry 235 (class 1259 OID 17171)
-- Name: subscriptions_subscription_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscriptions_subscription_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscriptions_subscription_id_seq OWNER TO postgres;

--
-- TOC entry 5180 (class 0 OID 0)
-- Dependencies: 235
-- Name: subscriptions_subscription_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscriptions_subscription_id_seq OWNED BY public.subscriptions.subscription_id;


--
-- TOC entry 238 (class 1259 OID 25189)
-- Name: transaction_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaction_log (
    log_id integer NOT NULL,
    message text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.transaction_log OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 25188)
-- Name: transaction_log_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transaction_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transaction_log_log_id_seq OWNER TO postgres;

--
-- TOC entry 5181 (class 0 OID 0)
-- Dependencies: 237
-- Name: transaction_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transaction_log_log_id_seq OWNED BY public.transaction_log.log_id;


--
-- TOC entry 220 (class 1259 OID 16993)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

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

--
-- TOC entry 219 (class 1259 OID 16992)
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO postgres;

--
-- TOC entry 5182 (class 0 OID 0)
-- Dependencies: 219
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- TOC entry 4919 (class 2604 OID 17035)
-- Name: albums album_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums ALTER COLUMN album_id SET DEFAULT nextval('public.albums_album_id_seq'::regclass);


--
-- TOC entry 4915 (class 2604 OID 17019)
-- Name: artists artist_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artists ALTER COLUMN artist_id SET DEFAULT nextval('public.artists_artist_id_seq'::regclass);


--
-- TOC entry 4926 (class 2604 OID 17079)
-- Name: genres genre_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres ALTER COLUMN genre_id SET DEFAULT nextval('public.genres_genre_id_seq'::regclass);


--
-- TOC entry 4927 (class 2604 OID 17109)
-- Name: playlists playlist_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists ALTER COLUMN playlist_id SET DEFAULT nextval('public.playlists_playlist_id_seq'::regclass);


--
-- TOC entry 4923 (class 2604 OID 17058)
-- Name: songs song_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.songs ALTER COLUMN song_id SET DEFAULT nextval('public.songs_song_id_seq'::regclass);


--
-- TOC entry 4932 (class 2604 OID 17150)
-- Name: streaming_history stream_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.streaming_history ALTER COLUMN stream_id SET DEFAULT nextval('public.streaming_history_stream_id_seq'::regclass);


--
-- TOC entry 4936 (class 2604 OID 17175)
-- Name: subscriptions subscription_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN subscription_id SET DEFAULT nextval('public.subscriptions_subscription_id_seq'::regclass);


--
-- TOC entry 4938 (class 2604 OID 25192)
-- Name: transaction_log log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_log ALTER COLUMN log_id SET DEFAULT nextval('public.transaction_log_log_id_seq'::regclass);


--
-- TOC entry 4911 (class 2604 OID 16996)
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- TOC entry 4972 (class 2606 OID 17048)
-- Name: albums albums_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_pkey PRIMARY KEY (album_id);


--
-- TOC entry 4968 (class 2606 OID 17030)
-- Name: artists artists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artists
    ADD CONSTRAINT artists_pkey PRIMARY KEY (artist_id);


--
-- TOC entry 4981 (class 2606 OID 17087)
-- Name: genres genres_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_name_key UNIQUE (name);


--
-- TOC entry 4983 (class 2606 OID 17085)
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (genre_id);


--
-- TOC entry 4995 (class 2606 OID 17135)
-- Name: playlist_songs playlist_songs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlist_songs
    ADD CONSTRAINT playlist_songs_pkey PRIMARY KEY (playlist_id, song_id);


--
-- TOC entry 4990 (class 2606 OID 17120)
-- Name: playlists playlists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_pkey PRIMARY KEY (playlist_id);


--
-- TOC entry 4986 (class 2606 OID 17094)
-- Name: song_genres song_genres_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.song_genres
    ADD CONSTRAINT song_genres_pkey PRIMARY KEY (song_id, genre_id);


--
-- TOC entry 4979 (class 2606 OID 17069)
-- Name: songs songs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_pkey PRIMARY KEY (song_id);


--
-- TOC entry 5002 (class 2606 OID 17160)
-- Name: streaming_history streaming_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.streaming_history
    ADD CONSTRAINT streaming_history_pkey PRIMARY KEY (stream_id);


--
-- TOC entry 5006 (class 2606 OID 17187)
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (subscription_id);


--
-- TOC entry 5008 (class 2606 OID 25198)
-- Name: transaction_log transaction_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_log
    ADD CONSTRAINT transaction_log_pkey PRIMARY KEY (log_id);


--
-- TOC entry 4962 (class 2606 OID 17012)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 4964 (class 2606 OID 17010)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4966 (class 2606 OID 17014)
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 4973 (class 1259 OID 17197)
-- Name: idx_albums_artist; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_albums_artist ON public.albums USING btree (artist_id);


--
-- TOC entry 4974 (class 1259 OID 17198)
-- Name: idx_albums_release_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_albums_release_date ON public.albums USING btree (release_date);


--
-- TOC entry 4969 (class 1259 OID 17196)
-- Name: idx_artists_country; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_artists_country ON public.artists USING btree (country);


--
-- TOC entry 4970 (class 1259 OID 17195)
-- Name: idx_artists_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_artists_name ON public.artists USING btree (name);


--
-- TOC entry 4991 (class 1259 OID 17205)
-- Name: idx_playlist_songs_song; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_playlist_songs_song ON public.playlist_songs USING btree (song_id);


--
-- TOC entry 4987 (class 1259 OID 17204)
-- Name: idx_playlists_public; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_playlists_public ON public.playlists USING btree (is_public);


--
-- TOC entry 4988 (class 1259 OID 17203)
-- Name: idx_playlists_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_playlists_user ON public.playlists USING btree (user_id);


--
-- TOC entry 4992 (class 1259 OID 25202)
-- Name: idx_ps_playlist; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ps_playlist ON public.playlist_songs USING btree (playlist_id);


--
-- TOC entry 4993 (class 1259 OID 25203)
-- Name: idx_ps_song; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ps_song ON public.playlist_songs USING btree (song_id);


--
-- TOC entry 4984 (class 1259 OID 17202)
-- Name: idx_song_genres_genre; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_song_genres_genre ON public.song_genres USING btree (genre_id);


--
-- TOC entry 4975 (class 1259 OID 17199)
-- Name: idx_songs_album; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_songs_album ON public.songs USING btree (album_id);


--
-- TOC entry 4976 (class 1259 OID 17201)
-- Name: idx_songs_play_count; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_songs_play_count ON public.songs USING btree (play_count DESC);


--
-- TOC entry 4977 (class 1259 OID 17200)
-- Name: idx_songs_title; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_songs_title ON public.songs USING btree (title);


--
-- TOC entry 4996 (class 1259 OID 25204)
-- Name: idx_stream_song; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stream_song ON public.streaming_history USING btree (song_id);


--
-- TOC entry 4997 (class 1259 OID 25201)
-- Name: idx_stream_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stream_user ON public.streaming_history USING btree (user_id);


--
-- TOC entry 4998 (class 1259 OID 17208)
-- Name: idx_streaming_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_streaming_date ON public.streaming_history USING btree (streamed_at);


--
-- TOC entry 4999 (class 1259 OID 17207)
-- Name: idx_streaming_song; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_streaming_song ON public.streaming_history USING btree (song_id);


--
-- TOC entry 5000 (class 1259 OID 17206)
-- Name: idx_streaming_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_streaming_user ON public.streaming_history USING btree (user_id);


--
-- TOC entry 5003 (class 1259 OID 17210)
-- Name: idx_subscriptions_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subscriptions_active ON public.subscriptions USING btree (is_active);


--
-- TOC entry 5004 (class 1259 OID 17209)
-- Name: idx_subscriptions_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subscriptions_user ON public.subscriptions USING btree (user_id);


--
-- TOC entry 4959 (class 1259 OID 17194)
-- Name: idx_users_country; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_country ON public.users USING btree (country);


--
-- TOC entry 4960 (class 1259 OID 17193)
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- TOC entry 5021 (class 2620 OID 17214)
-- Name: streaming_history trg_increment_play_count; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_increment_play_count AFTER INSERT ON public.streaming_history FOR EACH ROW EXECUTE FUNCTION public.increment_play_count();


--
-- TOC entry 5019 (class 2620 OID 25200)
-- Name: users trg_log_user_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_user_insert BEFORE INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.log_insert_attempt();


--
-- TOC entry 5020 (class 2620 OID 17212)
-- Name: playlist_songs trg_update_playlist_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_playlist_timestamp AFTER INSERT ON public.playlist_songs FOR EACH ROW EXECUTE FUNCTION public.update_playlist_timestamp();


--
-- TOC entry 5009 (class 2606 OID 17049)
-- Name: albums fk_albums_artist; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT fk_albums_artist FOREIGN KEY (artist_id) REFERENCES public.artists(artist_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5014 (class 2606 OID 17136)
-- Name: playlist_songs fk_playlist_songs_playlist; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlist_songs
    ADD CONSTRAINT fk_playlist_songs_playlist FOREIGN KEY (playlist_id) REFERENCES public.playlists(playlist_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5015 (class 2606 OID 17141)
-- Name: playlist_songs fk_playlist_songs_song; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlist_songs
    ADD CONSTRAINT fk_playlist_songs_song FOREIGN KEY (song_id) REFERENCES public.songs(song_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5013 (class 2606 OID 17121)
-- Name: playlists fk_playlists_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT fk_playlists_user FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5011 (class 2606 OID 17100)
-- Name: song_genres fk_song_genres_genre; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.song_genres
    ADD CONSTRAINT fk_song_genres_genre FOREIGN KEY (genre_id) REFERENCES public.genres(genre_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5012 (class 2606 OID 17095)
-- Name: song_genres fk_song_genres_song; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.song_genres
    ADD CONSTRAINT fk_song_genres_song FOREIGN KEY (song_id) REFERENCES public.songs(song_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5010 (class 2606 OID 17070)
-- Name: songs fk_songs_album; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.songs
    ADD CONSTRAINT fk_songs_album FOREIGN KEY (album_id) REFERENCES public.albums(album_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5016 (class 2606 OID 17166)
-- Name: streaming_history fk_streaming_song; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.streaming_history
    ADD CONSTRAINT fk_streaming_song FOREIGN KEY (song_id) REFERENCES public.songs(song_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5017 (class 2606 OID 17161)
-- Name: streaming_history fk_streaming_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.streaming_history
    ADD CONSTRAINT fk_streaming_user FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5018 (class 2606 OID 17188)
-- Name: subscriptions fk_subscriptions_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_subscriptions_user FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2026-05-02 10:52:59

--
-- PostgreSQL database dump complete
--

\unrestrict VhJjONtpeWsfF7YVVLg7kAvs5QtofkftJm9uE7Q6mjaQeRssZ5vjWOpERRn4PyW

