package ghflarebyte

project: {
  org:  "flarebyte"
  repo: "beaming_yggdrasil"
}

sync: {
  mode: "push"
}

repository: {
  description:   "Pure Dart client primitives for a Yggdrasil-style service"
  defaultBranch: "main"
  homepage:      "https://github.com/flarebyte/beaming_yggdrasil"
  visibility:    "public"
  template:      false
  topics: [
    "dart",
    "flutter",
    "client",
    "yggdrasil",
  ]
  labels: [
    {
      name:        "bug"
      color:       "d73a4a"
      description: "Something isn't working"
    },
    {
      name:        "documentation"
      color:       "0075ca"
      description: "Improvements or additions to documentation"
    },
    {
      name:        "duplicate"
      color:       "cfd3d7"
      description: "This issue or pull request already exists"
    },
    {
      name:        "enhancement"
      color:       "a2eeef"
      description: "New feature or request"
    },
    {
      name:        "good first issue"
      color:       "7057ff"
      description: "Good for newcomers"
    },
    {
      name:        "help wanted"
      color:       "008672"
      description: "Extra attention is needed"
    },
    {
      name:        "invalid"
      color:       "e4e669"
      description: "This doesn't seem right"
    },
    {
      name:        "question"
      color:       "d876e3"
      description: "Further information is requested"
    },
    {
      name:        "wontfix"
      color:       "ffffff"
      description: "This will not be worked on"
    },
  ]
  features: {
    issues:                       true
    wiki:                         false
    projects:                     false
    discussions:                  false
    autoMerge:                    true
    mergeCommit:                  false
    rebaseMerge:                  false
    squashMerge:                  true
    squashMergeCommitMessage:     "pr-title"
    deleteBranchOnMerge:          true
    allowForking:                 false
    allowUpdateBranch:            false
    advancedSecurity:             true
    secretScanning:               true
    secretScanningPushProtection: true
  }
}

build: {
  language:     "go"
  outputDir:    "build"
  checksumFile: "build/checksums.txt"
  targets: [
    "darwin-arm64",
  ]
}

release: {
  versionSource:    "pubspec.yaml"
  tagPrefix:        "v"
  notesMode:        "generate-notes"
  includeArtifacts: false
  artifactDir:      "build"
  includeChecksums: true
}
