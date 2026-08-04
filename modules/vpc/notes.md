# Count, for_each, and Dynamic Blocks

## The Problem This Solves
- Before today: writing separate near-identical resource blocks per subnet
  (public_subnet_1, public_subnet_2) — scaling meant manually copy-pasting more blocks
- count and for_each let ONE resource block generate MANY resources,
  driven by a list/map — scaling means changing a variable, not rewriting code

## count — the simpler, older mechanism
count = 2
- Creates the resource N times
- count.index = current iteration number (0, 1, 2...)
- Resources addressed by NUMERIC INDEX: aws_subnet.public[0], aws_subnet.public[1]

## The Real Problem With count
- Delete the middle item from a list of 3 → Terraform doesn't know "the middle
  one is gone," it only sees index positions shift
- [2] becomes [1] → Terraform sees this as destroy old [1]/[2], create new ones
- Can cause unnecessary destroy/recreate of resources that didn't actually need to change

## for_each — the one to use almost always
for_each = toset(var.availability_zones)
- Addresses resources by STABLE KEY (string), not position:
  aws_subnet.public["us-east-1a"], aws_subnet.public["us-east-1b"]
- Remove one AZ from the list → Terraform knows EXACTLY which resource that was,
  destroys only that one, everything else untouched
- This stability is the whole reason for_each is generally preferred

## each.key vs each.value
- Looping over a SET (toset(list)): each.key == each.value (no separate keys in a set)
- Looping over a MAP: each.key = the map key, each.value = that key's value

## count vs for_each — when to use which
- for_each: items have meaningful identity (subnets per AZ, buckets per purpose) — DEFAULT CHOICE
- count: genuinely identical, interchangeable copies with no distinguishing identity
- Rule of thumb: default to for_each, only use count for truly generic N copies

## for Expressions — Already Using These Since Day 5/8
[for s in aws_subnet.public_subnet : s.id]
- Loops through a map (created by for_each), pulls out one attribute per entry,
  builds a clean list
- Needed because for_each resources are MAPS, not single objects —
  no plain .id exists without specifying which key

## Splat Operator [*]
aws_subnet.public[*].id
- Shorthand ONLY for count-based resources (produces a list, not a map)
- Does NOT work the same way on for_each resources — use for expression instead
- Less flexible than for expression, just grabs one attribute from every instance

## Dynamic Blocks — Looping INSIDE a Resource
- Different from for_each at the resource level — this loops to generate
  repeated NESTED blocks (like multiple ingress rules) within ONE resource
- Syntax:
  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      description = ingress.value.description   # NOT local.ingress_rules directly
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
- Inside content{}, reference the loop var as <dynamic_block_name>.value —
  named after the dynamic block's label, NOT each.value
- Don't force everything into dynamic blocks — fine to mix dynamic + regular
  blocks in the same resource when only some rules need to be dynamic

## Why ingress_rules Had to Move from variable to locals
- variable defaults CANNOT reference other variables (var.my_ip inside a
  variable's default = [...] → hard error, "Variables may not be used here")
- Same category of restriction as the backend block issue from Day 4 —
  a chicken-and-egg problem, values not resolved yet at that stage
- locals ARE allowed to reference variables — they're computed AFTER
  variables are already resolved
- Fix: move the list from `variable "ingress_rules" { default = [...] }`
  to `locals { ingress_rules = [...] }`
- File location (locals.tf vs main.tf) doesn't matter — Terraform reads all
  .tf files in a folder as one combined whole. What matters is the BLOCK TYPE
  (locals vs variable), not which file it's written in

## The Big Lesson From Today — Converting to for_each Ripples Outward
- Switching a resource to for_each doesn't just change that resource —
  it changes how EVERY OTHER resource that references it must be written
- Before: aws_subnet.public_subnet_1.id (single object, direct .id)
- After for_each: aws_subnet.public_subnet["us-east-1a"].id (map, needs a key)
- Had to fix: route table associations (rewrite as single for_each block
  looping over the subnet map), NAT Gateway's subnet_id (index into map
  with specific AZ key), outputs.tf (for expression instead of direct .id x2)

## Renaming Resources After for_each Refactor
- public_subnet_1/public_subnet_2 → public_subnet (singular, no number)
  makes more sense once for_each handles the "multiple" part internally
- Renaming a resource = new address to Terraform = destroy + recreate,
  even if the underlying AWS resource would be identical
- Fine for a learning project (low stakes), NOT fine on real running
  production infrastructure without extra care
- Real fix for production: a `moved` block — tells Terraform "old name and
  new name are the same resource, just update your records, don't touch AWS"
  (mentioned in Day 13 topics, not needed yet)

## My Mistakes Today
- Left type/default inside a locals block — locals never have type or default,
  those are variable-only concepts. Just direct assignment: locals { name = value }
- cidr_block vs cidr_blocks typo again inside the ingress_rules list —
  every object in a list must have IDENTICAL keys, one typo breaks all entries
- Referenced local.ingress_rules directly inside content{} instead of
  ingress.value.X — dynamic blocks use their own loop variable, not the
  original local/variable name
- Forgot to update ALL references after renaming public_subnet_1 → public_subnet
  (NAT Gateway's subnet_id was the one that got missed)
- Missing protocol = "tcp" inside the dynamic ingress content block —
  required argument, easy to forget when converting from static blocks

## Commands / Workflow
git add modules/
git status                    # confirm only the intended files changed
git commit -m "..."
git push                      # pushing changes to an already-tracked folder
                               # works exactly like any other commit — Git
                               # tracks file-level diffs, not "folder already pushed" status

## Key Takeaway
Real debugging today wasn't about the for_each/dynamic block CONCEPTS themselves —
those were understood correctly from the start. The bugs were all about the
RIPPLE EFFECTS of that change across a file with interconnected references.
That's the actual skill being built: tracing every place a change touches,
not just the line you're directly editing.