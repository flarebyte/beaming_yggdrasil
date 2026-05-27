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
      return thoth.starts_with(locator, "lib/")
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
      "--rules 'import_files_list,class_map,function_map' " +
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
          class_list = thoth.sort_keys(rules.class_map or {}),
          function_list = thoth.sort_keys(rules.function_map or {}),
        },
      }
      """
  }

  persistMeta: {
    enabled: true
    outDir: "./thoth-meta/dart"
  }

  output: {
    out: "./temp/pipeline-dart-maat.json"
    pretty: true
    lines: false
  }

  ui: {
    progress: true
    progressIntervalMs: 250
  }
}
