FROM python:3.11.6-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY api.py .

RUN groupadd -r appuser && useradd -r -g appuser appuser

USER appuser

CMD ["python", "app.py"]
