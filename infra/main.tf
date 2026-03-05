terraform {
  required_version = ">= 1.5.0"

  required_providers {
    render = {
      source  = "render-oss/render"
      version = ">= 1.7.0"
    }
  }

  backend "s3" {}
}

provider "render" {
  api_key  = var.render_api_key
  owner_id = var.render_owner_id
}

module "app" {
  source = "git::https://github.com/dviramontes/terraform-render-preview-module.git//modules/render-preview-stack?ref=v0.1.1"

  is_preview = var.is_preview
  pr_number  = var.pr_number

  name_prefix      = "loteria"
  region           = "ohio"
  web_plan_prod    = "starter"
  web_plan_preview = "starter"
  create_postgres  = false

  runtime_source = {
    docker = {
      repo_url = "https://github.com/dviramontes/loteria"
      branch   = "main"
    }
  }

  previews_generation = var.is_preview ? "manual" : "off"

  env_vars = {
    SECRET_KEY_BASE = {
      generate_value = true
    }
    PHX_SERVER = {
      value_prod    = "true"
      value_preview = "true"
    }
    PHX_HOST = {
      value_prod    = "loteria.onrender.com"
      value_preview = var.pr_number != null ? "loteria-pr-${var.pr_number}.onrender.com" : null
    }
  }
}
