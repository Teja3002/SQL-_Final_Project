

from __future__ import annotations

import os
from pathlib import Path
from urllib.parse import quote_plus

import pandas as pd
import plotly.express as px
import streamlit as st

DATA_DIR = Path(__file__).resolve().parent.parent / "data"


def _norm_bool_series(s: pd.Series) -> pd.Series:
    if s.dtype == bool:
        return s
    return s.astype(str).str.upper().isin(("TRUE", "T", "1", "YES"))


def load_from_csv() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    h = pd.read_csv(DATA_DIR / "streaming_history.csv", parse_dates=["streamed_at"])
    s = pd.read_csv(DATA_DIR / "songs.csv")
    sg = pd.read_csv(DATA_DIR / "song_genres.csv")
    g = pd.read_csv(DATA_DIR / "genres.csv")
    sub = pd.read_csv(
        DATA_DIR / "subscriptions.csv",
        parse_dates=["start_date", "end_date"],
        dayfirst=False,
        infer_datetime_format=True,
    )
    sub["is_active"] = _norm_bool_series(sub["is_active"])
    sub["price"] = pd.to_numeric(sub["price"], errors="coerce").fillna(0)
    return h, s, sg, g, sub


def load_from_postgres() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    from sqlalchemy import create_engine, text

    host = os.environ.get("PGHOST", "localhost")
    port = os.environ.get("PGPORT", "5432")
    db = os.environ.get("PGDATABASE", "music_streaming")
    user = os.environ.get("PGUSER", "postgres")
    password = os.environ.get("PGPASSWORD", "")

    try:
        if hasattr(st, "secrets") and "postgres" in st.secrets:
            sct = st.secrets["postgres"]
            host = str(sct.get("host", host))
            port = str(sct.get("port", port))
            db = str(sct.get("database", db))
            user = str(sct.get("user", user))
            password = str(sct.get("password", password))
    except (FileNotFoundError, KeyError, TypeError):
        pass

    url = f"postgresql+psycopg2://{quote_plus(user)}:{quote_plus(password)}@{host}:{port}/{db}"
    engine = create_engine(url, pool_pre_ping=True)

    q = """
    SELECT stream_id, user_id, song_id, streamed_at, duration_played, device_type
    FROM streaming_history
    """
    h = pd.read_sql(text(q), engine)
    s = pd.read_sql(text("SELECT * FROM songs"), engine)
    sg = pd.read_sql(text("SELECT * FROM song_genres"), engine)
    g = pd.read_sql(text("SELECT * FROM genres"), engine)
    sub = pd.read_sql(text("SELECT * FROM subscriptions"), engine)
    return h, s, sg, g, sub


@st.cache_data(ttl=60)
def load_all(source: str) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    if source == "PostgreSQL":
        return load_from_postgres()
    return load_from_csv()


def df_top_songs(h: pd.DataFrame, s: pd.DataFrame, top_n: int = 15) -> pd.DataFrame:
    m = h.merge(s[["song_id", "title"]], on="song_id", how="inner")
    out = (
        m.groupby(["song_id", "title"])
        .size()
        .reset_index(name="stream_events")
        .sort_values("stream_events", ascending=False)
        .head(top_n)
    )
    return out


def df_plan_revenue(sub: pd.DataFrame) -> pd.DataFrame:
    a = sub[sub["is_active"]].copy()
    return (
        a.groupby("plan_type", as_index=False)
        .agg(subscriber_rows=("subscription_id", "count"), plan_revenue=("price", "sum"))
        .sort_values("plan_revenue", ascending=False)
    )


def df_streams_by_month(h: pd.DataFrame) -> pd.DataFrame:
    d = h.copy()
    d["streamed_at"] = pd.to_datetime(d["streamed_at"])
    d["month"] = d["streamed_at"].dt.to_period("M").dt.to_timestamp()
    return d.groupby("month", as_index=False).size().rename(columns={"size": "streams"})


def df_top_genres(h: pd.DataFrame, s: pd.DataFrame, sg: pd.DataFrame, g: pd.DataFrame, top_n: int = 12) -> pd.DataFrame:
    m = h.merge(s[["song_id"]], on="song_id").merge(sg, on="song_id").merge(g[["genre_id", "name"]], on="genre_id")
    out = (
        m.groupby(["genre_id", "name"])
        .size()
        .reset_index(name="stream_events")
        .sort_values("stream_events", ascending=False)
        .head(top_n)
    )
    return out.rename(columns={"name": "genre_name"})


