import subprocess
import boto3
import logging
import psycopg
from botocore.config import Config
from psycopg import OperationalError
import time
import argparse
from datetime import datetime, timedelta
import urllib.parse
import sys
from os import getenv

my_config = Config(
    region_name="ap-south-1",
    signature_version="v4",
    retries={"max_attempts": 10, "mode": "standard"},
)

def parse_arguments():
    parser = argparse.ArgumentParser(description='Script to configure RDS database storage size.')
    parser.add_argument('action', choices=['migrate', 'evaluate'], help='Action to perform: migrate or evaluate')
    parser.add_argument('dbname', nargs='?', help='Name of the RDS database')
    parser.add_argument('size', nargs='?', help='New storage size for the RDS database (required for migrate action)')
    return parser.parse_args()

ec2_client = boto3.client("ec2", config=my_config)
rds = boto3.client("rds", config=my_config)
s3_client = boto3.client("s3", config=my_config)
ssm = boto3.client("ssm", config=my_config)
cloudwatch = boto3.client("cloudwatch", config=my_config)

def log_setup():
    logger = logging.getLogger()

    for handler in logger.handlers:
        logger.removeHandler(handler)
    handler = logging.StreamHandler(sys.stdout)

    dformat = "[%(filename)s:%(lineno)d] :%(levelname)8s: %(message)s"
    handler.setFormatter(logging.Formatter(dformat))
    logger.addHandler(handler)
    log_level = logging.INFO
    if getenv("DEBUG", False):
        log_level = logging.DEBUG
    logger.setLevel(log_level)

    # Suppress the more verbose modules
    logging.getLogger("botocore").setLevel(logging.WARN)
    logging.getLogger("s3transfer").setLevel(logging.WARN)
    logging.getLogger("boto3").setLevel(logging.WARN)
    logging.getLogger("urllib3").setLevel(logging.WARN)

def source_rds_instance(dbinstance):
    return rds.describe_db_instances(DBInstanceIdentifier=dbinstance)["DBInstances"][0]

def get_db_details(dbinstance):
    # parameter name should be in "/database/{dbinstance}" format
    # parameter store has the db_link in below format
    #  f'postgresql://{db_user}:{db_password}@{db_host_endpoint}:{db_port}/{database_name}'
    #  postgresql://postgres:N.)<Ba%X5s2sHezwr2Rq$tmW:Mbz@wordpress.cfykukwcw419.ap-south-1.rds.amazonaws.com:5432/mydb

    parametre_name = (
        f"/database/{dbinstance}"
    )
    response = ssm.get_parameter(Name=parametre_name, WithDecryption=True | False)[
        "Parameter"
    ]["Value"]

    user = response.split(":")[1].split("/")[-1]
    password = response.split(":")[2].split("@")[0]
    db = response.split("/")[-1]
    host = response.split(":")[2].split("@")[-1]
    port = response.split(":")[3].split("/")[0]

    return host, db, user, password, port

# rds monitoring data for free storage
def get_db_freestorage(DBInstanceIdentifier):
    response = cloudwatch.get_metric_data(
        MetricDataQueries=[
            {
                "Id": "fetching_FreeStorageSpace",
                "MetricStat": {
                    "Metric": {
                        "Namespace": "AWS/RDS",
                        "MetricName": "FreeStorageSpace",
                        "Dimensions": [
                            {
                                "Name": "DBInstanceIdentifier",
                                "Value": DBInstanceIdentifier,
                            }
                        ],
                    },
                    "Period": 86400 * 7,
                    "Stat": "Minimum",
                },
            }
        ],
        StartTime=(datetime.now() - timedelta(seconds=86400 * 7)).timestamp(),
        EndTime=datetime.now().timestamp(),
        ScanBy="TimestampDescending",
    )
    return round(response["MetricDataResults"][0]["Values"][0] / 1024**3, 2)


