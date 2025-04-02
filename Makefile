# A script to format ALL The terraform code in the repo

format:
	terraform fmt -recursive

# A script to check ALL The terraform code in the repo
check:
	terraform validate
