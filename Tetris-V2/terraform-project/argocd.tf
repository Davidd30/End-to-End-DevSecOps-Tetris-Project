resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.7"

 
  depends_on = [module.eks_module] 

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
}