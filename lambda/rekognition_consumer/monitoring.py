import time
from opentelemetry import metrics

meter = metrics.get_meter("rekognition_consumer_meter")

# -------------------------------------------------------------------
# Counters
# -------------------------------------------------------------------

# Total images/videos processed, labeled by status and detection mode
image_processed_counter = meter.create_counter(
    name="rekognition_images_processed_total",
    unit="1",
    description="Total number of files processed by the rekognition consumer"
)

# Errors broken down by which component raised them
error_counter = meter.create_counter(
    name="rekognition_errors_total",
    unit="1",
    description="Total errors by component (rekognition, s3, apigateway, pillow, other)"
)

# -------------------------------------------------------------------
# Histograms
# -------------------------------------------------------------------

# How long each Rekognition API call takes (seconds)
rekognition_latency = meter.create_histogram(
    name="rekognition_detection_duration_seconds",
    unit="s",
    description="Duration of Rekognition API calls in seconds"
)

# Size of the S3 object that was processed (bytes)
image_size_histogram = meter.create_histogram(
    name="rekognition_image_size_bytes",
    unit="By",
    description="Size in bytes of images/videos processed"
)

# -------------------------------------------------------------------
# Public helpers called from index.py
# -------------------------------------------------------------------

def track_image_processed(status="success", detection_mode="unknown", function_name="unknown"):
    image_processed_counter.add(1, {
        "status": status,
        "detection_mode": detection_mode,
        "function_name": function_name
    })


def track_error(component="other", function_name="unknown"):
    """
    component: one of rekognition | s3 | apigateway | pillow | other
    """
    error_counter.add(1, {
        "component": component,
        "function_name": function_name
    })


def track_rekognition_latency(duration_seconds, detection_mode="unknown"):
    rekognition_latency.record(duration_seconds, {
        "detection_mode": detection_mode
    })


def track_image_size(size_bytes, file_type="unknown"):
    image_size_histogram.record(size_bytes, {
        "file_type": file_type
    })


class RekognitionTimer:
    """Context manager for timing a Rekognition call and recording it."""
    def __init__(self, detection_mode):
        self.detection_mode = detection_mode
        self._start = None

    def __enter__(self):
        self._start = time.perf_counter()
        return self

    def __exit__(self, exc_type, *_):
        duration = time.perf_counter() - self._start
        track_rekognition_latency(duration, self.detection_mode)