def duplicate_rds(dbinstance: str, new_allocated_storage: int) -> dict:
    source_rds_data = source_rds_instance(dbinstance)
    _, db, user, password, port = get_db_details(dbinstance)

    instance_params = {
        "DBName": db,
        "DBInstanceIdentifier": f"{source_rds_data['DBInstanceIdentifier']}new",
        "AllocatedStorage": new_allocated_storage,
        "DBInstanceClass": source_rds_data["DBInstanceClass"],
        "Engine": source_rds_data["Engine"],
        "MasterUsername": user,
        "MasterUserPassword": password,
        "Port": int(port),
        "DBSecurityGroups": [
            items["DBSecurityGroupName"]
            for items in source_rds_data["DBSecurityGroups"]
        ],
        "VpcSecurityGroupIds": [
            items["VpcSecurityGroupId"]
            for items in source_rds_data["VpcSecurityGroups"]
        ],
        "AvailabilityZone": source_rds_data["AvailabilityZone"],
        "DBSubnetGroupName": source_rds_data["DBSubnetGroup"]["DBSubnetGroupName"],
        "PreferredMaintenanceWindow": source_rds_data["PreferredMaintenanceWindow"],
        "DBParameterGroupName": source_rds_data["DBParameterGroups"][0][
            "DBParameterGroupName"
        ],
        "BackupRetentionPeriod": source_rds_data["BackupRetentionPeriod"],
        "PreferredBackupWindow": source_rds_data["PreferredBackupWindow"],
        "MultiAZ": source_rds_data["MultiAZ"],
        "EngineVersion": source_rds_data["EngineVersion"],
        "AutoMinorVersionUpgrade": source_rds_data["AutoMinorVersionUpgrade"],
        "LicenseModel": source_rds_data["LicenseModel"],
        "OptionGroupName": source_rds_data["OptionGroupMemberships"][0][
            "OptionGroupName"
        ],
        "PubliclyAccessible": source_rds_data["PubliclyAccessible"],
        "Tags": source_rds_data["TagList"],
        "StorageType": source_rds_data["StorageType"],
        "StorageEncrypted": source_rds_data["StorageEncrypted"],
        "CopyTagsToSnapshot": source_rds_data["CopyTagsToSnapshot"],
        "EnableIAMDatabaseAuthentication": source_rds_data[
            "IAMDatabaseAuthenticationEnabled"
        ],
        "EnablePerformanceInsights": source_rds_data["PerformanceInsightsEnabled"],
        "DeletionProtection": source_rds_data["DeletionProtection"],
        "EnableCustomerOwnedIp": source_rds_data["CustomerOwnedIpEnabled"],
        "BackupTarget": source_rds_data["BackupTarget"],
        "NetworkType": source_rds_data["NetworkType"],
        "CACertificateIdentifier": source_rds_data["CACertificateIdentifier"],
    }

    try:
        if source_rds_data["MaxAllocatedStorage"]:
            instance_params["MaxAllocatedStorage"] = source_rds_data[
                "MaxAllocatedStorage"
            ]
    except KeyError:
        pass

    response = rds.create_db_instance(**instance_params)
    return response


def backup_postgres_db(host, db, port, user, password, dest_file, verbose):
    """
    Backup postgres db to a file.
    """
    if verbose:
        try:
            process = subprocess.Popen(
                [
                    "pg_dump",
                    f"--dbname=postgresql://{user}:{password}@{host}:{port}/{db}",
                    "-Fc",
                    "-f",
                    dest_file,
                    "-v",
                ],
                stdout=subprocess.PIPE,
            )
            output = process.communicate()[0]
            if int(process.returncode) != 0:
                print(f"Command failed. Return code : {process.returncode}")
                exit(1)
            return output
        except Exception as e:
            logging.error(e)
            exit(1)
    else:

        try:
            process = subprocess.Popen(
                [
                    "pg_dump",
                    f"--dbname=postgresql://{user}:{password}@{host}:{port}/{db}",
                    "-f",
                    dest_file,
                ],
                stdout=subprocess.PIPE,
            )
            output = process.communicate()[0]
            if process.returncode != 0:
                print(f"Command failed. Return code : {process.returncode}")
                exit(1)
            return output
        except Exception as e:
            print.error(e)
            exit(1)


def restore_postgres_db(host, db, port, user, password, backup_file, verbose):
    """
    Restore postgres db from a file.
    """
    if verbose:
        try:
            process = subprocess.Popen(
                [
                    "pg_restore",
                    "--no-owner",
                    f"--dbname=postgresql://{user}:{password}@{host}:{port}/{db}",
                    "-v",
                    backup_file,
                ],
                stdout=subprocess.PIPE,
            )
            output = process.communicate()[0]
            if int(process.returncode) != 0:
                logging.error(f"Command failed. Return code : {process.returncode}")

            return output
        except Exception as e:
            logging.error(f"Issue with the db restore : {e}")
    else:
        try:
            process = subprocess.Popen(
                [
                    "pg_restore",
                    "--no-owner",
                    f"--dbname=postgresql://{user}:{password}@{host}:{port}/{db}",
                    backup_file,
                ],
                stdout=subprocess.PIPE,
            )
            output = process.communicate()[0]
            if int(process.returncode) != 0:
                logging.error(f"Command failed. Return code : {process.returncode}")

            return output
        except Exception as e:
            logging.error(f"Issue with the db restore : {e}")

