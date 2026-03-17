# frozen_string_literal: true

# NATS connection is lazy-loaded in Realtime::NatsPublisher.
# Configure URL via NATS_URL env var (default: nats://localhost:4222).
#
# In production, NATS runs inside the Docker network with auth tokens.
# In development, it runs on localhost without auth.
