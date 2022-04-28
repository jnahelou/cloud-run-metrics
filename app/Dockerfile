FROM python:3.10-slim

WORKDIR /app

COPY . .
COPY requirements.txt /app/

RUN pip install Flask gunicorn
RUN pip3 install -r requirements.txt

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 main:app
