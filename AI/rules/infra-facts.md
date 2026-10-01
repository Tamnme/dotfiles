# Infrastructure facts — do not guess

Before proposing any infrastructure design, enumerate the facts the design rests on and
mark each **VERIFIED** (naming the command or file that proves it) or **ASSUMED**. Go
verify the assumed ones against the live system, then show the corrected list. Do not
write the design until the list is clean.

This exists because the same four assumptions below were corrected by hand across three
separate sessions, and two of them had already shipped as defects.

## Standing facts

- **HAProxy and Patroni already exist** as the external LB / DB layer. Do not propose
  in-cluster stateful replacements, and do not put a new load balancer in front of
  masters. Check what is already serving the role before adding one.
- **VM IPs and VMIDs are allocated from NetBox.** Never hardcode inline IPs or VMIDs in
  VM definitions, Ansible roles, or Terraform. Query NetBox; add prefixes and bands there.
- **Persistent data never lands on the OS volume.** Use dedicated data volumes.
- **Read the real cluster state, not the repo.** Use the actual kubeconfig — repo files
  describe intent, which may not match what is running. Topology inferred from a repo
  tree is an assumption, not a fact.

## Confirm the deployment mechanism before editing anything

Before touching a `values.yaml`, manifest, or config file, establish **how it is actually
deployed**: ArgoCD Application, Helm release, Talos-baked manifest, or Ansible template.
Look for an ArgoCD Application referencing the path before assuming a local Helm deploy.

**Never edit an untracked local copy of managed config.** An untracked file next to
managed config is usually a scratch copy, not the source of truth — editing it produces
work that silently does nothing. This cost a full wasted editing pass on SigNoz, where
the stack was ArgoCD-managed with a hand-created Application as the real source.

## A rename is a delete plus a create

Before proposing to rename or move any live GitOps-managed object, check **finalizers and
ownerReferences on what it manages**, not just on the object itself. Those two fields alone
decide whether a rename is free or destructive, and both are cheap to read.

Precedent: renaming the ArgoCD `apps` ApplicationSet looked like a tidy-up. Its generated
Applications carried `resources-finalizer.argocd.argoproj.io`, so the ownerReference cascade
would have deleted the live dev workloads. The sibling case was the opposite — the `root`
Application had no finalizer and its ApplicationSets were tracked only by the
`argocd.argoproj.io/tracking-id` annotation, so renaming *that* was genuinely free. Same
operation, opposite blast radius, and only the live objects could tell them apart.

## Check whether config was ever applied

**A Terraform/Terragrunt `dependency` needs state, not a directory.** List the backend before
wiring one stack to another — a directory holding `terragrunt.hcl` + `import.tf` looks identical
to a working stack, and a dependency on a stateless one silently returns `mock_outputs` instead
of failing. Same check before copying values out of a sibling env: unapplied config records what
someone intended, and nothing has ever tested it.

Precedent: `envs/sit` had state for 2 of 9 stacks. A cross-env dependency design was approved and
half-written before a plan surfaced `vpc_id = "vpc-00000000"`. Two defects then shipped from
copying sit's committed values — a read-only Valkey `access_string`, and an MSK `scram_username`
left at the module default — neither of which had ever run anywhere.

## Making a step unconditional is a first run on every host

Before merging a change that makes a deploy step run where it did not before, run that step's
precondition against every real host. A path that has never executed on a host has never been
tested against its state — "unconditional" is a deploy of untested code to all of them at once.
Writing the risk into the MR description is not mitigation.

Precedent: `apply_config` was moved out of two case arms to run on every deploy. On uat it had
never run (both prior deploys were `upgrade`) and `conf/.render-env` did not exist. The MR said
"a missing .render-env now fails every deploy"; nobody ran `cut -d= -f1 ~/odoo/conf/.render-env`
first. Result: seven failed deploys over a day, and — because each died after the symlink
swap — every intervening rehearsal degraded to `-u all`, 19 minutes instead of 5.

## A tag on a resource is not a tag activated for billing

**Tagging resources and being able to group cost by that tag are two separate systems.** Check
`aws ce list-cost-allocation-tags` before planning any cost measurement, and note that
activation is **not retroactive** — data accrues from activation forward, so switching it on
does not recover the window you wanted to measure.

Precedent: every POC resource carried `project=hybrid-poc` via terraform `default_tags`, and
every Cost Explorer query filtered on it returned `0.00` for four consecutive days while the
same window unfiltered showed $3.87 / $4.62 / $1.05. The tag's status was `Inactive`, and no
cost-allocation tag was Active in that account at all. A go/no-go decision had been scheduled
against a soak that was collecting nothing and never would have — and the zeros read as
"cheaper than expected" rather than as "not instrumented".

## A missing job or config may be documented as deliberately missing

Before adding something that "should obviously exist", grep the file's own header and
comments for why it does not. Absence is sometimes the design.

Precedent: `allocate:prod-win` / `plan:prod-win` were added to close an apparent CI gap and
turned `main` red. `.gitlab-ci.yml`'s header already said "win-vm is dev-only today
(uat/prod add it later)", and the prod win-vm layer still carries inline `vmid`/`ip_address`
with no allocations overlay — so the allocator correctly refused. The header text had
already been read earlier in the same session; the conclusion was drawn from the absence
rather than from the documentation of that absence.

## Read the working sibling, not just the cluster

Before adding a workload beside one that already works, **diff your new security group,
task definition and IAM policy against the working one's**. The sibling is a tested answer
to the same network; deriving your own from first principles re-discovers its constraints
as outages.

Precedent: a POC Fargate task placed beside a proven gateway took five failed task starts —
Secrets Manager unreachable (no interface endpoint, no NAT), the shared endpoint SG
admitting only the proven task's SG, egress allowing the VPC CIDR but not the S3/DynamoDB
**prefix lists** that gateway endpoints actually route, the ALB SG egress locked to the
proven port, and the harness SG likewise. Every one was already answered in
`sg-0ea3b93fe538a2416` and two `describe-security-groups` calls. Each surfaced as a
symptom pointing elsewhere: an ECR `i/o timeout` that looked like routing, and a
`Target.Timeout` while the container logged `Uvicorn running` throughout. The same omission
made a gate pass for the wrong reason earlier in that session — a tenant role's trust
policy, unread, named exactly one principal that no local caller could ever be, so the
"wrong ExternalId is refused" test was really just observing the caller refused outright.

## Scope

These are cross-repo defaults. A project's own CLAUDE.md may add or override specifics —
where it does, the project wins.
