FROM python:3.12-slim
WORKDIR /app
COPY pyproject.toml .
RUN pip install --no-cache-dir git+https://github.com/abedegno/givenergy-modbus-async.git@dev
COPY src/ src/
COPY settings/ settings/
COPY config.example.yaml config.example.yaml
RUN pip install --no-cache-dir .
EXPOSE 8099
CMD ["uvicorn", "givenergy_local.main:app", "--host", "0.0.0.0", "--port", "8099"]
