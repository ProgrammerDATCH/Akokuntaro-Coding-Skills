#!/bin/sh
# Refuse to push the local-only `combined-preview` branch (gokabisa-habits: test open PRs together
# locally; every change goes on the PR branches). git passes "<local ref> <sha> <remote ref> <sha>"
# lines on stdin; any line that names combined-preview, on either side, stops the push.
while read -r local_ref _local_sha remote_ref _remote_sha; do
  case "$local_ref $remote_ref" in
    *refs/heads/combined-preview*)
      echo "pre-push: combined-preview is local only and is never pushed." >&2
      echo "Commit the change on its PR branch, push that, and rebuild combined-preview." >&2
      exit 1
      ;;
  esac
done
exit 0
