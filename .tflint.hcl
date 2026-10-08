# Built-in Terraform ruleset: checks for missing version constraints,
# unused declarations, deprecated syntax and similar best-practice issues.
# The AWS-specific ruleset is added on Day 3, once we have real resources.
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