def main() -> None:
    st.set_page_config(page_title="Music Streaming Analytics", layout="wide", initial_sidebar_state="expanded")

    st.title("Music streaming platform analytics")
    st.caption("CSE 4/560 bonus dashboard — exploratory charts from the course project dataset.")

    with st.sidebar:
        st.header("Data source")
        source = st.radio("Load data from", ["Local CSV (../data)", "PostgreSQL"], index=0)
        source_key = "PostgreSQL" if source.startswith("PostgreSQL") else "CSV"

        st.subheader("Filters")
        date_min = None
        date_max = None

    try:
        h, s, sg, g, sub = load_all(source_key)
    except Exception as e:
        st.error(f"Could not load data: {e}")
        if source_key == "PostgreSQL":
            st.info("Check PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD or Streamlit Cloud secrets [postgres].")
        else:
            st.info(f"Expected CSV files under: {DATA_DIR}")
        return

    h = h.copy()
    h["streamed_at"] = pd.to_datetime(h["streamed_at"])

    with st.sidebar:
        dmin, dmax = h["streamed_at"].min().date(), h["streamed_at"].max().date()
        date_range = st.date_input("Stream date range", value=(dmin, dmax), min_value=dmin, max_value=dmax)
        if isinstance(date_range, tuple) and len(date_range) == 2:
            date_min, date_max = date_range
            h = h[(h["streamed_at"].dt.date >= date_min) & (h["streamed_at"].dt.date <= date_max)]

    active_subs = sub[sub["is_active"]]
    col1, col2, col3 = st.columns(3)
    col1.metric("Stream events (filtered)", f"{len(h):,}")
    col2.metric("Active subscription rows", f"{len(active_subs):,}")
    col3.metric("Sum of active plan prices ($)", f"{active_subs['price'].sum():,.2f}")

    st.divider()

    c1, c2 = st.columns(2)

    with c1:
        st.subheader("Top songs by listen events")
        ts = df_top_songs(h, s)
        fig1 = px.bar(
            ts,
            x="stream_events",
            y="title",
            orientation="h",
            labels={"stream_events": "Streams", "title": "Song"},
            color="stream_events",
            color_continuous_scale="Blues",
        )
        fig1.update_layout(yaxis={"categoryorder": "total ascending"}, height=480, showlegend=False)
        st.plotly_chart(fig1, use_container_width=True)
        st.markdown(
            "**Insight:** A short list of tracks captures a disproportionate share of streams, "
            "**which suggests catalog promotion and licensing efforts should prioritize these titles.** "
            "Long-tail discovery still matters, but peak-demand tracks drive capacity planning."
        )

    with c2:
        st.subheader("Active subscriptions: revenue by plan")
        pr = df_plan_revenue(sub)
        fig2 = px.bar(
            pr,
            x="plan_type",
            y="plan_revenue",
            color="plan_type",
            labels={"plan_type": "Plan", "plan_revenue": "Monthly price sum ($)"},
        )
        fig2.update_layout(showlegend=False, height=480)
        st.plotly_chart(fig2, use_container_width=True)
        st.markdown(
            "**Insight:** Revenue concentration by plan type shows which tiers fund the business today. "
            "**If premium and family plans dominate dollar volume, pricing experiments should guard those ARPU levels.** "
            "Free and student tiers may still anchor acquisition even if revenue is smaller."
        )

    c3, c4 = st.columns(2)

    with c3:
        st.subheader("Listening volume by month")
        sm = df_streams_by_month(h)
        fig3 = px.line(sm, x="month", y="streams", markers=True, labels={"month": "Month", "streams": "Streams"})
        fig3.update_layout(height=400)
        st.plotly_chart(fig3, use_container_width=True)
        st.markdown(
            "**Insight:** Month-to-month variation highlights seasonality or campaign effects in synthetic data. "
            "**Operations teams can align cache warming and support staffing with these demand swings.** "
            "Sudden drops might also flag data-collection gaps worth monitoring."
        )

    with c4:
        st.subheader("Genres with the most streams")
        tg = df_top_genres(h, s, sg, g)
        fig4 = px.bar(
            tg,
            x="genre_name",
            y="stream_events",
            color="stream_events",
            color_continuous_scale="Teal",
            labels={"genre_name": "Genre", "stream_events": "Streams"},
        )
        fig4.update_xaxes(tickangle=35)
        fig4.update_layout(height=400, showlegend=False)
        st.plotly_chart(fig4, use_container_width=True)
        st.markdown(
            "**Insight:** Genres bridge catalog metadata and actual behavior—listeners may stream _through_ tags. "
            "**Playlist and recommendation teams can overweight high-engagement genres while testing diversity goals.** "
            "Mismatches versus raw catalog size can reveal under-marketed styles."
        )

    with st.expander("SQL excerpts (for your bonus report)"):
        st.code(
            Path(__file__).resolve().parent.joinpath("bonus_queries.sql").read_text(encoding="utf-8"),
            language="sql",
        )


if __name__ == "__main__":
    main()
