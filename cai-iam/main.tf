provider "aws" {}

variable "aws_account_id" {}
variable "cloud_trail_bucket_name" {}
variable "aws_region" {}

########################### Account Users ####################################
resource "aws_iam_user" "ALKSAdmin" {
	name = "ALKSAdmin"
	path = "/cai-managed/alks/iam/"
}

resource "aws_iam_user" "ALKSIAMAdmin" {
	name = "ALKSIAMAdmin"
	path = "/cai-managed/alks/iam/"
}

resource "aws_iam_user" "ALKSPowerUser" {
	name = "ALKSPowerUser"
	path = "/cai-managed/alks/"
}

resource "aws_iam_user" "ALKSReadOnly" {
	name = "ALKSReadOnly"
	path = "/cai-managed/alks/"
}

########################## Account Groups ######################################
resource "aws_iam_group" "AdminGroup" {
	name = "Admin"
	path = "/cai-managed/private/"
}

resource "aws_iam_group" "PowerUserGroup" {
	name = "PowerUser"
	path = "/cai-managed/private/"
}

resource "aws_iam_group" "ReadOnlyGroup" {
	name = "ReadOnly"
	path = "/cai-managed/private/"
}

resource "aws_iam_group" "IAMAdminGroup" {
	name = "IAMAdmin"
	path = "/cai-managed/private/"
}

###################### Assigning Account Users to Account Groups ##########################
resource "aws_iam_group_membership" "AdminGroupMembership" {
	name = "AdminGroupMembership"
	users = ["${aws_iam_user.ALKSAdmin.name}"]
	group = "${aws_iam_group.AdminGroup.name}"
}

resource "aws_iam_group_membership" "IAMAdminGroupMembership" {
	name = "IAMAdminGroupMembership"
	users = ["${aws_iam_user.ALKSIAMAdmin.name}"]
	group = "${aws_iam_group.IAMAdminGroup.name}"
}

resource "aws_iam_group_membership" "PowerUserGroupMembership" {
	name = "PowerUserGroupMembership"
	users = ["${aws_iam_user.ALKSPowerUser.name}"]
	group = "${aws_iam_group.PowerUserGroup.name}"
}

resource "aws_iam_group_membership" "ReadOnlyGroupMembership" {
	name = "ReadOnlyGroupMembership"
	users = ["${aws_iam_user.ALKSReadOnly.name}"]
	group = "${aws_iam_group.ReadOnlyGroup.name}"
}

######################### Account Roles ###########################################
resource "aws_iam_role" "AdminRole" {
	name = "Admin"
	path = "/cai-managed/private/"
	assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
	  {
		"Sid": "",
		"Effect": "Allow",
		"Principal": {
			"AWS": [
                  "arn:aws:iam::${var.aws_account_id}:user/cai-managed/alks/iam/ALKSAdmin"
			]
		},
		"Action": "sts:AssumeRole"
	  }
	 ]
}
EOF
}

resource "aws_iam_role" "IAMAdminRole" {
	name = "IAMAdmin"
	path = "/cai-managed/private/"
	assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
	  {
		"Sid": "",
		"Effect": "Allow",
		"Principal": {
			"AWS": [
				"arn:aws:iam::${var.aws_account_id}:user/cai-managed/alks/iam/ALKSIAMAdmin"
			]
		},
		"Action": "sts:AssumeRole"
	  }
	]
}
EOF
}

resource "aws_iam_role" "PowerUserRole" {
	name = "PowerUser"
	path = "/cai-managed/private/"
	assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
	  {
		"Sid": "",
		"Effect": "Allow",
		"Principal": {
			"AWS": [
				"arn:aws:iam::${var.aws_account_id}:user/cai-managed/alks/ALKSPowerUser"
			]
		},
		"Action": "sts:AssumeRole"
	  }
	]
}
EOF
}

resource "aws_iam_role" "ReadOnlyRole" {
	name = "ReadOnly"
	path = "/cai-managed/private/"
	assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
	  {
		"Sid": "",
		"Effect": "Allow",
		"Principal": {
			"AWS": [
				"arn:aws:iam::${var.aws_account_id}:user/cai-managed/alks/ALKSReadOnly"
			]
		},
		"Action": "sts:AssumeRole"
	  }
	]
}
EOF
}