def check_rds_availability(host, port, dbname, user, password):
    while True:
        try:
            # Attempt to establish a connection to the RDS database
            conn = psycopg.connect(
                host=host, port=port, dbname=dbname, user=user, password=password
            )

            conn.close()
            time.sleep(30) # giving additional 30 seconds 
            return True

        except OperationalError as e:
            # If an OperationalError occurs (e.g., connection error), print the error
            logging.error(f"Error connecting to the RDS database {host}: {e}")
            logging.info("Retrying in 60 seconds...")
            time.sleep(60) 

def evaluate_rds(dbinstance):
    free_storage = get_db_freestorage(dbinstance)
    allocated_storage = source_rds_instance(dbinstance)['AllocatedStorage']

    return f' RDS instance {dbinstance} ia allocated {allocated_storage} GB and out of that, {free_storage} GB is available'

def rename_rds(old, new):
    try:
            process = subprocess.Popen(
                [
                    "aws",
                    "rds",
                    "modify-db-instance",
                    "--db-instance-identifier",
                    old,
                    "--new-db-instance-identifier",
                    new,
                    "--apply-immediately"
                ],
                stdout=subprocess.PIPE,
            )
            output = process.communicate()[0]
            if int(process.returncode) != 0:
                logging.error(f"Command failed. Return code : {process.returncode}")

            return output
    except Exception as e:
        logging.error(f"Issue with renaming {old} -> {old}-old : {e}")
        exit(1)


def swap_db(old, new):
    logging.info(f'Renaming db: {old} -> {old}-old ')
    rename_rds(old, f'{old}-old')
    logging.info("Sleeping for 5 min")
    time.sleep(300)
    logging.info(f'Renaming db: {new} - > {old}')
    rename_rds(new, old)

def stop_rds(dbinstance: str) -> None:
    try:
        logging.info(f"Stopping the RDS instance - {dbinstance}")
        rds.stop_db_instance(
            DBInstanceIdentifier=dbinstance
        )
    except Exception as e:
        logging.error(f"Issue with stopping - {dbinstance} -> {e}")
        exit(1)

def migrate_rds(dbinstance,new_allocated_storage ):
    host, db, user, password, port = get_db_details(dbinstance)
    password = urllib.parse.quote(password)
    source_rds_data = source_rds_instance(dbinstance)
    logging.info(f' Taking pg_dump of {dbinstance} ')
    backup_filename = f'{dbinstance}_dump'
    try:
        backup_postgres_db(
            host, db, port, user, password, backup_filename, verbose=False
        )
    except Exception as e:
        logging.info(e)

    logging.info(f' Creating the duplicte rds of {dbinstance}')
    duplicate_rds_instance = duplicate_rds(dbinstance, int(new_allocated_storage))

    new_rds_DBInstanceIdentifier = duplicate_rds_instance["DBInstance"][
        "DBInstanceIdentifier"
    ]
    logging.info(f"Creating {new_rds_DBInstanceIdentifier}")
    old_db_endpoint = source_rds_data['Endpoint']['Address']
    new_db_endpoint = new_rds_DBInstanceIdentifier + "." + ".".join(old_db_endpoint.split(".")[1:])
    check_rds_availability(new_db_endpoint, port, db, user, password)

    logging.info(f"restoring the new db - {new_rds_DBInstanceIdentifier}")
    try:
        restore_postgres_db(
            new_db_endpoint, db, port, user, password, backup_filename, verbose=False
        )
    except Exception as e:
        print(e)

    logging.info("Swapping dbs")
    swap_db(dbinstance, new_rds_DBInstanceIdentifier)
    logging.info(f'Stopping the {dbinstance}-old')
    stop_rds(f'{dbinstance}-old')



if __name__ == "__main__":
    log_setup()
    args = parse_arguments()
    
    if args.action == 'migrate':
        if args.dbname and args.size:
            migrate_rds(args.dbname, args.size)
        else:
            print("Usage: migrate action requires dbname and size arguments.")
    elif args.action == 'evaluate':
        if args.dbname:
            print(evaluate_rds(args.dbname))
        else:
            print("Usage: evaluate action requires dbname argument.")
    else:
        print("Invalid action. Valid actions are 'migrate' or 'evaluate'.")