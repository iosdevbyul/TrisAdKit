FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY server/app.py server/auth.py server/reward_ledger.py ./
RUN useradd --uid 10001 --create-home rewards && mkdir -p /data && chown rewards:rewards /data
USER rewards
ENV PORT=8765 REWARD_BIND_HOST=0.0.0.0 REWARD_DATABASE=/data/rewards.sqlite3
EXPOSE 8765
CMD ["python", "app.py"]
