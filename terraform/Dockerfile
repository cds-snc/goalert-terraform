FROM public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 AS lambda-adapter

FROM goalert/goalert:v0.34.1

COPY --from=lambda-adapter /lambda-adapter /opt/extensions/lambda-adapter

ENV AWS_LWA_PORT=8081
ENV AWS_LWA_READINESS_CHECK_PATH=/
ENV AWS_LWA_READINESS_CHECK_PROTOCOL=http

ENV GOALERT_LISTEN=":8081"
ENV GOALERT_LOG_FORMAT=json