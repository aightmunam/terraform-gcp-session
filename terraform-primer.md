# How to terraform
Terraform uses HCL language. It has its own syntax. It is not as flexible as
python as it takes a more declarative approach.

### Provider
The first step to using Terraform is typically to configure the provider(s)
we want to use. E.g. aws, gcp, docker etc.
```HCL
provider "<NAME>" {
    [CONFIG ...]
}
```


### Declaring a variable

```HCL
variable "<NAME>" {
    type = <VALUE>
    [CONFIG ...]
}
```
We can assign value to the variable in the variable definition file which by default is terraform.tfvars

### Outputs

In addition to input variables, Terraform also allows us to define output
variables by using the following syntax:
```HCL
output "<NAME>" {
    value = <VALUE>
    [CONFIG ...]
}
```

### Creating a resource
The general syntax looks kind of like:
```HCL
resource "<PROVIDER>_<TYPE>" "<NAME>" {
    [CONFIG ...]
}
```

This is how we create and configure resources like servers, DBs, VPCs etc.
Every provider has their own array of resources.

### Data Sources
A data source represents a piece of read-only information.

Adding a data source to our Terraform configurations does not create
anything new; it’s just a way to query the provider’s APIs for data and to
make that data available to the rest of our Terraform code.

Example uses could be something like fetching an docker image link, or
finding the list of instances (from a autoscaling group), and sharing
it with a load balancer.

The syntax for using a data source is very similar to the syntax of a
resource:
```HCL
data "<PROVIDER>_<TYPE>" "<NAME>" {
  [CONFIG ...]
}
```

## State
Terraform state is how Terraform keeps track of the real-world infrastructure it manages.
When we run terraform apply, it:
1. Creates or updates resources
2. Saves the current state of our infrastructure in a file called `terraform.tfstate`


In practice, the state should be stored in some shared storage, so all team members can access it.
In addition, there should be some sort of locking mechanism so multiple people cannot edit it at the same time.

Terraform supports remote backends (like AWS S3 with DynamoDB locking):
- Terraform will automatically load the state file from that backend every time we run plan or apply
- To run terraform apply, Terraform will automatically acquire a lock; if someone else is already running apply, they
will already have the lock, and we will have to wait.

## Beyond the scope of this workshop

There is much more to learn, including but not limited to:
- Loops, conditionals
- Modules
- Handling Drift & Lifecycle
- Terraform Cloud
- CI/CD Integration
- Multi-cloud Deployments
