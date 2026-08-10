from opentelemetry import metrics

# Initialize the telemetry meter
meter = metrics.get_meter("rekognition_consumer_meter")

# Define the counter instrument
image_processed_counter = meter.create_counter(
    name="rekognition_images_processed_total",
    unit="1",
    description="Total number of images processed by Rekognition consumer"
)

def track_image_processed(status="success", function_name="unknown"):
    """Helper function to cleanly increment your Prometheus metric"""
    image_processed_counter.add(1, {
        "status": status,
        "function_name": function_name
    })
