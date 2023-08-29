FROM python:3.6-alpine

WORKDIR /app
ADD . /app

RUN pip install -r /app/requirements.txt -r /app/requirements-test.txt

CMD ["python", "-u", "crawler/crawler.py", "https://vitkhab.github.io/search_engine_test_site/"]