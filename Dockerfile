FROM python:3.11

RUN apt-get update && apt-get install -y libdbus-1-dev
RUN apt-get update && apt-get install -y cloud-init

WORKDIR /app

COPY requirements.txt .

RUN pip install --upgrade pip

RUN pip install -r requirements.txt

COPY . .

CMD ["python", "run_pipeline.py"]