######################### CAI Service Roles ###########################################

resource "aws_iam_role" "SvcCloudHealthRole" {
	name = "SvcCloudHealth"
	path = "/cai-managed/private/"
	assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::454464851268:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "C0x@uto-ch3398!"
        }
      }
    }
  ]
}
EOF
}

################# Standard ElasticBeanstalk IP and SR ################################

resource "aws_iam_instance_profile" "aws-elasticbeanstalk-ec2-role" {
    name = "aws-elasticbeanstalk-ec2-role"
    roles = ["${aws_iam_role.aws-elasticbeanstalk-ec2-role.name}"]
}

resource "aws_iam_role" "aws-elasticbeanstalk-ec2-role" {
    name = "aws-elasticbeanstalk-ec2-role"
    path = "/"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkWebTier" {
    role = "${aws_iam_role.aws-elasticbeanstalk-ec2-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkMulticontainerDocker" {
    role = "${aws_iam_role.aws-elasticbeanstalk-ec2-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkWorkerTier" {
    role = "${aws_iam_role.aws-elasticbeanstalk-ec2-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role" "aws-elasticbeanstalk-service-role" {
    name = "aws-elasticbeanstalk-service-role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "elasticbeanstalk"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkService" {
    role = "${aws_iam_role.aws-elasticbeanstalk-service-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkEnhancedHealth" {
    role = "${aws_iam_role.aws-elasticbeanstalk-service-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

########################### Policies ####################################
resource "aws_iam_policy" "CAICloudHealthPolicy" {
	#TODO - figure out how to set the deletion policy
	name = "CAICloudHealthPolicy"
	path = "/cai-managed/private/"
	policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
	  {
		"Effect": "Allow",
		"Action": [
			"aws-portal:ViewBilling",
            "aws-portal:ViewUsage",
            "autoscaling:Describe*",
            "cloudformation:ListStacks",
            "cloudformation:ListStackResources",
            "cloudformation:DescribeStacks",
            "cloudformation:DescribeStackEvents",
            "cloudformation:DescribeStackResources",
            "cloudformation:GetTemplate",
            "cloudfront:Get*",
            "cloudfront:List*",
            "cloudwatch:Describe*",
            "cloudwatch:Get*",
            "cloudwatch:List*",
            "dynamodb:DescribeTable",
            "dynamodb:ListTables",
            "ec2:Describe*",
            "elasticache:Describe*",
            "elasticache:ListTagsForResource",
            "elasticbeanstalk:Check*",
            "elasticbeanstalk:Describe*",
            "elasticbeanstalk:List*",
            "elasticbeanstalk:RequestEnvironmentInfo",
            "elasticbeanstalk:RetrieveEnvironmentInfo",
            "elasticloadbalancing:Describe*",
            "elasticmapreduce:Describe*",
            "elasticmapreduce:List*",
            "iam:List*",
            "iam:Get*",
            "lambda:List*",
            "redshift:Describe*",
            "route53:Get*",
            "route53:List*",
            "rds:Describe*",
            "rds:ListTagsForResource",
            "s3:List*",
            "s3:GetBucketTagging",
            "s3:GetBucketLocation",
            "s3:GetBucketLogging",
            "s3:GetBucketVersioning",
            "s3:GetBucketWebsite",
            "sdb:GetAttributes",
            "sdb:List*",
            "ses:Get*",
            "ses:List*",
            "sns:Get*",
            "sns:List*",
            "sqs:GetQueueAttributes",
            "sqs:ListQueues",
            "storagegateway:List*",
            "storagegateway:Describe*"
		],
		"Resource": "*"
	  },
	  {
        "Effect": "Allow",
        "Action": [
          "ec2:DeleteSnapshot",
          "ec2:DeleteVolume",
          "ec2:ModifyReservedInstances",
          "ec2:DescribeReservedInstancesOfferings",
          "ec2:PurchaseReservedInstancesOffering",
          "sts:GetFederationToken",
          "rds:DescribeReservedDBInstancesOfferings",
          "rds:PurchaseReservedDBInstancesOffering"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:Get*",
          "s3:List*"
        ],
        "Resource": [
            "arn:aws:s3:::${var.cloud_trail_bucket_name}.logs.coxautomotive",
            "arn:aws:s3:::${var.cloud_trail_bucket_name}.logs.coxautomotive/*",
            "arn:aws:s3:::${var.cloud_trail_bucket_name}-logs-coxautomotive",
            "arn:aws:s3:::${var.cloud_trail_bucket_name}-logs-coxautomotive/*"
        ]
      }
	]
}
EOF
}

resource "aws_iam_policy" "CAIBasicIAMPermissions" {
	#TODO - figure out how to set the deletion policy
	name = "CAIBasicIAMPermissions"
	path = "/cai-managed/private/"
	policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
	  {
		"Effect": "Allow",
		"Action": [
			"iam:Get*",
            "iam:List*",
            "iam:PassRole*",
            "iam:GenerateCredentialReport",
            "iam:GenerateServiceLastAccessedDetails",
            "iam:SimulateCustomPolicy",
            "iam:SimulatePrincipalPolicy"
		],
		"Resource": "*"
	  }
	]
}
EOF
}

resource "aws_iam_policy" "CAIALKSCreateRoles" {
	#TODO - figure out how to set the deletion policy
	name = "CAIALKSCreateRoles"
	path = "/cai-managed/private/"
	policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
	  {
		"Effect": "Allow",
		"Action": [
			"iam:AddRoleToInstanceProfile",
            "iam:CreateInstanceProfile",
            "iam:CreateRole",
            "iam:PutRolePolicy"
		],
		"Resource": [
		    "arn:aws:iam::${var.aws_account_id}:role/acct-managed/*",
            "arn:aws:iam::${var.aws_account_id}:user/instance-profile/acct-managed/*"
		]
	  }
	]
}
EOF
}

