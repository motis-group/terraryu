import pandas as pd
from prefect import flow, task
from prefect.blocks.system import JSON
from prefect_aws.s3 import S3Bucket
from prefect_snowflake.database import SnowflakeConnector
from typing import List, Dict, Any
import logging
from prefect.blocks.secrets import Secret
from prefect.blocks.storage import BlockCredentials
from prefect import get_run_logger

# Import the SecretManager for secure credential access
from prefect.blocks.secrets import SecretManager

logger = logging.getLogger(__name__)

@task
def extract_from_s3(s3_bucket_block_name: str, s3_key: str) -> pd.DataFrame:
    """Extract data from S3"""
    task_logger = get_run_logger()
    task_logger.info(f"Extracting data from S3: {s3_key}")
    s3_bucket = S3Bucket.load(s3_bucket_block_name)
    s3_object = s3_bucket.read_path(s3_key)
    
    # Handle different file formats based on extension
    if s3_key.endswith(".csv"):
        df = pd.read_csv(s3_object)
    elif s3_key.endswith(".parquet"):
        df = pd.read_parquet(s3_object)
    elif s3_key.endswith(".json"):
        df = pd.read_json(s3_object)
    else:
        raise ValueError(f"Unsupported file format: {s3_key}")
    
    task_logger.info(f"Extracted {len(df)} rows from S3")
    return df

@task
def transform_data(df: pd.DataFrame, config: Dict[str, Any]) -> pd.DataFrame:
    """Apply transformations to the data"""
    task_logger = get_run_logger()
    task_logger.info("Transforming data")
    
    # Apply any transformation rules from the config
    transform_rules = config.get("transform_rules", {})
    
    # Example: Drop specified columns
    if "drop_columns" in transform_rules:
        df = df.drop(columns=transform_rules["drop_columns"], errors="ignore")
    
    # Example: Rename columns
    if "rename_columns" in transform_rules:
        df = df.rename(columns=transform_rules["rename_columns"])
    
    # Example: Fill missing values
    if "fill_na" in transform_rules:
        for col, value in transform_rules["fill_na"].items():
            if col in df.columns:
                df[col] = df[col].fillna(value)
    
    task_logger.info(f"Transformation complete. Dataframe shape: {df.shape}")
    return df

@task
def load_to_snowflake(
    df: pd.DataFrame, 
    snowflake_block_name: str = None,
    table_name: str = None,
    schema: str = None,
    environment: str = None
) -> None:
    """
    Load data to Snowflake
    
    If snowflake_block_name is provided, uses that block.
    Otherwise, tries to get credentials from SecretManager.
    """
    task_logger = get_run_logger()
    task_logger.info(f"Loading data to Snowflake: {schema}.{table_name}")
    
    # First try to use the block if provided
    if snowflake_block_name:
        try:
            snowflake_connector = SnowflakeConnector.load(snowflake_block_name)
            task_logger.info(f"Using Snowflake block: {snowflake_block_name}")
        except Exception as e:
            task_logger.warning(f"Failed to load Snowflake block: {e}")
            snowflake_connector = None
    else:
        snowflake_connector = None
    
    # If we couldn't load the block, try to create one from SecretManager
    if not snowflake_connector:
        task_logger.info("Creating Snowflake connector from secrets")
        try:
            # Get credentials from SecretManager
            secret_manager = SecretManager(environment=environment)
            
            # Get Snowflake credentials
            account = secret_manager.get_secret("SNOWFLAKE_ACCOUNT")
            user = secret_manager.get_secret("SNOWFLAKE_USER")
            password = secret_manager.get_secret("SNOWFLAKE_PASSWORD")
            warehouse = secret_manager.get_secret("SNOWFLAKE_WAREHOUSE")
            database = secret_manager.get_secret("SNOWFLAKE_DATABASE")
            schema = schema or secret_manager.get_secret("SNOWFLAKE_SCHEMA")
            role = secret_manager.get_secret("SNOWFLAKE_ROLE")
            
            # Create a temporary connector
            snowflake_connector = SnowflakeConnector(
                account=account,
                user=user,
                password=password,
                database=database,
                schema=schema,
                warehouse=warehouse,
                role=role
            )
        except Exception as e:
            task_logger.error(f"Failed to create Snowflake connector from secrets: {e}")
            raise
    
    # Connect to Snowflake
    with snowflake_connector.get_connection() as conn:
        # Create a cursor object
        cursor = conn.cursor()
        
        # Use the schema
        cursor.execute(f"USE SCHEMA {schema}")
        
        # Check if table exists, if not create it
        cursor.execute(f"""
        CREATE TABLE IF NOT EXISTS {table_name} (
            {', '.join([f'"{col}" VARCHAR' for col in df.columns])}
        )
        """)
        
        # Write the dataframe to Snowflake
        success, num_chunks, num_rows, output_rows = df.to_sql(
            name=table_name,
            con=conn,
            if_exists='append',
            index=False,
            schema=schema
        )
        
        task_logger.info(f"Loaded {num_rows} rows to Snowflake")

@flow(name="S3 to Snowflake ETL")
def s3_to_snowflake_flow(
    s3_bucket_block_name: str,
    s3_key: str,
    snowflake_block_name: str = None,
    table_name: str = None,
    schema: str = None,
    config_block_name: str = "etl-config",
    environment: str = None
):
    """
    Flow to extract data from S3, transform it, and load to Snowflake
    
    This flow can use either a Prefect block for Snowflake or get credentials
    from the SecretManager.
    """
    flow_logger = get_run_logger()
    
    # Load configuration
    config = JSON.load(config_block_name).value
    
    # Get values from config if not explicitly provided
    table_name = table_name or config.get("table_name")
    schema = schema or config.get("schema")
    
    if not table_name or not schema:
        raise ValueError("Table name and schema must be provided either as parameters or in the config")
    
    # Extract
    flow_logger.info(f"Extracting data from {s3_key}")
    df = extract_from_s3(s3_bucket_block_name, s3_key)
    
    # Transform
    flow_logger.info("Transforming data")
    df_transformed = transform_data(df, config)
    
    # Load
    flow_logger.info(f"Loading data to Snowflake {schema}.{table_name}")
    load_to_snowflake(
        df=df_transformed, 
        snowflake_block_name=snowflake_block_name, 
        table_name=table_name, 
        schema=schema,
        environment=environment
    )
    
    return f"Successfully loaded data from {s3_key} to Snowflake table {schema}.{table_name}"

if __name__ == "__main__":
    # This can be used for local testing
    s3_to_snowflake_flow(
        s3_bucket_block_name="dev-data-bucket",
        s3_key="sample_data.csv",
        snowflake_block_name="dev-snowflake",
        table_name="sample_table",
        schema="DEV_SCHEMA",
        config_block_name="etl-config",
        environment="dev"
    ) 