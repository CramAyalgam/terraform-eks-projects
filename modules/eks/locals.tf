# Sample Role Format: arn:aws:iam::180789647333:role/hr-dev-eks-nodegroup-role
# Locals Block
locals {
  name = "marc-eks"
  configmap_roles = [
      {
      #rolearn  = "${aws_iam_role.eks_admin_role.arn}"
      rolearn  = "arn:aws:iam::038540414823:role/AWSReservedSSO_AdministratorAccess_f343585ea4bd6b67"
      username = "eks-admin" # Just a place holder name
      groups   = ["system:masters"]
      },   
      {
        #rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.eks_nodegroup_role.name}"
        rolearn = "${aws_iam_role.eks_nodegroup_role.arn}"
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
  ]
  /*
  configmap_users = [
      {
      userarn  = "${aws_iam_user.basic_user.arn}"
      username = "${aws_iam_user.basic_user.name}"
      groups   = ["system:masters"]
      },
      {
      userarn  = "${aws_iam_user.admin_user.arn}"
      username = "${aws_iam_user.admin_user.name}"
      groups   = ["system:masters"]
      },    
  ]
  */
  # Extract OIDC Provider from OIDC Provider ARN
  aws_iam_oidc_connect_provider_arn = "${aws_iam_openid_connect_provider.oidc_provider.arn}"
  aws_iam_oidc_connect_provider_extract_from_arn = element(split("oidc-provider/", "${aws_iam_openid_connect_provider.oidc_provider.arn}"), 1)
  
}