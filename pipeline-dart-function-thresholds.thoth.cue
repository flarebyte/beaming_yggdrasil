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
        tokenThreshold = 120,
        complexityThreshold = 5,
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
      "--rules 'function_map,method_map' " +
      "--language dart " +
      "--json",
    ]
  }

  postMap: {
    inline: """
      local rules = shell and shell.json and shell.json.rules or {}
      local functionMap = rules.function_map or {}
      local methodMap = rules.method_map or {}
      local flagged = {}
      local tokenThreshold = mapped and mapped.tokenThreshold or 120
      local complexityThreshold = mapped and mapped.complexityThreshold or 5

      local function addFlagged(kind, symbolMap)
        for _, name in ipairs(thoth.sort_keys(symbolMap)) do
          local node = symbolMap[name] or {}
          local tokens = node.tokens or 0
          local complexity = node.cognitiveComplexity or 0
          if tokens > tokenThreshold or complexity > complexityThreshold then
            thoth.push(flagged, {
              kind = kind,
              name = name,
              cognitiveComplexity = node.cognitiveComplexity or 0,
              cyclomaticComplexity = node.cyclomaticComplexity or 0,
              tokens = node.tokens or 0,
              loc = node.loc or 0,
              sloc = node.sloc or 0,
            })
          end
        end
      end

      addFlagged("function", functionMap)
      addFlagged("method", methodMap)

      return {
        locator = locator,
        flaggedCount = #flagged,
        flaggedFunctions = flagged,
      }
      """
  }

  reduce: {
    inline: """
      local function worseFirst(a, b)
        if a.cognitiveComplexity ~= b.cognitiveComplexity then
          return a.cognitiveComplexity > b.cognitiveComplexity
        end
        if a.tokens ~= b.tokens then
          return a.tokens > b.tokens
        end
        if a.locator ~= b.locator then
          return a.locator < b.locator
        end
        return a.name < b.name
      end

      local out = acc or {
        filesWithFlags = 0,
        flaggedFunctions = 0,
        worstOffenders = {},
      }
      local flagged = item and item.flaggedFunctions or {}

      if #flagged > 0 then
        out.filesWithFlags = (out.filesWithFlags or 0) + 1
      end

      for _, fn in ipairs(flagged) do
        thoth.push(out.worstOffenders, {
          locator = item.locator,
          kind = fn.kind,
          name = fn.name,
          cognitiveComplexity = fn.cognitiveComplexity,
          cyclomaticComplexity = fn.cyclomaticComplexity,
          tokens = fn.tokens,
          loc = fn.loc,
          sloc = fn.sloc,
        })
        out.flaggedFunctions = (out.flaggedFunctions or 0) + 1
      end

      table.sort(out.worstOffenders, worseFirst)

      return out
      """
  }

  output: {
    out: "./temp/pipeline-dart-function-thresholds.json"
    pretty: true
    lines: false
  }

  ui: {
    progress: true
    progressIntervalMs: 250
  }
}