resource "aws_iam_policy" "CAIALKSUserPolicy" {
	#TODO - figure out how to set the deletion policy
	name = "CAIALKSUserPolicy"
	path = "/cai-managed/private/"
	policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
	  {
		"Effect": "Allow",
		"Action": [
			"iam:*LoginProfile",
			"iam:*AccessKey*"
		],
		"Resource": [
			"arn:aws:iam::${var.aws_account_id}:user/$${aws:username}",
			"arn:aws:iam::${var.aws_account_id}:user/cai-managed/alks/iam/$${aws:username}",
			"arn:aws:iam::${var.aws_account_id}:user/cai-managed/alks/$${aws:username}"
		]
	  },
	  {
		"Effect": "Allow",
		"Action": [
			"iam:ListAccountAliases",
			"iam:GetUser",
			"iam:ListRoles",
			"sts:GetFederationToken"
		],
		"Resource": "*"
	  }
	]
}
EOF
}

resource "aws_iam_policy" "CAIDenyALKSIAMPolicy" {
	name = "CAIDenyALKSIAMPolicy"
	path = "/cai-managed/private/"
	policy = <<EOF
{
	"Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Deny",
              "Action": [
                "iam:AddUserToGroup",
                "iam:AddClientIDToOpenIDConnectProvider",
                "iam:AttachGroupPolicy",
                "iam:AttachUserPolicy",
                "iam:ChangePassword",
                "iam:CreateAccountAlias",
                "iam:CreateGroup",
                "iam:CreateOpenIDConnectProvider",
                "iam:CreateSAMLProvider",
                "iam:CreateUser",
                "iam:CreateVirtualMFADevice",
                "iam:DeactivateMFADevice",
                "iam:DeleteAccountAlias",
                "iam:DeleteAccountPasswordPolicy",
                "iam:DeleteGroup",
                "iam:DeleteGroupPolicy",
                "iam:DeleteLoginProfile",
                "iam:DeleteOpenIDConnectProvider",
                "iam:DeleteSAMLProvider",
                "iam:DeleteSSHPublicKey",
                "iam:DeleteSigningCertificate",
                "iam:DeleteUser",
                "iam:DeleteUserPolicy",
                "iam:DeleteVirtualMFADevice",
                "iam:DetachGroupPolicy",
                "iam:DetachUserPolicy",
                "iam:EnableMFADevice",
                "iam:PutGroupPolicy",
                "iam:PutUserPolicy",
                "iam:RemoveClientIDFromOpenIDConnectProvider",
                "iam:RemoveUserFromGroup",
                "iam:ResyncMFADevice",
                "iam:UpdateAccountPasswordPolicy",
                "iam:UpdateAssumeRolePolicy",
                "iam:UpdateGroup",
                "iam:UpdateLoginProfile",
                "iam:UpdateOpenIDConnectProviderThumbprint",
                "iam:UpdateSAMLProvider",
                "iam:UpdateSSHPublicKey",
                "iam:UpdateSigningCertificate",
                "iam:UpdateUser",
                "iam:UploadSSHPublicKey",
                "iam:UploadSigningCertificate",
                "sts:AssumeRoleWithSAML",
                "sts:AssumeRoleWithWebIdentity"
              ],
              "Resource": "*"
            },
			{
              "Effect": "Deny",
              "Action": [
                "iam:CreateInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:CreateRole"
              ],
              "NotResource": [
                "arn:aws:iam::${var.aws_account_id}:role/acct-managed/*",
                "arn:aws:iam::${var.aws_account_id}:instance-profile/acct-managed/*"
              ],
			  "Condition": {
                "ArnLike": {
                  "aws:userid": "arn:aws:iam::${var.aws_account_id}:user/cai-managed/alks/iam/*"
                }
              }
            },
            {
              "Effect": "Deny",
              "Action": [
                "iam:CreatePolicy",
                "iam:CreatePolicyVersion",
                "iam:DeletePolicy",
                "iam:DeletePolicyVersion",
                "iam:SetDefaultPolicyVersion"
              ],
              "Resource": [
                "arn:aws:iam::${var.aws_account_id}:policy/cai-managed/*",
                "arn:aws:iam::${var.aws_account_id}:policy/IAM-*"
              ]
            },
            {
              "Effect": "Deny",
              "Action": [
                "iam:CreatePolicy",
                "iam:CreatePolicyVersion",
                "iam:DeletePolicy",
                "iam:DeletePolicyVersion",
                "iam:SetDefaultPolicyVersion"
              ],
              "NotResource": [
                "arn:aws:iam::${var.aws_account_id}:policy/acct-managed/*",
                "arn:aws:iam::${var.aws_account_id}:policy/Acct*"
              ]
            },
			{
              "Effect": "Deny",
              "Action": [
                "iam:DeleteRole",
                "iam:DeleteInstanceProfile",
                "iam:AttachRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePolicy",
                "iam:RemoveRoleFromInstanceProfile"
              ],
              "NotResource": [
                "arn:aws:iam::${var.aws_account_id}:role/acct-managed/*",
                "arn:aws:iam::${var.aws_account_id}:instance-profile/acct-managed/*"
              ]
            },
            {
              "Effect": "Deny",
              "NotAction": [
                "iam:Get*",
                "iam:List*",
                "iam:GenerateCredentialReport",
                "iam:GenerateServiceLastAccessedDetails",
                "iam:SimulateCustomPolicy",
                "iam:SimulatePrincipalPolicy",
                "sts:assumerole"
              ],
              "Resource": [
                "arn:aws:iam:::group/*",
                "arn:aws:iam:::federated-user/*",
                "arn:aws:iam:::mfa/*",
                "arn:aws:iam:::sms-mfa/*",
                "arn:aws:iam:::saml-provider/*",
                "arn:aws:iam:::oidc-provider/*",
                "arn:aws:iam::${var.aws_account_id}:policy/cai-managed/*",
                "arn:aws:iam::${var.aws_account_id}:role/cai-managed/*",
                "arn:aws:iam::${var.aws_account_id}:instance-profile/cai-managed/*",
                "arn:aws:iam::${var.aws_account_id}:role/IAM-*",
                "arn:aws:iam::${var.aws_account_id}:policy/IAM-*",
                "arn:aws:iam::${var.aws_account_id}:instance-profile/IAM-*"
              ]
            },
            {
              "Effect": "Deny",
              "Action": [
                "iam:*LoginProfile*",
                "iam:*AccessKey*"
              ],
              "NotResource": [
                "arn:aws:iam::${var.aws_account_id}:user/$${aws:username}",
                "arn:aws:iam::${var.aws_account_id}:user/cai-managed/alks/iam/$${aws:username}",
                "arn:aws:iam::${var.aws_account_id}:user/cai-managed/alks/$${aws:username}"
              ]
            },
            {
              "Effect": "Deny",
              "Action": [
                "iam:PassRole"
              ],
              "Resource": [
                "arn:aws:iam::*:role/cai-managed/*",
                "arn:aws:iam::*:role/IAM-1-Admin*",
                "arn:aws:iam::*:role/IAM-1-Network*",
                "arn:aws:iam::*:role/IAM-1-CloudEngineer*",
                "arn:aws:iam::*:role/IAM-1-Config*",
                "arn:aws:iam::*:role/IAM-1-IAM*"
              ]
            }
          ]
}
EOF
}

