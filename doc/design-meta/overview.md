# beaming_yggdrasil Overview

## Purpose

`beaming_yggdrasil` should be a Dart client library for the `chatty` mock server and compatible Yggdrasil-style services.

The library should make the transport contract easy to use from Dart applications without pretending to be the authority on `keyId` structure.

## Main Responsibilities

- send REST requests that match the mock server payload formats
- decode shallow REST response envelopes
- open and manage the optional WebSocket connection
- send WebSocket commands and decode event messages
- preserve correlation ids and status values
- expose practical Dart-friendly client abstractions over the wire DTOs

## Explicit Non-Goals

- do not parse the full logical key grammar in this package
- do not derive authoritative `kind` values from `keyId`
- do not duplicate server access-control logic
- do not mix local persistence concerns into the transport contract

## Key Boundary

For this client, `keyId` should normally be treated as an opaque string.

Minimal expectations:

- a request may require a `keyId` string
- the client may preserve optional client-supplied `kind` hints in DTOs
- the client must not invent server-derived key semantics locally unless a future dedicated key library is introduced

If richer key tooling is needed later, it should live in a separate Dart package and compose with `beaming_yggdrasil`.

## Planned Surface

The client spec currently assumes these major areas:

- snapshot client methods
- node read and write client methods
- create client methods
- optional admin commands for test harness usage
- optional WebSocket subscription and event handling

## Practical API Direction

The eventual Dart package should likely provide:

- DTO classes for request and response payloads
- a small HTTP client wrapper
- a WebSocket session wrapper
- typed status enums or string constants
- a transport error model that preserves server status and message content

It should avoid:

- a large code-generated schema framework before the core flows are pleasant to use
- committing the package to heavyweight `keyId` modeling too early
