# Diagnosis protocol

Applies to any debugging, root-cause, or "why is X broken" task.

## Hypotheses before a root cause

Do not open with a single root cause. Open with a ranked list — top 3–5 hypotheses, and
for each, **the single cheapest command that confirms or eliminates it**. Run them in
order, report which survive, then name the cause.

Committing to one theory early burns more turns than listing five. Failures here are
routinely stacked 2–6 layers deep, so the first plausible cause is usually a real
finding *and* not the whole answer.

## Every claim carries its evidence

State the command or file that proves each claim, and a confidence level. "The CA
filename is mismatched" is a guess; "`kubectl -n x get cm y -o yaml` shows `ca.crt` but
the deployment mounts `tls.crt`" is a finding. If a claim cannot be backed, mark it
ASSUMED and go verify it before building on it.

## A fix that does not fix it re-opens the diagnosis

If the symptom persists after a fix, **the diagnosis was wrong** — do not layer a second
fix on the first. Go back to the hypothesis list, mark what was refuted, and start again
from evidence.

Precedent: the gitlab-runner failure was diagnosed as a CA filename mismatch, fixed, and
still failed; the real cause was a double-`git.` typo in ArgoCD `extraEnv`. Same shape in
the ArgoCD 504, Odoo filestore, and SigNoz investigations.

## Distinguish misconfiguration from unreachability

Before concluding "component X is misconfigured", test L4 reachability. A blocked network
path and a bad config produce identical-looking application errors, and guessing between
them has cost whole sessions.

## Say when a hypothesis is refuted

Refutation is a result. State it explicitly rather than silently moving to the next idea —
it is what stops the next session from retrying the same dead end.

## A working-tree change that contradicts committed config is not automatically wrong

Before calling an uncommitted edit a scratch hack, check what the **consuming** system
actually reads — CI variables, the unit file, the job definition. The committed value is
the older claim, not the truer one.

Precedent: assumed committed `PROXMOX_PROD_TOKEN_SECRET` was correct and the working
tree's `PROXMOX_TOKEN_SECRET` was a local hack, then worked to keep it out of the commit.
It was the right value. `.gitlab-ci.yml` had carried a shim line bridging the two names
all along — one grep would have surfaced it before the wrong assumption shaped the commit.

## "It arrives but nothing answers" → read the receiver's counters first

When a capture proves packets reach the destination but no reply is generated, go to the
**receiver's** `/proc/net/snmp` before theorising, and match the protocol of the **inner**
header, not the outer one.

Precedent: a 3-month VXLAN black hole survived five wrong root causes (NIC offload, LACP,
Proxmox firewall, stale Cilium ipcache, PMTU) because `Tcp InCsumErrors` on the receiving
node was never checked. It was the only counter that moved, and `InErrs == InCsumErrors`
named the cause outright. UDP counters on the sender and TCP counters on the sender both
read clean the whole time, as did every Cilium drop counter — the discard happened in the
guest kernel, below every instrument that was being consulted.

## A blocked operation is not a blocked service

Before concluding a provider is unreachable, establish which **operations** are blocked.
Quotas, SCPs and policies gate individual API actions, not the endpoint — the control plane
and adjacent read APIs usually still answer, and one of them is often the oracle the
investigation needs. "We cannot call X" is a claim about one operation until tested.

Precedent: a Bedrock on-demand inference quota of zero org-wide was read as "Bedrock cannot
be called", and that framing was written into a fresh-eyes brief, two debate briefs and
three research documents before anyone tested it. `bedrock-runtime count-tokens` answered
on the first attempt — a real API call, real data, same account, same credentials — and
proved the token estimator under-counted in 10 of 12 cases, which was the highest-value
finding of the session and available from the first minute. The gate ledger had said "no
real *Converse*"; the generalisation to "no Bedrock" was mine, and nothing in the evidence
supported it. A `ValidationException` naming a model capability is the tell: it means the
call reached the service and was answered, so the service is not what is blocking you.

## Identify the real source before interpreting a probe

If the endpoint is a VIP, load balancer or Service, establish which backend actually served
the request before drawing conclusions from the result.

Precedent: probing `10.9.108.5` — a Talos **active/passive** VIP — made "three unreachable
nodes" look like a property of the targets. Addressing each apiserver directly showed it
was one *source* failing to reach three targets, which reframed the entire fault and was
what finally made the evidence legible.

## Naming the cheap experiment is not running it

When a note marks something UNVERIFIED and names the one command that would settle it, run
that command before shipping the note. An UNVERIFIED that could have been resolved for free
is a choice, and it propagates into every document that cites the first one.

Precedent: three documents in one session recorded that `CountTokens` is free, unblocked by
the zero inference quota, and the authoritative oracle for whether the token estimator
upper-bounds Bedrock's own count. None ran it. The estimate-fidelity question, load-bearing
for the recommendation those documents made, shipped unresolved — while `aws-vault` was
working in the same session for Price List queries.

## A corrected diagnosis has to be chased through the docs

When you record that a previous root cause was wrong, grep the repo for the old wording in
the same pass. The correction is worthless while the refuted version is still the first
thing a reader meets.

Precedent: a repo's CLAUDE.md carried "do not conclude Bedrock is unreachable" as a named
trap that had already cost several rounds. Its README still opened the Blocked section with
"Bedrock is unreachable from the target account ... a commercial restriction, not a
technical one" — the exact refuted diagnosis — and had done for multiple sessions.