resource "aws_iam_policy" "CAIDenyPolicy1" {
	name = "CAIDenyPolicy1"
	path = "/cai-managed/deny/"
	policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
	  {
		"Effect": "Deny",
			"Action": [
                "iam:AddUserToGroup",
                "iam:AddClientIDToOpenIDConnectProvider",
                "iam:AttachGroupPolicy",
                "iam:AttachUserPolicy",
                "iam:ChangePassword",
                "iam:CreateAccountAlias",
                "iam:CreateGroup",
                "iam:CreateOpenIDConnectProvider",
                "iam:CreateSAMLProvider",
                "iam:CreateUser",
                "iam:CreateVirtualMFADevice",
                "iam:DeactivateMFADevice",
                "iam:DeleteAccountAlias",
                "iam:DeleteAccountPasswordPolicy",
                "iam:DeleteGroup",
                "iam:DeleteGroupPolicy",
                "iam:DeleteLoginProfile",
                "iam:DeleteOpenIDConnectProvider",
                "iam:DeleteSAMLProvider",
                "iam:DeleteSSHPublicKey",
                "iam:DeleteSigningCertificate",
                "iam:DeleteUser",
                "iam:DeleteUserPolicy",
                "iam:DeleteVirtualMFADevice",
                "iam:DetachGroupPolicy",
                "iam:DetachUserPolicy",
                "iam:EnableMFADevice",
                "iam:PutGroupPolicy",
                "iam:PutUserPolicy",
                "iam:RemoveClientIDFromOpenIDConnectProvider",
                "iam:RemoveUserFromGroup",
                "iam:ResyncMFADevice",
                "iam:UpdateAccountPasswordPolicy",
                "iam:UpdateAssumeRolePolicy",
                "iam:UpdateGroup",
                "iam:UpdateLoginProfile",
                "iam:UpdateOpenIDConnectProviderThumbprint",
                "iam:UpdateSAMLProvider",
                "iam:UpdateSSHPublicKey",
                "iam:UpdateSigningCertificate",
                "iam:UpdateUser",
                "iam:UploadSSHPublicKey",
                "iam:UploadSigningCertificate",
                "sts:AssumeRoleWithSAML",
                "sts:AssumeRoleWithWebIdentity"
			],
		"Resource": "*"
	  },
	  {
		"Effect": "Deny",
			"Action": [
                "iam:CreateInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:CreateRole"
			],
		"Resource": "*"
	  },
	  {
		"Effect": "Deny",
			"Action": [
                "iam:CreatePolicy",
                "iam:CreatePolicyVersion",
                "iam:DeletePolicy",
                "iam:DeletePolicyVersion",
                "iam:SetDefaultPolicyVersion"
            ],
		"Resource": [
			"arn:aws:iam::${var.aws_account_id}:policy/cai-managed/*",
            "arn:aws:iam::${var.aws_account_id}:policy/IAM-*"
		]
	  },
	  {
        "Effect": "Deny",
            "Action": [
                  "iam:CreatePolicy",
                  "iam:CreatePolicyVersion",
                  "iam:DeletePolicy",
                  "iam:DeletePolicyVersion",
                  "iam:SetDefaultPolicyVersion"
              ],
        "NotResource": [
            "arn:aws:iam::${var.aws_account_id}:policy/acct-managed/*",
            "arn:aws:iam::${var.aws_account_id}:policy/Acct*"
        ]
      },
	  {
		"Effect": "Deny",
			"Action": [
                "iam:DeleteRole",
                "iam:DeleteInstanceProfile",
                "iam:AttachRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePolicy",
                "iam:RemoveRoleFromInstanceProfile"
			],
		"NotResource": [
			"arn:aws:iam::${var.aws_account_id}:role/acct-managed/*",
            "arn:aws:iam::${var.aws_account_id}:instance-profile/acct-managed/*"
		]
	  },
	  {
		"Effect": "Deny",
			"NotAction": [
                "iam:Get*",
                "iam:List*",
                "iam:GenerateCredentialReport",
                "iam:GenerateServiceLastAccessedDetails",
                "iam:SimulateCustomPolicy",
                "iam:SimulatePrincipalPolicy",
                "sts:assumerole"
            ],
        "Resource": [
			"arn:aws:iam:::group/*",
            "arn:aws:iam:::federated-user/*",
            "arn:aws:iam:::mfa/*",
            "arn:aws:iam:::sms-mfa/*",
            "arn:aws:iam:::saml-provider/*",
            "arn:aws:iam:::oidc-provider/*",
            "arn:aws:iam::${var.aws_account_id}:policy/cai-managed/*",
            "arn:aws:iam::${var.aws_account_id}:role/cai-managed/*",
            "arn:aws:iam::${var.aws_account_id}:instance-profile/cai-managed/*",
            "arn:aws:iam::${var.aws_account_id}:role/IAM-*",
			"arn:aws:iam::${var.aws_account_id}:policy/IAM-*",
            "arn:aws:iam::${var.aws_account_id}:instance-profile/IAM-*"
		]
	  },
	  {
		"Effect": "Deny",
			"Action": [
                "iam:DetachRolePolicy"
			],
			"Condition": {
                "ArnLike": {
                  "iam:PolicyArn": "arn:aws:iam::*:policy/cai-managed/*"
                }
            },
            "Resource": [
                "*"
            ]
      },
	  {
		"Effect": "Deny",
			"Action": [
                "iam:*LoginProfile*",
                "iam:*AccessKey*"
			],
        "NotResource": [
			"arn:aws:iam::${var.aws_account_id}:user/$${aws:username}",
            "arn:aws:iam::${var.aws_account_id}:user/cai-managed/alks/iam/$${aws:username}",
            "arn:aws:iam::${var.aws_account_id}:user/cai-managed/alks/$${aws:username}"
		]
	  },
	  {
		"Effect": "Deny",
			"Action": [
                "iam:PassRole"
            ],
        "Resource": [
			"arn:aws:iam::*:role/cai-managed/*",
            "arn:aws:iam::*:role/IAM-1-Admin*",
            "arn:aws:iam::*:role/IAM-1-Network*",
            "arn:aws:iam::*:role/IAM-1-CloudEngineer*",
            "arn:aws:iam::*:role/IAM-1-Config*",
            "arn:aws:iam::*:role/IAM-1-IAM*"
        ]
	  }
	]
}
EOF
}

