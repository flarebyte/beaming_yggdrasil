{
  configVersion: "1"
  action: "input-pipeline"

  discovery: {
    root: "."
  }

  errors: {
    mode: "keep-going"
    embedErrors: true
  }

  filter: {
    inline: """
      return thoth.starts_with(locator, "test/")
        and thoth.ends_with(locator, ".dart")
      """
  }

  map: {
    inline: """
      return {
        language = "dart",
      }
      """
  }

  shell: {
    enabled: true
    decodeJsonStdout: true
    program: "/bin/sh"
    workingDir: "."
    argsTemplate: [
      "-c",
      "npx maat-ostraca analyse " +
      "--in '{locator}' " +
      "--rules 'import_files_list,testcase_titles_list' " +
      "--language dart " +
      "--json",
    ]
  }

  postMap: {
    inline: """
      local rules = shell and shell.json and shell.json.rules or {}
      return {
        meta = {
          language = mapped and mapped.language or "dart",
          import_files_list = rules.import_files_list or {},
          testcase_titles_list = rules.testcase_titles_list or {},
        },
      }
      """
  }

  persistMeta: {
    enabled: true
    outDir: "./thoth-meta/dart-test"
  }

  output: {
    out: "./temp/pipeline-dart-test-maat.json"
    pretty: true
    lines: false
  }

  ui: {
    progress: true
    progressIntervalMs: 250
  }
}
