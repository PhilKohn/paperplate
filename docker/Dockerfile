# Hermetic build image: same pinned toolchain as requirements.txt.
#   docker build -f docker/Dockerfile -t paperplate .
#   docker run --rm -v "$PWD":/work paperplate            # builds the PDF
#   docker run --rm -v "$PWD":/work paperplate docx
FROM python:3.12.7-slim-bookworm
RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
WORKDIR /work
ENV GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0=/work
ENTRYPOINT ["python3", "/work/paperplate/build.py"]
CMD ["pdf", "--strict"]
