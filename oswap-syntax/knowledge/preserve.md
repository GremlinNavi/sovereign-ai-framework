# `preserve`

SPDX-License-Identifier: Apache-2.0

`oswap preserve` is the prompt-driven sensitive-record preservation workflow defined by the OSWAP Standard.

It is defensive infrastructure. It does not inspect another person's accounts or devices, remove monitoring software, disable security controls, or promise invisibility.

## Workflow

The reference implementation:

1. requires acknowledgement that the operation is being performed on a trusted device;
2. prompts for the source file or directory;
3. copies the source into a temporary staging area without modifying the original;
4. computes SHA-256 for staged files and writes an internal manifest;
5. compresses the staged package;
6. invokes `age -p` so the encryption passphrase is entered interactively rather than as a command-line argument;
7. deletes temporary plaintext staging material on normal cleanup;
8. writes a generic ciphertext package and non-sensitive ciphertext receipt;
9. optionally stages only the ciphertext and receipt into an existing Git repository approved by the user for sensitive encrypted archives;
10. invokes `oswap push twin=<expression>` for semi-random remote replication after explicit confirmation.

Deletion of temporary plaintext is best-effort. Modern storage may retain recoverable blocks. If the device may be monitored or seized, use a different trusted device rather than relying on cleanup or stealth.

## External dependency

The reference workflow requires the open-source `age` command-line tool for encryption before remote replication. `age` is an external dependency and retains its own license.

## Example twin factor

```text
oswap push twin=(4+3)/2
```

resolves to a factor of `3.5`: three whole destination copies are guaranteed and a fourth destination is selected with 50% probability. No fractional file or repository is created.

## Disclosure

Creating or replicating a preservation package does not disclose its contents. Decryption credentials remain separate and under user control.
