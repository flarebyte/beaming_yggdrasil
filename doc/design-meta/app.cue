package flyb

source: "beaming-yggdrasil"
name:   "beaming-yggdrasil"
modules: ["core"]

argumentRegistry: {
	arguments: [{
		name:          "format-csv"
		valueType:     "string"
		scopes:        ["note"]
		allowedValues: ["table"]
	}]
}

reports: [{
	title:       "beaming_yggdrasil Design"
	filepath:    "../design/specs.md"
	description: "Transport-first Dart client spec for the chatty mock server."
	sections: [{
		title:       "01 Overview"
		description: "Purpose, scope, and package boundary."
		sections: [{
			title:       "01 Purpose and Scope"
			description: "Repository target, client goal, and transport-first ownership boundaries."
			notes: [
				"dart.client.summary",
				"dart.client.goals",
				"dart.client.design-ownership",
				"dart.client.responsibilities",
				"dart.client.non-goals",
			]
		}, {
			title:       "02 Product Shape"
			description: "Major client areas, scope boundaries, and preferred API direction."
			notes: [
				"dart.client.scope",
				"dart.client.planned-surface",
				"dart.client.api-direction",
				"dart.client.cache-integration-primitives",
				"dart.client.stream-integration",
				"dart.client.source-layout",
				"dart.client.usecases",
			]
		}]
	}, {
		title:       "02 REST Contract"
		description: "HTTP actions and payload responsibilities."
		sections: [{
			title:       "01 REST Actions"
			description: "Supported REST endpoint actions for the client."
			notes: ["dart.client.rest-actions", "dart.client.rest-client"]
		}, {
			title:       "02 Error Mapping"
			description: "How server responses should map into client-facing transport outcomes."
			notes: ["dart.client.error-mapping"]
		}]
	}, {
		title:       "03 WebSocket Contract"
		description: "Optional websocket session responsibilities."
		sections: [{
			title:       "01 WebSocket Actions"
			description: "Command and message kinds used by the optional event channel."
			notes: ["dart.client.websocket-actions", "dart.client.websocket-client"]
		}]
	}, {
		title:       "04 Key Boundary"
		description: "Explicit separation between transport DTOs and key semantics."
		sections: [{
			title:       "01 Key Boundary"
			description: "Why this package keeps key handling intentionally lightweight."
			notes: ["dart.client.value-boundary", "dart.client.key-boundary", "dart.client.common"]
		}]
	}, {
		title:       "05 Diagnostics and Observability"
		description: "Hooks and signals for understanding transport behavior without locking the package into one tooling stack."
		sections: [{
			title:       "01 Diagnostics Hooks"
			description: "Observability should be customizable and implementation-agnostic while the final operational model is still evolving."
			notes: ["dart.client.observability-principles", "dart.client.diagnostics-hooks"]
		}]
	}, {
		title:       "06 Testing Strategy"
		description: "How the client should be validated against the real mock-server contract."
		sections: [{
			title:       "01 End-to-End Tests"
			description: "End-to-end Dart tests should exercise this client against the external chatty mock server implementation."
			notes: ["dart.client.e2e-testing-principles", "dart.client.e2e-testing"]
		}]
	}]
}]

