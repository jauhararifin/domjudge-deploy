# domjudge-deploy
Deploy domjudge without tears

Just do this:
1. configure `terraform.tfvars.example`
2. provision ec2 and install domjudge using `./provision.sh`
3. run grader using `./start-judgehost.sh`

hopefully

Actually we can use docker for deploying domjudge. Then why using ansible? Because I like it
