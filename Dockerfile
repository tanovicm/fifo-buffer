FROM golang:1.24-alpine AS builder

RUN apk add --no-cache zeromq-dev build-base pkgconfig

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=1 GOOS=linux go build -o server cmd/server/main.go

FROM alpine:latest

RUN apk add --no-cache zeromq

WORKDIR /app

COPY --from=builder /app/server .

EXPOSE 5555

CMD ["./server"]