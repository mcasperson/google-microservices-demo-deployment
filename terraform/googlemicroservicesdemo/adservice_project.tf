locals {
  adservice_package_id          = "octopussamples/adservice"
  adservice_package_name        = "adservice"
  adservice_resource_names      = "adservice#{unless Octopus.Release.Channel.Name == \"Mainline\"}-#{Octopus.Release.Channel.Name}#{/unless}"
  adservice_project_name        = "Ad Service"
  adservice_project_description = "Deploys the ad service."
  adservice_service_ports       = jsonencode([
    {
      name : "grpc",
      port : "9555",
      targetPort : "9555"
    }
  ])
  adservice_containers = jsonencode([
    {
      IsNew : true,
      InitContainer : "False",
      Ports : [
        {
          value : "9555"
        }
      ],
      EnvironmentVariables : [
        {
          key : "PORT",
          value : "9555"
        },
        {
          key : "DISABLE_STATS",
          value : "1"
        },
        {
          key : "DISABLE_TRACING",
          value : "1"
        }
      ],
      SecretEnvironmentVariables : [],
      SecretEnvFromSource : [],
      ConfigMapEnvironmentVariables : [],
      ConfigMapEnvFromSource : [],
      FieldRefEnvironmentVariables : [],
      VolumeMounts : [],
      AcquisitionLocation : "NotAcquired",
      Name : local.adservice_package_name
      PackageId : local.adservice_package_id
      FeedId : var.octopus_dockerhub_feed_id
      Properties : {

      },
      Command : [],
      Args : [],
      Resources : {
        requests : {
          memory : "180Mi",
          cpu : "200m",
          ephemeralStorage : ""
        },
        limits : {
          memory : "300Mi",
          cpu : "300m",
          ephemeralStorage : "",
          nvidiaGpu : "",
          amdGpu : ""
        }
      },
      LivenessProbe : {
        failureThreshold : "",
        initialDelaySeconds : "20",
        periodSeconds : "15",
        successThreshold : "",
        timeoutSeconds : "",
        type : "Command",
        exec : {
          command : [
            "/bin/grpc_health_probe",
            "-addr=:9555"
          ]
        },
        httpGet : {
          host : "",
          path : "",
          port : "",
          scheme : "",
          httpHeaders : []
        },
        tcpSocket : {
          host : "",
          port : ""
        }
      },
      ReadinessProbe : {
        failureThreshold : "",
        initialDelaySeconds : "20",
        periodSeconds : "15",
        successThreshold : "",
        timeoutSeconds : "",
        type : "Command",
        exec : {
          command : [
            "/bin/grpc_health_probe",
            "-addr=:9555"
          ]
        },
        httpGet : {
          host : "",
          path : "",
          port : "",
          scheme : "",
          httpHeaders : []
        },
        tcpSocket : {
          host : "",
          port : ""
        }
      },
      StartupProbe : {
        failureThreshold : "",
        initialDelaySeconds : "",
        periodSeconds : "",
        successThreshold : "",
        timeoutSeconds : "",
        type : null,
        exec : {
          command : []
        },
        httpGet : {
          host : "",
          path : "",
          port : "",
          scheme : "",
          httpHeaders : []
        },
        tcpSocket : {
          host : "",
          port : ""
        }
      },
      Lifecycle : {

      },
      SecurityContext : {
        allowPrivilegeEscalation : "false",
        privileged : "false",
        readOnlyRootFilesystem : "true",
        runAsGroup : "",
        runAsNonRoot : "",
        runAsUser : "",
        capabilities : {
          add : [],
          drop : ["all"]
        },
        seLinuxOptions : {
          level : "",
          role : "",
          type : "",
          user : ""
        }
      }
    }
  ])
}

resource "octopusdeploy_project" "adservice_project" {
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  description                          = local.adservice_project_description
  discrete_channel_release             = false
  is_disabled                          = false
  is_discrete_channel_release          = false
  is_version_controlled                = false
  lifecycle_id                         = var.octopus_application_lifecycle_id
  name                                 = local.adservice_project_name
  project_group_id                     = octopusdeploy_project_group.google_microservice_demo.id
  tenanted_deployment_participation    = "Untenanted"
  space_id                             = var.octopus_space_id
  included_library_variable_sets       = []
  versioning_strategy {
    template = local.versioning_strategy
  }

  connectivity_policy {
    allow_deployments_to_no_targets = false
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "SkipUnavailableMachines"
  }
}

resource "octopusdeploy_channel" "adservice_mainline" {
  name        = "Mainline"
  project_id  = octopusdeploy_project.adservice_project.id
  description = "The channel through which mainline releases are deployed"
  depends_on  = [octopusdeploy_deployment_process.adservice_deployment_process]
  is_default  = true
  rule {
    tag = "^$"
    action_package {
      deployment_action = local.deployment_step
      package_reference = local.adservice_package_name
    }
  }
  rule {
    tag = "^$"
    action_package {
      deployment_action = local.check_for_vulnerabilities_step
      package_reference = "${local.adservice_package_name}-sbom"
    }
  }
}

resource "octopusdeploy_variable" "adservice_debug_variable" {
  name         = "OctopusPrintVariables"
  type         = "String"
  description  = "A debug variable used to print all variables to the logs. See [here](https://octopus.com/docs/support/debug-problems-with-octopus-variables) for more information."
  is_sensitive = false
  owner_id     = octopusdeploy_project.adservice_project.id
  value        = "False"
}

