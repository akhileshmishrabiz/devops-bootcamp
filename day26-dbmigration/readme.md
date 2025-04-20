aws rds create-db-instance \
    --db-instance-identifier mydbinstance-1 \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --allocated-storage 50 \
    --master-username mymasteruser \
    --master-user-password mypassword \
    --backup-retention-period 7

aws rds create-db-instance \
    --db-instance-identifier mydbinstance-2 \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --allocated-storage 70 \
    --master-username mymasteruser \
    --master-user-password mypassword \
    --backup-retention-period 7


aws rds create-db-instance \
    --db-instance-identifier mydbinstance-3 \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --allocated-storage 60 \
    --master-username mymasteruser \
    --master-user-password mypassword \
    --backup-retention-period 7


postgresql://mymasteruser:{db_password}@{db_host_endpoint}:{db_port}/{database_name}

1. postgresql://mymasteruser:mypassword@mydbinstance-1.cfykukwcw419.ap-south-1.rds.amazonaws.com:5432/postgres ->
 /database/mydbinstance-1

2. postgresql://mymasteruser:mypassword@mydbinstance-2.cfykukwcw419.ap-south-1.rds.amazonaws.com:5432/postgres
/database/mydbinstance-2

3. postgresql://mymasteruser:mypassword@mydbinstance-3.cfykukwcw419.ap-south-1.rds.amazonaws.com:5432/postgres
/database/mydbinstance-3


suppose we have a 200gb database -> it is used 100 gb useed
used is 100gb -> 200-100 
20% of used + used -? 120% used -> will be the new size -> 120gb 

so you build a rds of 120gb

-> calculate new storage -> based on your use case

-> duplicate rds with new storage 

-> you need rds creds

-> use psycorp library to take a dump rom source db and restore to destination db

-> stop the old db 

-> rename the newdb to old db

-> i hve built with cli -> i can pass differnet options -> evalute, migrate 

docker build -t dbmigrate .

docker run -v ~/.aws:/root/.aws dbmigrate python migrate.py evaluate mydbinstance-1

docker run  -v ~/.aws:/root/.aws  dbmigrate python migrate.py  migrate mydbinstance-1 20