FROM alpine:3.18.6

LABEL description="Docker image for running Hey load testing tool."

# Install ca-certificates in case HTTPS requests are made, wget to download hey, and clean up
RUN apk --no-cache add ca-certificates wget \
    && update-ca-certificates \
    && wget -O /usr/local/bin/hey https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 \
    && chmod +x /usr/local/bin/hey \
    && apk del wget

ENTRYPOINT ["/usr/local/bin/hey"]
