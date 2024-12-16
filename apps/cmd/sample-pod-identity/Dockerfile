FROM golang:1.23.3-bullseye as build
WORKDIR /app
# Copy dependencies list
COPY go.mod go.sum ./
# Build with optional lambda.norpc tag
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main cmd/sample-pod-identity/main.go
# Copy artifacts to a clean image
FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y ca-certificates openssl
COPY --from=build /app/main /main
ENTRYPOINT [ "/main" ]
