from prometheus_client import Counter, Histogram, Gauge


REQUEST_COUNT = Counter(
    "app_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "http_status"]
)

REQUEST_LATENCY = Histogram(
    "app_request_latency_seconds",
    "Request latency in seconds",
    ["endpoint"]
)

JOB_STATUS_COUNT = Gauge(
    "job_status_count",
    "Number of jobs by script and status from PostgreSQL",
    ["script_name", "status"]
)
