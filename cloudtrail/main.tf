# Eventually put into vars file, and pull in from the calling environment
# 2nd part of NewAccounts is "Config" which isn't supported currently in TF
# Using TF Provisioners instead for arbitrary execution

provider "aws" {
	region = "us-east-1"
}

variable "account" {
	description = "Account shortname to setup"
	default = "awslabs68"
}

variable "profile" {
	description = "Profile name"
	default = "awslabs68"
}

# Change this to use data source
variable "AccountID" {
	description = "Account shortname to setup"
	default = "688976807255"
}

variable "DefaultRegion" {
	description = "default region"
	default = "us-east-1"
}

variable "bucket" {
	description = "account specific bucket"
	default = "awslabs68"
}


resource "aws_s3_bucket_policy" "b" {
  bucket = "${format("%s.logs.coxautomotive", var.bucket)}" 
  policy = "${data.aws_iam_policy_document.b.json}"
}


data "aws_iam_policy_document" "b" {

	statement {
		sid = "AWSCloudTrailAclCheck20150319"
		effect = "Allow"
		actions = [
			"s3:GetBucketAcl",
		]
		resources = [
  			"${format("arn:aws:s3:::%s.logs.coxautomotive", var.bucket)}",
		]
		principals {
			type = "Service"
			identifiers = [
				"cloudtrail.amazonaws.com",
			]
		}
	}

	statement {
		sid = "AWSCloudTrailWrite20150319",
		actions = [
			"s3:PutObject",
		]
		resources = [
  			"${format("arn:aws:s3:::%s.logs.coxautomotive/AWSLogs/%s/*", var.bucket, var.AccountID)}",
		]
		principals {
			type = "Service"
			identifiers = [
				"cloudtrail.amazonaws.com",
			]
		}
		condition {
			test = "StringEquals"
			variable = "s3:x-amz-acl"
			values = [
				"bucket-owner-full-control",
			]
		}
	}
}


data "aws_iam_policy_document" "sns" {

	statement {
		sid = "AWSCloudTrailSNSPolicy20131101"
		effect = "Allow"
		actions = [
			"SNS:Publish",
		]
		resources = [
  			"${format("arn:aws:sns:%s:%s:%s-cloudtrail-allregions", var.DefaultRegion, var.AccountID, var.bucket)}",
		]
		principals {
			type = "Service"
			identifiers = [
				"cloudtrail.amazonaws.com",
			]
		}

	}
}


##	The topic name is "awslabs68-cloudtrail-allregions"

resource "aws_sns_topic" "sns" {
	name = "${format("%s-cloudtrail-allregions", var.bucket)}" 
}	


resource "aws_sns_topic_policy" "sns" {
	arn		= "${aws_sns_topic.sns.arn}"
	policy	= "${data.aws_iam_policy_document.sns.json}"
}


# Can't use the bucket.id because terraform didn't create it

resource "aws_cloudtrail" "sns" {
	name = "${format("%s-cloudtrail-allregions", var.bucket)}" 
	s3_bucket_name = "${format("%s.logs.coxautomotive", var.bucket)}"
	sns_topic_name = "${aws_sns_topic.sns.name}"
	include_global_service_events = true

	provisioner "local-exec" {
		command = "sleep 5"
		command = "aws --region ${var.DefaultRegion} cloudtrail start-logging --name ${self.arn}"
	}
} 


