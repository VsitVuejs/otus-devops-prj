FROM python:3.6-alpine

WORKDIR /app
ADD . /app

RUN pip install -r /app/requirements.txt -r /app/requirements-test.txt

WORKDIR /app/ui

CMD ["gunicorn", "ui:app", "-b", "0.0.0.0"]