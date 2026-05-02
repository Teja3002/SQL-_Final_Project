================================================================================
MUSIC STREAMING PLATFORM DATABASE - DATA README
CSE 4/560 Data Models and Query Language - Semester Project
================================================================================

DATA SOURCE
-----------
All data in this directory was programmatically generated using Python.
The generation script is located at: scripts/generate_data.py

The data is synthetic (fake) but follows realistic patterns based on:
- Real music streaming platform structures (Spotify, Apple Music)
- Realistic name distributions from various countries
- Proper date ranges and numeric distributions

DATA FILES
----------
1. users.csv (200 records)
   - Platform users with authentication and profile information
   - Unique emails and usernames guaranteed

2. artists.csv (80 records)
   - Music artists and bands
   - Includes formation year, country, and listener counts

3. albums.csv (323 records)
   - Albums linked to artists
   - Includes singles, EPs, full albums, and compilations

4. songs.csv (2,655 records)
   - Individual tracks linked to albums
   - Includes duration, play counts, and explicit flags

5. genres.csv (20 records)
   - Music genre categories
   - Covers major genres: Pop, Rock, Hip Hop, Jazz, etc.

6. song_genres.csv (5,285 records)
   - Many-to-many relationship between songs and genres
   - Each song assigned 1-3 genres randomly

7. playlists.csv (617 records)
   - User-created playlists
   - Includes public/private visibility

8. playlist_songs.csv (10,887 records)
   - Songs added to playlists with position ordering
   - Each playlist contains 5-30 songs

9. streaming_history.csv (10,967 records)
   - User streaming events with timestamps
   - Includes device type and duration played

10. subscriptions.csv (283 records)
    - User subscription plans (free, student, premium, etc.)
    - Includes historical and current subscriptions

TOTAL RECORDS: 31,317

DATA CHARACTERISTICS
--------------------
- All foreign key relationships are valid
- Dates are within reasonable ranges (1960-2025)
- Numeric values follow realistic distributions
- Text data uses varied but consistent patterns

LOADING INSTRUCTIONS
--------------------
1. Ensure PostgreSQL database is created
2. Run sql/create.sql to create schema
3. Run sql/load.sql to bulk load CSV files
4. Verify with sample queries in sql/sample_queries.sql

Note: Update file paths in load.sql to match your system.

REGENERATING DATA
-----------------
To regenerate data with different parameters:
1. Navigate to scripts/ directory
2. Run: python generate_data.py
3. CSV files will be created/overwritten in data/ directory

Random seed is set to 42 for reproducibility.

================================================================================
Generated: March 2026
================================================================================