resource "octopusdeploy_variable" "adservice_debug_evaluated_variable" {
  name         = "OctopusPrintEvaluatedVariables"
  type         = "String"
  description  = "A debug variable used to print all variables to the logs. See [here](https://octopus.com/docs/support/debug-problems-with-octopus-variables) for more information."
  is_sensitive = false
  owner_id     = octopusdeploy_project.adservice_project.id
  value        = "False"
}

resource "octopusdeploy_deployment_process" "adservice_deployment_process" {
  project_id = octopusdeploy_project.adservice_project.id
  step {
    condition           = "Success"
    name                = local.deployment_step
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"
    target_roles        = [local.deployment_role]
    action {
      action_type           = "Octopus.KubernetesDeployContainers"
      name                  = local.deployment_step
      run_on_server         = true
      worker_pool_id        = local.worker_pool_id
      excluded_environments = [
        var.octopus_development_security_environment_id,
        var.octopus_production_security_environment_id
      ]
      environments = []
      features     = ["Octopus.Features.KubernetesService"]
      package {
        name                      = local.adservice_package_name
        package_id                = local.adservice_package_id
        feed_id                   = var.octopus_dockerhub_feed_id
        acquisition_location      = "NotAcquired"
        extract_during_deployment = false
      }
      container {
        feed_id = var.octopus_dockerhub_feed_id
        image   = local.worker_image
      }
      properties = {
        "Octopus.Action.KubernetesContainers.Replicas" : "1",
        "Octopus.Action.KubernetesContainers.DeploymentStyle" : "RollingUpdate",
        "Octopus.Action.KubernetesContainers.ServiceNameType" : "External",
        "Octopus.Action.KubernetesContainers.DeploymentResourceType" : "Deployment",
        "Octopus.Action.KubernetesContainers.DeploymentWait" : "Wait",
        "Octopus.Action.KubernetesContainers.ServiceType" : "ClusterIP",
        "Octopus.Action.KubernetesContainers.IngressAnnotations" : "[]",
        "Octopus.Action.KubernetesContainers.PersistentVolumeClaims" : "[]",
        "Octopus.Action.KubernetesContainers.Tolerations" : "[]",
        "Octopus.Action.KubernetesContainers.NodeAffinity" : "[]",
        "Octopus.Action.KubernetesContainers.PodAffinity" : "[]",
        "Octopus.Action.KubernetesContainers.PodAntiAffinity" : "[]",
        "Octopus.Action.KubernetesContainers.Namespace" : local.namespace,
        "Octopus.Action.KubernetesContainers.DeploymentName" : local.adservice_resource_names,
        "Octopus.Action.KubernetesContainers.TerminationGracePeriodSeconds" : "5",
        "Octopus.Action.KubernetesContainers.DnsConfigOptions" : "[]",
        "Octopus.Action.KubernetesContainers.PodAnnotations" : "[]",
        "Octopus.Action.KubernetesContainers.DeploymentAnnotations" : "[]",
        "Octopus.Action.KubernetesContainers.DeploymentLabels" : "{\"app\":\"${local.adservice_package_name}\"}",
        "Octopus.Action.KubernetesContainers.CombinedVolumes" : "[]",
        "Octopus.Action.KubernetesContainers.PodSecurityFsGroup" : "1000",
        "Octopus.Action.KubernetesContainers.PodSecurityRunAsGroup" : "1000",
        "Octopus.Action.KubernetesContainers.PodSecurityRunAsNonRoot" : "true",
        "Octopus.Action.KubernetesContainers.PodSecuritySysctls" : "[]",
        "Octopus.Action.KubernetesContainers.PodServiceAccountName" : "default",
        "Octopus.Action.KubernetesContainers.Containers" : local.adservice_containers,
        "Octopus.Action.KubernetesContainers.PodSecurityRunAsUser" : "1000",
        "Octopus.Action.KubernetesContainers.ServiceName" : local.adservice_resource_names,
        "Octopus.Action.KubernetesContainers.LoadBalancerAnnotations" : "[]",
        "Octopus.Action.KubernetesContainers.ServicePorts" : local.adservice_service_ports
        "Octopus.Action.RunOnServer" : "true"
      }
    }
  }
  step {
    condition           = "Success"
    name                = "Check for Vulnerabilities"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"
    run_script_action {
      can_be_used_for_project_versioning = false
      condition                          = "Success"
      is_disabled                        = false
      is_required                        = true
      script_syntax                      = "Bash"
      script_source                      = "Inline"
      run_on_server                      = true
      worker_pool_id                     = local.worker_pool_id
      name                               = "Check for Vulnerabilities"
      notes                              = "Scans the SBOM for any known vulnerabilities."
      environments                       = [
        var.octopus_development_security_environment_id,
        var.octopus_production_security_environment_id
      ]
      package {
        name                      = "adservice-sbom"
        package_id                = "microservices-demo:adservice-sbom"
        feed_id                   = octopusdeploy_maven_feed.github_maven_feed.id
        acquisition_location      = "Server"
        extract_during_deployment = true
      }
      script_body = local.vulnerability_scan
    }
  }
}