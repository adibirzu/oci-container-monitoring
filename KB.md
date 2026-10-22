# oci-container-monitoring knowledge base

Troubleshooting reference. Read it only when an error occurs, not at session start.
Cross-cutting OCI, OKE, IAM and networking issues live in the shared OCI-DEMO KB: `~/dev/OCI-DEMO/KB.md`
(search it with `python3.11 ~/dev/OCI-DEMO/scripts/knowledge_lookup.py --query '<error>'`).

Add an entry after every error that needed investigation and a fix. Use the next number.

## Entry format

```
## KB-NNN: <component> - <short symptom>
- Error: <exact message>
- Root cause: <what was actually wrong>
- Fix: <what changed, with file/command>
- Prevention: <how to avoid it next time>
```