resource "aws_iam_policy" "CAIDenyPolicy2" {
	name = "CAIDenyPolicy2"
	path = "/cai-managed/deny/"
	policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
	  {
		"Effect": "Deny",
			"Action": [
                "ec2:DeleteVpc*",
                "ec2:CreateVpc*",
                "ec2:RejectVpcPeeringConnection",
                "ec2:AcceptVpcPeeringConnection",
                "ec2:DeleteVpn*",
                "ec2:CreateVpn*",
                "ec2:DeleteCustomer*",
                "ec2:CreateCustomer*",
                "ec2:AttachVpnGateway",
                "ec2:AttachClassicLinkVpc",
                "ec2:CreateNetworkAcl*",
                "ec2:CreateRoute*",
                "ec2:CreateSubnet*",
                "ec2:ModifyReservedInstances",
                "ec2:ModifyVpc*",
                "ec2:CreateVpcPeeringConnection",
                "ec2:RejectVpcPeeringConnection",
                "ec2:ReplaceNetworkAcl*",
                "ec2:ReplaceRoute*",
                "ec2:CreateReservedInstancesListing",
                "ec2:ModifyReservedInstances",
                "ec2:PurchaseReservedInstancesOffering",
                "ec2:CancelReservedInstancesListing",
                "ec2:Purchase*",
                "aws-portal:Modify*",
                "directconnect:Allocate*",
                "directconnect:Confirm*",
                "directconnect:Create*",
                "directconnect:Delete*",
                "ds:*"
            ],
		"Resource": "*"
	  },
	  {
		"Effect": "Deny",
			"NotAction": [
                "cloudtrail:DescribeTrails",
                "cloudtrail:GetTrailStatus",
                "cloudtrail:ListPublicKeys",
                "cloudtrail:ListTags",
                "cloudtrail:LookupEvents"
            ],
		"Resource": [
			"arn:aws:cloudtrail:*:*:${var.cloud_trail_bucket_name}-cloudtrail-allregions"
		]
	  },
	  {
		"Effect": "Deny",
			"NotAction": [
                "sqs:List*",
                "sqs:Get*"
            ],
		"Resource": [
			"arn:aws:sqs:::${var.aws_account_id}-awsconfig",
            "arn:aws:sqs:::${var.aws_account_id}-cloudtrail"
		]
	  },
	  {
        "Effect": "Deny",
        "Action": [
            "config:Delete*",
            "config:Put*",
            "config:Start*",
            "config:Stop*"
        ],
        "Resource": "*"
      },
	  {
		"Effect": "Deny",
			"Action": "cloudformation:*",
		"Resource": [
			"arn:aws:cloudformation:${var.aws_region}:${var.aws_account_id}:stack/IAM-*",
			"arn:aws:cloudformation:${var.aws_region}:${var.aws_account_id}:stack/VPC-*",
			"arn:aws:cloudformation:${var.aws_region}:${var.aws_account_id}:stack/CAI-*",
            "arn:aws:cloudformation:*:*:stack/IAM-*",
            "arn:aws:cloudformation:*:*:stack/VPC-*",
            "arn:aws:cloudformation:*:*:stack/CAI-*"
		]
	  },
	  {
		"Effect": "Deny",
	    "NotAction": [
            "s3:Get*",
            "s3:List*"
		],
		"Resource": [
			"arn:aws:s3:::${var.cloud_trail_bucket_name}.logs.coxautomotive/*",
            "arn:aws:s3:::${var.cloud_trail_bucket_name}.logs.coxautomotive",
            "arn:aws:s3:::${var.cloud_trail_bucket_name}-logs-coxautomotive/*",
            "arn:aws:s3:::${var.cloud_trail_bucket_name}-logs-coxautomotive",
			"arn:aws:s3::*:*.logs.coxautomotive*",
			"arn:aws:s3::*:*logs-coxautomotive*"
		]
	  }
	]
}
EOF
}




