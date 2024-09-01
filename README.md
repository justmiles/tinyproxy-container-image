# Tinyproxy Container Image

[Tinyproxy](https://tinyproxy.github.io/) is a lightweight HTTP/HTTPS proxy daemon for POSIX operating systems. This project containerizes Tinyproxy, adding basic HTTP health check support, Prometheus `/metrics` endpoint, and configuration via environment variables.

## Table of Contents

- [Configuration](#configuration)
- [Examples](#examples)
  - [Run as Allowlist Proxy](#run-as-allowlist-proxy)
  - [Run as Denylist Proxy](#run-as-denylist-proxy)
- [Testing](#testing)
- [Building](#building)
- [Additional Notes](#additional-notes)

## Configuration

This project dynamically builds the `tinyproxy.conf` file based on environment variables. Values are mapped by prefixing each config with `TINYPROXY_CONF_` and converting from standard case to camel case. Consider the following examples:

- `Bind` -> `TINYPROXY_CONF_BIND`
- `LogLevel` -> `TINYPROXY_CONF_LOG_LEVEL`

Refer to the [Tinyproxy documentation](https://tinyproxy.github.io/) for detailed configuration variables.

This project listens over a few different ports. You can define these with the environment variables below:

| Environment Variable       | Default Port | Description                                        |
| -------------------------- | ------------ | -------------------------------------------------- |
| `PROMETHEUS_EXPORTER_PORT` | `8887`       | Serves Prometheus metrics.                         |
| `TINYPROXY_CONF_PORT`      | `8888`       | This is the port Tinyproxy will accept traffic on. |
| `HEALTHCHECK_PORT`         | `8889`       | Serves the HTTP health check.                      |

When dealing with large filter lists, it is more efficient to mount these lists as files and use the `TINYPROXY_CONF_FILTER` environment variable to point to the appropriate mount point. For smaller lists, you can provide the entire list base64 encoded via the `TINYPROXY_FILTER` environment variable. The container will decode this string and write it to a temporary file on startup, then configure Tinyproxy to use this file.

### Prometheus Metrics Endpoint

The metric endpoint is available at `http://localhost:8887/metrics`

### Healthcheck Endpoint

The healthcheck endpoint is available at `http://localhost:8889/health`

## Examples

### Run as Allowlist Proxy

```bash
docker run -p 8888:8888 \
  -e TINYPROXY_CONF_ALLOW=0.0.0.0/0 \
  -e TINYPROXY_CONF_LISTEN=0.0.0.0 \
  -e TINYPROXY_CONF_FILTER_TYPE=fnmatch \
  -e TINYPROXY_CONF_FILTER_DEFAULT_DENY=Yes \
  -e TINYPROXY_FILTER="$(cat example-list.txt | base64 -w0)" \
  -it --rm justmiles/tinyproxy:latest

```

### Run as Denylist Proxy

```bash
docker run -p 8888:8888 \
  -e TINYPROXY_CONF_ALLOW=0.0.0.0/0 \
  -e TINYPROXY_CONF_LISTEN=0.0.0.0 \
  -e TINYPROXY_CONF_FILTER_TYPE=fnmatch \
  -e TINYPROXY_CONF_FILTER_DEFAULT_DENY=No \
  -e TINYPROXY_FILTER="$(cat example-list.txt | base64 -w0)" \
  -it --rm justmiles/tinyproxy:latest
```

### Run with Healthcheck and Metrics

```bash
> docker run --rm -d --name tinyproxy \
  -p 8887:8887 \
  -p 8888:8888 \
  -p 8889:8889 \
  -e TINYPROXY_CONF_ALLOW=0.0.0.0/0 \
  -e TINYPROXY_CONF_LISTEN=0.0.0.0 \
  -e TINYPROXY_CONF_FILTER_TYPE=fnmatch \
  -e TINYPROXY_CONF_FILTER_DEFAULT_DENY=Yes \
  -e TINYPROXY_FILTER="$(cat example-list.txt | base64 -w0)" \
  -it --rm justmiles/tinyproxy:latest

# hit the healthcheck endpoint
> curl stable:8889/health
OK

# hit the metrics endpoint
> curl stable:8887/metrics
open_connections 1
bad_connections 0
denied_connections 0
refused 0
total_requests 1

```

## Testing

Set up the environment variables for HTTP/HTTPS proxy:

```
export http_proxy=localhost:8888
export https_proxy=localhost:8888

curl google.com
```

## Building

Build the Docker image:

```
docker build . -t tinyproxy
```

## Additional Notes

You can pull statistics by curling `tinyproxy.stats` using the proxy:

```
export http_proxy=localhost:8888
export https_proxy=localhost:8888

curl tinyproxy.stats
```

---

Feel free to raise issues or contribute to this project. Happy proxying!
