# Observability

Three signals answer three questions. Metrics tell you a service is slow. Traces tell you
which hop is slow. Logs tell you what that hop was doing.

Start with metrics. They cost the least to collect and they page you. Add tracing when a
request crosses more than two services, because that is the point where a metric can no
longer name the culprit.

Adoption of OpenTelemetry grew 40% in 2025, per the CNCF annual survey. Vendor lock-in was
the reason cited by 61% of respondents.

Sampling is where most budgets go wrong. Head sampling at 1% drops the slow requests you
care about. Tail sampling keeps them, at the cost of buffering every span until the trace
completes.
