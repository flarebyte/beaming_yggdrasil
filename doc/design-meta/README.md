# beaming_yggdrasil Specs

This folder contains draft specs for the Dart client library `beaming_yggdrasil`.

Repository target:

- GitHub project: `beaming_yggdrasil`

Client goal:

- provide a Dart client for the `chatty` mock server
- conform to the shipped REST and WebSocket payload formats
- keep key handling intentionally lightweight
- avoid embedding strong `keyId` parsing or validation rules that are better owned by a separate key library

## Design Intent

`beaming_yggdrasil` should be a transport-first client library.

It should own:

- request and response DTOs
- REST endpoint calls
- WebSocket command and event payloads
- shallow envelope handling
- correlation id plumbing
- practical client-side error mapping

It should not own:

- authoritative `keyId` grammar
- deep key derivation rules
- full access-scope evaluation
- server-side kind derivation logic

## Folder Layout

- [overview.md](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/overview.md)
- [examples/usecases.csv](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/usecases.csv)
- [examples/client-scope.csv](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/client-scope.csv)
- [examples/rest-actions.csv](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/rest-actions.csv)
- [examples/websocket-actions.csv](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/websocket-actions.csv)
- [examples/error-mapping.csv](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/error-mapping.csv)
- [examples/key-boundary.csv](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/key-boundary.csv)
- [examples/common.ts](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/common.ts)
- [examples/rest-client.ts](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/rest-client.ts)
- [examples/websocket-client.ts](/Users/olivier/Documents/github/chatty-ratatoskr/temp/dart/examples/websocket-client.ts)

## Notes

- The `.ts` files are payload-shape examples, not implementation language requirements.
- The CSV files are intended to stay readable and easy to review without heavy Flyb or CUE machinery.
- The source protocol reference remains [doc/design/yggdrasil-mock-server.md](/Users/olivier/Documents/github/chatty-ratatoskr/doc/design/yggdrasil-mock-server.md).
