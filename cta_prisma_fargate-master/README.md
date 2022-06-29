# Prisma Cloud Fargate Integration

This repo is a demo of how one can create a Primsa sidecar container in Fargate

1. Start up mountebank mock server in http-mock, see [README](http-mock/README.md)
2. Run terraform apply
3. Check fargate task definition, there should be a definition called service-testing with 2 container definitions