notes: [
	{
		name:  "dart.client.summary"
		title: "Client Summary"
		markdown: """
		`beaming_yggdrasil` is a transport-first Dart client library for the `chatty` mock server and compatible Yggdrasil-style services.

		The package should make the wire contract easy to use from Dart without pretending to be the authority on `keyId` structure or other server-owned semantics.
		"""
		labels: ["overview", "markdown"]
	},
	{
		name:  "dart.client.goals"
		title: "Client Goals"
		filepath: "examples/client-goals.csv"
		arguments: ["format-csv=table"]
		labels: ["goals", "csv"]
	},
	{
		name:  "dart.client.design-ownership"
		title: "Design Ownership"
		filepath: "examples/design-ownership.csv"
		arguments: ["format-csv=table"]
		labels: ["ownership", "csv"]
	},
	{
		name:  "dart.client.responsibilities"
		title: "Main Responsibilities"
		filepath: "examples/main-responsibilities.csv"
		arguments: ["format-csv=table"]
		labels: ["responsibilities", "csv"]
	},
	{
		name:  "dart.client.non-goals"
		title: "Explicit Non-Goals"
		filepath: "examples/explicit-non-goals.csv"
		arguments: ["format-csv=table"]
		labels: ["non-goals", "csv"]
	},
	{
		name:  "dart.client.usecases"
		title: "Use Cases"
		filepath: "examples/usecases.csv"
		arguments: ["format-csv=table"]
		labels: ["usecase", "csv"]
	},
	{
		name:  "dart.client.scope"
		title: "Client Scope"
		filepath: "examples/client-scope.csv"
		arguments: ["format-csv=table"]
		labels: ["scope", "csv"]
	},
	{
		name:  "dart.client.planned-surface"
		title: "Planned Surface"
		filepath: "examples/planned-surface.csv"
		arguments: ["format-csv=table"]
		labels: ["surface", "csv"]
	},
	{
		name:  "dart.client.cache-integration-primitives"
		title: "Cache Integration Primitives"
		filepath: "examples/cache-integration.csv"
		arguments: ["format-csv=table"]
		labels: ["cache", "integration", "csv"]
	},
	{
		name:  "dart.client.api-direction"
		title: "Practical API Direction"
		filepath: "examples/api-direction.csv"
		arguments: ["format-csv=table"]
		labels: ["api", "csv"]
	},
	{
		name:  "dart.client.stream-integration"
		title: "Stream Integration Model"
		filepath: "examples/stream-integration.csv"
		arguments: ["format-csv=table"]
		labels: ["streams", "rx", "csv"]
	},
	{
		name:  "dart.client.rest-actions"
		title: "REST Actions"
		filepath: "examples/rest-actions.csv"
		arguments: ["format-csv=table"]
		labels: ["rest", "csv"]
	},
	{
		name:  "dart.client.error-mapping"
		title: "Error Mapping"
		filepath: "examples/error-mapping.csv"
		arguments: ["format-csv=table"]
		labels: ["errors", "csv"]
	},
	{
		name:  "dart.client.websocket-actions"
		title: "WebSocket Actions"
		filepath: "examples/websocket-actions.csv"
		arguments: ["format-csv=table"]
		labels: ["websocket", "csv"]
	},
	{
		name:  "dart.client.value-boundary"
		title: "Value Boundary"
		filepath: "examples/value-boundary.csv"
		arguments: ["format-csv=table"]
		labels: ["value", "boundary", "csv"]
	},
	{
		name:  "dart.client.key-boundary"
		title: "Key Boundary"
		filepath: "examples/key-boundary.csv"
		arguments: ["format-csv=table"]
		labels: ["key", "boundary", "csv"]
	},
	{
		name:  "dart.client.common"
		title: "Common Payload Shapes"
		filepath: "examples/common.ts"
		labels: ["typescript", "payloads"]
	},
	{
		name:  "dart.client.rest-client"
		title: "REST Client Example Shapes"
		filepath: "examples/rest-client.ts"
		labels: ["typescript", "rest"]
	},
	{
		name:  "dart.client.websocket-client"
		title: "WebSocket Client Example Shapes"
		filepath: "examples/websocket-client.ts"
		labels: ["typescript", "websocket"]
	},
	{
		name:  "dart.client.source-layout"
		title: "Source Layout"
		filepath: "examples/source-layout.csv"
		arguments: ["format-csv=table"]
		labels: ["layout", "csv"]
	},
	{
		name:  "dart.client.observability-principles"
		title: "Observability Principles"
		markdown: """
		Diagnostics and observability should be treated as first-class extension points rather than hard-coded framework choices.

		The client should prefer hooks, listeners, or pluggable adapters over committing early to one logging, tracing, or metrics dependency. That keeps the package usable in different environments while the final operational model is still unsettled.

		The package should surface enough structured context for higher layers to build:

		- logging
		- tracing
		- metrics
		- audit trails
		- custom debugging tools

		without forcing all consumers to adopt the same observability stack.
		"""
		labels: ["observability", "markdown"]
	},
	{
		name:  "dart.client.diagnostics-hooks"
		title: "Diagnostics Hooks"
		filepath: "examples/diagnostics-hooks.csv"
		arguments: ["format-csv=table"]
		labels: ["observability", "hooks", "csv"]
	},
	{
		name:  "dart.client.e2e-testing-principles"
		title: "End-to-End Testing Principles"
		markdown: """
		This library should include end-to-end tests written in Dart that validate the client against a running `chatty` mock server.

		The purpose of these tests is not to re-test the server internals, but to ensure that `beaming_yggdrasil` remains compatible with the real external contract exposed by `chatty`.

		The reference mock server for these tests is `flarebyte/chatty-ratatoskr`:

		- https://github.com/flarebyte/chatty-ratatoskr

		These tests should focus on client-visible behavior, wire compatibility, and transport semantics rather than implementation details inside either repository.
		"""
		labels: ["testing", "e2e", "markdown"]
	},
	{
		name:  "dart.client.e2e-testing"
		title: "End-to-End Test Coverage"
		filepath: "examples/e2e-testing.csv"
		arguments: ["format-csv=table"]
		labels: ["testing", "e2e", "csv"]
	},
]
