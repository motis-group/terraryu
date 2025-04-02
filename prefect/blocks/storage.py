from prefect.blocks.system import JSON
from prefect_aws.s3 import S3Bucket
from prefect_snowflake.database import SnowflakeConnector
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def register_s3_block(name, bucket_name, aws_access_key_id=None, aws_secret_access_key=None):
    """
    Register an S3 bucket block
    
    Args:
        name: The name to give the block
        bucket_name: The S3 bucket name
        aws_access_key_id: Optional AWS access key ID (otherwise uses environment variables)
        aws_secret_access_key: Optional AWS secret access key (otherwise uses environment variables)
    """
    # Use provided credentials or fallback to environment variables
    aws_access_key_id = aws_access_key_id or os.getenv("AWS_ACCESS_KEY_ID")
    aws_secret_access_key = aws_secret_access_key or os.getenv("AWS_SECRET_ACCESS_KEY")
    
    # Create and save the block
    s3_block = S3Bucket(
        bucket_name=bucket_name,
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
    )
    s3_block.save(name=name, overwrite=True)
    print(f"S3 Block {name} registered successfully")
    return s3_block

def register_snowflake_block(
    name,
    account,
    user,
    password=None,
    database=None,
    schema=None,
    warehouse=None,
    role=None
):
    """
    Register a Snowflake connector block
    
    Args:
        name: The name to give the block
        account: Snowflake account identifier
        user: Snowflake username
        password: Optional Snowflake password (otherwise uses environment variables)
        database: Optional default database
        schema: Optional default schema
        warehouse: Optional default warehouse
        role: Optional default role
    """
    # Use provided password or fallback to environment variable
    password = password or os.getenv("SNOWFLAKE_PASSWORD")
    
    # Create and save the block
    snowflake_block = SnowflakeConnector(
        account=account,
        user=user,
        password=password,
        database=database,
        schema=schema,
        warehouse=warehouse,
        role=role
    )
    snowflake_block.save(name=name, overwrite=True)
    print(f"Snowflake Block {name} registered successfully")
    return snowflake_block

def register_etl_config_block(name, config_data):
    """
    Register a JSON block with ETL configuration
    
    Args:
        name: The name to give the block
        config_data: Dictionary with configuration data
    """
    # Create and save the block
    json_block = JSON(value=config_data)
    json_block.save(name=name, overwrite=True)
    print(f"Config Block {name} registered successfully")
    return json_block

if __name__ == "__main__":
    # Register blocks for different environments
    
    # Dev environment
    register_s3_block(
        name="dev-data-bucket",
        bucket_name="data-platform-dev-data"
    )
    
    register_snowflake_block(
        name="dev-snowflake",
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        user=os.getenv("SNOWFLAKE_USER"),
        database="DEV_DB",
        schema="DEV_SCHEMA",
        warehouse="DEV_WH",
        role="SYSADMIN"
    )
    
    # Sample ETL config
    register_etl_config_block(
        name="etl-config", 
        config_data={
            "transform_rules": {
                "drop_columns": ["temp_col", "unused_col"],
                "rename_columns": {
                    "old_name": "new_name",
                    "raw_value": "processed_value"
                },
                "fill_na": {
                    "important_field": 0,
                    "status": "unknown"
                }
            }
        }
    ) 