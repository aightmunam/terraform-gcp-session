FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

ENV FUNCTION_TARGET=hello_world_get
ENV PORT=8080

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip -r requirements.txt

COPY . .

EXPOSE 8080

CMD ["python", "-m", "functions_framework", "--target=hello_world_get", "--host=0.0.0.0", "--port=8080"]
