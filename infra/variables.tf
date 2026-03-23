variable "render_api_key" {
  description = "Render API key."
  type        = string
  sensitive   = true
}

variable "render_owner_id" {
  description = "Render owner ID (usr- or tea-)."
  type        = string
}

variable "is_preview" {
  description = "Whether this run targets a preview environment."
  type        = bool
  default     = false
}

variable "pr_number" {
  description = "Pull request number. Set for preview runs."
  type        = number
  default     = null
}

variable "secret_key_base" {
  description = "Phoenix secret key base (at least 64 bytes)."
  type        = string
  sensitive   = true
}
