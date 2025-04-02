import pandas as pd
from prefect import flow, task
from prefect.blocks.system import JSON
from prefect_aws.s3 import S3Bucket
from prefect_snowflake.database import SnowflakeConnector
from typing import List, Dict, Any
import logging

logger = logging.getLogger(__name__)

@task
def extract_from_s3(s3_bucket_block_name: str, s3_key: str) -> pd.DataFrame:
    """Extract data from S3"""
    logger.info(f"Extracting data from S3: {s3_key}")
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
    
    logger.info(f"Extracted {len(df)} rows from S3")
    return df

@task
def transform_data(df: pd.DataFrame, config: Dict[str, Any]) -> pd.DataFrame:
    """Apply transformations to the data"""
    logger.info("Transforming data")
    
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
    
    logger.info(f"Transformation complete. Dataframe shape: {df.shape}")
    return df

@task
def load_to_snowflake(
    df: pd.DataFrame, 
    snowflake_block_name: str,
    table_name: str,
    schema: str
) -> None:
    """Load data to Snowflake"""
    logger.info(f"Loading data to Snowflake: {schema}.{table_name}")
    
    # Load the Snowflake connector block
    snowflake_connector = SnowflakeConnector.load(snowflake_block_name)
    
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
        
        logger.info(f"Loaded {num_rows} rows to Snowflake")

@flow(name="S3 to Snowflake ETL")
def s3_to_snowflake_flow(
    s3_bucket_block_name: str,
    s3_key: str,
    snowflake_block_name: str,
    table_name: str,
    schema: str,
    config_block_name: str
):
    """Flow to extract data from S3, transform it, and load to Snowflake"""
    # Load configuration
    config = JSON.load(config_block_name).value
    
    # Extract
    df = extract_from_s3(s3_bucket_block_name, s3_key)
    
    # Transform
    df_transformed = transform_data(df, config)
    
    # Load
    load_to_snowflake(df_transformed, snowflake_block_name, table_name, schema)
    
    return f"Successfully loaded data from {s3_key} to Snowflake table {schema}.{table_name}"

if __name__ == "__main__":
    # This can be used for local testing
    s3_to_snowflake_flow(
        s3_bucket_block_name="dev-data-bucket",
        s3_key="sample_data.csv",
        snowflake_block_name="dev-snowflake",
        table_name="sample_table",
        schema="DEV_SCHEMA",
        config_block_name="etl-config"
    ) 