###################### Mapping Custom Managed Policies to Resources #########################

resource "aws_iam_policy_attachment" "CAIBasicIAMPermissionsAttachment" {
	name = "CAIBasicIAMPermissionsAttachment"
	roles = [
		"${aws_iam_role.PowerUserRole.name}"
	]
	groups = [
		"${aws_iam_group.PowerUserGroup.name}"
	]
	policy_arn = "${aws_iam_policy.CAIBasicIAMPermissions.arn}"
}

resource "aws_iam_policy_attachment" "CAIALKSCreateRolesAttachment" {
	name = "CAIALKSCreateRolesAttachment"
	users = [
    		"${aws_iam_user.ALKSAdmin.name}",
    		"${aws_iam_user.ALKSIAMAdmin.name}"
    	]
	policy_arn = "${aws_iam_policy.CAIALKSCreateRoles.arn}"
}


resource "aws_iam_policy_attachment" "CAIALKSUserPolicyAttachment" {
    name = "CAIALKSUserPolicyAttachment"
    policy_arn = "${aws_iam_policy.CAIALKSUserPolicy.arn}"
    users = [
    		"${aws_iam_user.ALKSAdmin.name}",
    		"${aws_iam_user.ALKSIAMAdmin.name}",
    		"${aws_iam_user.ALKSPowerUser.name}",
    		"${aws_iam_user.ALKSReadOnly.name}"
    ]
}

