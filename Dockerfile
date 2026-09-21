FROM alpine:3.19

SHELL ["/bin/ash", "-o", "pipefail", "-c"]

RUN apk add --no-cache \
  bash=~5 \
  coreutils=~9 \
  curl=~8 \
  git=~2 \
  sed=~4 \
&& rm -rf /var/cache/apk/* \
&& adduser -D -u 1000 runner

COPY --chmod=0755 ./upload_sarif_to_defectdojo.bash /

HEALTHCHECK NONE

USER 1000
ENTRYPOINT ["/upload_sarif_to_defectdojo.bash"]
