package flyb

source: "beaming-yggdrasil"
name:   "beaming-yggdrasil"
modules: ["core"]

reports: [{
	title:       "beaming_yggdrasil Design"
	filepath:    "../design/specs.md"
	description: "Transport-first Dart client spec for the chatty mock server."
	sections: [{
		title:       "01 Overview"
		description: "Purpose, scope, and package boundary."
		sections: [{
			title:       "01 Intent"
			description: "What the Dart client should own and what it should leave to other libraries."
			notes: ["dart.client.readme", "dart.client.overview"]
		}, {
			title:       "02 Use Cases"
			description: "Core client workflows and success criteria."
			notes: ["dart.client.usecases", "dart.client.scope"]
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
			notes: ["dart.client.key-boundary", "dart.client.common"]
		}]
	}]
}]

notes: [
	{
		name:  "dart.client.readme"
		title: "beaming_yggdrasil Specs"
		filepath: "README.md"
		labels: ["overview", "markdown"]
	},
	{
		name:  "dart.client.overview"
		title: "Client Overview"
		filepath: "overview.md"
		labels: ["overview", "markdown"]
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
]
