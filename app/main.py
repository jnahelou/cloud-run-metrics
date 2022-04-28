import time
import random

from flask import abort, request, Flask
from opentelemetry import propagate, trace
from opentelemetry.exporter.cloud_trace import CloudTraceSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.propagators.cloud_trace_propagator import CloudTraceFormatPropagator
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor


app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)


def configure_exporter(exporter):
    trace.set_tracer_provider(TracerProvider())
    trace.get_tracer_provider().add_span_processor(SimpleSpanProcessor(exporter))
    propagate.set_global_textmap(CloudTraceFormatPropagator())


configure_exporter(CloudTraceSpanExporter())
tracer = trace.get_tracer(__name__)

def trace_span(func):
    def inner(*args, **kwargs):
        with tracer.start_as_current_span(func.__name__):
            return func(*args, **kwargs)
    return inner

@trace_span
def do_sleep(duration):
    time.sleep(duration)


@trace_span
@app.route("/error")
def error_handler():
    r = random.randrange(100)
    if (r % 2 == 0):
        return { "status": "Done" }
    elif (r % 3 == 0):
        abort(404)
    elif (r % 5 == 0):
        abort(500)
    abort(403)

@trace_span
@app.route("/sleep")
def sleep_handler():
    duration = int(request.args.get("duration",default=0))
    do_sleep(duration)
    return { "status": "Done" }

@trace_span
@app.route("/")
def default_handler():
    return { "status": "Done" }


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)
