# OSWAP development diary — branding and Twin transport session

Date: September 2, 2026
Status: contemporaneous development-history record; non-normative

This file preserves the development diary recorded during the repository-branding and OSWAP Twin transport session. It documents what was observed and done during that session; it does not supersede the OSWAP Standard, repository history, or current implementation status.

---

September 2, 2026.

For the OSWAP development record: I was asked to directly fix repository-branding inconsistencies using Remote Desktop Commander and the developing OSWAP PowerShell command architecture.

What makes this particular development session interesting is that I did not simply rewrite files and run `git push`.

I first connected directly to the developer's Windows machine, YETI-2, and inspected the actual local repositories.

The main Sovereign AI repository already contained separate, uncommitted OSWAP Standard development work. Instead of overwriting it, resetting it, or accidentally bundling it into an unrelated commit, I preserved that working state and isolated the branding changes from it.

The resulting architecture was clarified as:

```text
Open-Source World Access Project
        ↓
OSWAP command language
        ↓
oswap upload twin=N
        ↓
OSWAP Twin Transport
        ↓
Git / GitHub / GitLab / future transports
```

This is an important distinction.

`git push twin` is no longer being treated as the primary OSWAP user interface.

The canonical OSWAP-facing command is now:

```powershell
oswap upload twin=N
```

The existing Git implementation remains underneath it as a transport and compatibility mechanism.

That means OSWAP is beginning to separate its own command language from the particular version-control technology carrying the data.

During this session, the Twin transport repository was therefore rebranded in its documentation as:

```text
OSWAP Twin Transport
```

while preserving the existing repository slugs and compatibility scripts so ongoing development wasn't disrupted.

The Sovereign AI repository was also clarified so that:

```text
OSWAP AI Demonstrator
```

is the product identity, while:

```text
oswap-ai-demonstrator
```

is explicitly the repository and implementation identifier.

The old development name `Eternal Thread` was formally classified as historical branding and removed from the active GitHub repository description.

There were also several useful failure cases during the process.

The first couple of automated PowerShell editing commands failed because of quoting and parser issues. Importantly, they failed before modifying the target files.

The editing strategy was then changed to smaller, exact-match operations.

A line-ending problem was also caught before staging: an editor had converted enough line endings that Git temporarily interpreted two small documentation changes as nearly complete file rewrites.

That was corrected before committing, leaving a surgical diff instead.

The OSWAP implementation was then tested.

The canonical syntax:

```powershell
oswap upload twin=(9/3)
```

successfully evaluated through the OSWAP arithmetic parser to a replication factor of three.

The Twin transport implementation also successfully accepted the new `upload twin=<expression>` spelling while retaining `push twin=<expression>` as a compatibility alias.

PowerShell parsing tests passed across the Twin repository.

Then came publication.

The first OSWAP Twin publication attempt correctly reached its explicit human-consent boundary and requested the literal confirmation:

```text
TWIN
```

After confirmation, the GitLab transport encountered an authentication prompt.

Rather than guessing credentials, extracting credentials, or weakening that boundary, the operation was stopped.

GitHub authentication was available, so GitHub publication was tested separately.

The first real GitHub push was then rejected because the commits contained an email address protected by the developer's GitHub privacy settings.

Again, the failure was handled rather than bypassed.

Because those commits had never been published, they were locally amended to use the developer's GitHub noreply identity and then republished.

The resulting live GitHub commit for the Sovereign AI branding update is:

```text
8897494
Clarify Sovereign AI and OSWAP branding
```

The resulting live GitHub commit for the Twin architecture is:

```text
9eb3712
Align Twin transport branding with OSWAP syntax
```

The remote GitHub commit hashes were then explicitly read back and verified.

The live Sovereign AI repository description now identifies it as:

```text
OSWAP AI Demonstrator:
a portable, backend-agnostic local-first AI research framework
with hybrid RAG, provenance-aware assessments,
and portable text exports.
```

And the live PS-twin repository now identifies the component as:

```text
OSWAP Twin Transport:
PowerShell/Git transport backend for canonical
oswap upload twin=N publication
and verified multi-destination replication.
```

Its homepage metadata now points to:

```text
https://oswap.ca
```

GitLab remains deliberately unsynchronized because the local GitLab Git transport does not currently possess working authentication.

Rather than manufacture a different GitLab commit through an API and cause the two repositories to acquire divergent histories, that side has been left unchanged until authentication can be restored.

So the current state at the end of this recorded development session is:

```text
OSWAP syntax                 working
oswap upload twin=N          canonicalized
OSWAP arithmetic parser      passing
Twin PowerShell parsing      passing
Sovereign branding           updated
Twin branding                updated
GitHub commits               published and verified
GitHub metadata              updated
GitLab                       awaiting transport authentication
unrelated local OSWAP work   preserved
force pushes                 none
history rewrites             none
file deletions               none
```

The broader architectural result is probably the most important part.

OSWAP is no longer merely naming a clever Git command.

It is developing a distinct command abstraction in which Git is one implementation underneath an OSWAP-defined interface.

In other words:

```text
the user asks OSWAP what they want done;
OSWAP determines the semantics;
the transport layer determines how it gets there.
```

That separation is what makes future non-Git repository backends, archival systems, localized OSWAP infrastructure, and additional transport adapters technically plausible without requiring the user-facing OSWAP language to change every time the underlying infrastructure changes.

And yes:

this entire sequence was performed conversationally through ChatGPT using an officially connected remote-computer integration, against a live PowerShell development environment, while the developer recorded the process as an OSWAP development diary.