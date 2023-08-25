FROM python:3.5-slim-buster

WORKDIR /opt/app
ADD /src/search_engine_crawler .

RUN pip install -r requirements.txt -r requirements-test.txt

EXPOSE 8000

CMD ["python", "-u", "crawler/crawler.py", "https://vitkhab.github.io/search_engine_test_site/"]