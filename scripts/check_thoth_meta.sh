#!/bin/sh

set -eu

status=0
: "${YQ:=yq}"

check_orphans() {
  meta_root="$1"
  prefix="$2"

  if [ ! -d "$meta_root" ]; then
    return
  fi

  for meta_file in $(find "$meta_root" -name '*.thoth.yaml' | sort); do
    source_file="${meta_file#$prefix}"
    source_file="${source_file%.thoth.yaml}"
    if [ ! -f "$source_file" ]; then
      printf 'ORPHAN %s -> missing %s\n' "$meta_file" "$source_file"
      status=1
    fi
  done
}

check_missing_purpose() {
  meta_root="$1"
  prefix="$2"

  if [ ! -d "$meta_root" ]; then
    return
  fi

  for meta_file in $(find "$meta_root" -name '*.thoth.yaml' | sort); do
    source_file="${meta_file#$prefix}"
    source_file="${source_file%.thoth.yaml}"
    purpose="$("$YQ" -r '.meta.purpose // ""' "$meta_file")"
    if [ -f "$source_file" ] && [ -z "$purpose" ]; then
      printf 'MISSING_PURPOSE %s -> %s\n' "$meta_file" "$source_file"
      status=1
    fi
  done
}

check_orphans "thoth-meta/dart" "thoth-meta/dart/"
check_orphans "thoth-meta/dart-support" "thoth-meta/dart-support/"
check_orphans "thoth-meta/dart-test" "thoth-meta/dart-test/"
check_missing_purpose "thoth-meta/dart" "thoth-meta/dart/"
check_missing_purpose "thoth-meta/dart-support" "thoth-meta/dart-support/"

if [ "$status" -eq 0 ]; then
  printf 'OK no orphaned Thoth metadata files and no Dart metadata missing meta.purpose\n'
fi

exit "$status"