resource "aws_iam_policy_attachment" "CAICloudHealthPolicyAttachment" {
	name = "CAICloudHealthPolicyAttachment"
	policy_arn = "${aws_iam_policy.CAICloudHealthPolicy.arn}"
	roles = [
    	"${aws_iam_role.SvcCloudHealthRole.name}"
    ]
}

resource "aws_iam_policy_attachment" "CAIDenyALKSIAMPolicyAttachment" {
	name = "CAIDenyALKSIAMPolicyAttachment"
	policy_arn = "${aws_iam_policy.CAIDenyALKSIAMPolicy.arn}"
	groups = [
		"${aws_iam_group.AdminGroup.name}",
		"${aws_iam_group.IAMAdminGroup.name}"
	]
}

resource "aws_iam_policy_attachment" "CAIDenyPolicy1Attachment" {
	name = "CAIDenyPolicy1Attachment"
	roles = [
		"${aws_iam_role.AdminRole.name}",
		"${aws_iam_role.IAMAdminRole.name}",
		"${aws_iam_role.PowerUserRole.name}",
		"${aws_iam_role.ReadOnlyRole.name}"
	]
	groups = [
		"${aws_iam_group.PowerUserGroup.name}",
		"${aws_iam_group.ReadOnlyGroup.name}"
	]
	policy_arn = "${aws_iam_policy.CAIDenyPolicy1.arn}"
}

