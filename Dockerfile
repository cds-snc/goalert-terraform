# Build a GoAlert image with the AWS Lambda Web Adapter extension.
# The web adapter intercepts ALB / API Gateway / Function URL events
# and proxies them as plain HTTP requests to GoAlert's local web server.
#
# https://github.com/aws/aws-lambda-web-adapter

FROM public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 AS lambda-adapter

FROM goalert/goalert:v0.34.1

# Install the Lambda Web Adapter as a Lambda Extension.
# Lambda runs all binaries under /opt/extensions/ before starting the handler.
COPY --from=lambda-adapter /lambda-adapter /opt/extensions/lambda-adapter

# Tell the adapter which port GoAlert listens on and where to probe for readiness.
ENV AWS_LWA_PORT=8081
ENV AWS_LWA_READINESS_CHECK_PATH=/api/v2/health
ENV AWS_LWA_READINESS_CHECK_PROTOCOL=http

# GoAlert runtime defaults (sensitive values injected by Lambda environment variables).
ENV GOALERT_LISTEN=":8081"
ENV GOALERT_LOG_FORMAT=json
