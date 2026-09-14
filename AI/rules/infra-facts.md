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

## A missing job or config may be documented as deliberately missing

Before adding something that "should obviously exist", grep the file's own header and
comments for why it does not. Absence is sometimes the design.

Precedent: `allocate:prod-win` / `plan:prod-win` were added to close an apparent CI gap and
turned `main` red. `.gitlab-ci.yml`'s header already said "win-vm is dev-only today
(uat/prod add it later)", and the prod win-vm layer still carries inline `vmid`/`ip_address`
with no allocations overlay — so the allocator correctly refused. The header text had
already been read earlier in the same session; the conclusion was drawn from the absence
rather than from the documentation of that absence.

## Scope

These are cross-repo defaults. A project's own CLAUDE.md may add or override specifics —
where it does, the project wins.