resource "aws_iam_policy_attachment" "CAIDenyPolicy2Attachment" {
	name = "CAIDenyPolicy2Attachment"
	roles = [
		"${aws_iam_role.AdminRole.name}",
		"${aws_iam_role.IAMAdminRole.name}",
		"${aws_iam_role.PowerUserRole.name}",
		"${aws_iam_role.ReadOnlyRole.name}"
	]
	groups = [
		"${aws_iam_group.AdminGroup.name}",
		"${aws_iam_group.IAMAdminGroup.name}",
		"${aws_iam_group.ReadOnlyGroup.name}",
		"${aws_iam_group.PowerUserGroup.name}"
	]
	policy_arn = "${aws_iam_policy.CAIDenyPolicy2.arn}"
}

###################### Mapping AWS Managed Policies to Resources #########################


# Tried using aws_iam_policy_attachment for Administrator Access - but it removed Administrator Access from all accounts
resource "aws_iam_role_policy_attachment" "AdminRole_AdministratorAccessPolicyAttachment" {
	role = "${aws_iam_role.AdminRole.name}"
	policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "AdminGroup_AdministratorAccessPolicyAttachment" {
	group = "${aws_iam_group.AdminGroup.name}"
	policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "IAMAdminGroup_IAMFullAccessPolicyAttachment" {
	group = "${aws_iam_group.IAMAdminGroup.name}"
	policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_role_policy_attachment" "IAMAdminRole_IAMFullAccessPolicyAttachment" {
	role = "${aws_iam_role.IAMAdminRole.name}"
	policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_group_policy_attachment" "PowerUserGroup_PowerUserAccessPolicyAttachment" {
	group = "${aws_iam_group.PowerUserGroup.name}"
	policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role_policy_attachment" "PowerUserRole_PowerUserAccessPolicyAttachment" {
	role = "${aws_iam_role.PowerUserRole.name}"
	policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_group_policy_attachment" "PowerUserGroup_IAMReadOnlyAccessPolicyAttachment" {
	group = "${aws_iam_group.PowerUserGroup.name}"
	policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "PowerUserRole_IAMReadOnlyAccessPolicyAttachment" {
	role = "${aws_iam_role.PowerUserRole.name}"
	policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

resource "aws_iam_group_policy_attachment" "ReadOnlyGroup_ReadOnlyAccessPolicyAttachment" {
	group = "${aws_iam_group.ReadOnlyGroup.name}"
	policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ReadOnlyRole_ReadOnlyAccessPolicyAttachment" {
	role = "${aws_iam_role.ReadOnlyRole.name}"
	policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
