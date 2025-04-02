from prefect.blocks.system import Secret
from prefect_aws.credentials import AwsCredentials
from prefect_aws.secrets_manager import AwsSecretsManager
import os
import json
from dotenv import load_dotenv
import logging

# Load environment variables for local development
load_dotenv()

logger = logging.getLogger(__name__)

class SecretManager:
    """
    A class to manage secrets with fallback mechanisms.
    
    This allows retrieving secrets from AWS Secrets Manager,
    with fallback to Prefect Secret blocks or environment variables.
    """
    
    def __init__(self, environment=None):
        """
        Initialize the SecretManager.
        
        Args:
            environment (str, optional): The deployment environment (dev, staging, prod).
                If not provided, will try to get from ENVIRONMENT env var, defaulting to "dev".
        """
        self.environment = environment or os.getenv("ENVIRONMENT", "dev")
        self._aws_secrets_manager = None
        self._initialized = False
    
    def initialize(self):
        """Initialize the AWS Secrets Manager connection if possible."""
        if self._initialized:
            return
            
        try:
            # Try to get AWS credentials from Prefect block
            aws_creds = AwsCredentials.load("aws-credentials")
            
            # Create AWS Secrets Manager block
            self._aws_secrets_manager = AwsSecretsManager(
                aws_credentials=aws_creds,
                secret_name=f"data-platform/{self.environment}/credentials"
            )
            logger.info("Successfully initialized AWS Secrets Manager")
        except Exception as e:
            logger.warning(f"Failed to initialize AWS Secrets Manager: {e}")
            logger.warning("Will fall back to environment variables or Prefect Secret blocks")
            self._aws_secrets_manager = None
            
        self._initialized = True
    
    def get_secret(self, key):
        """
        Get a secret using the fallback chain.
        
        Args:
            key (str): The key of the secret to retrieve.
            
        Returns:
            The secret value.
            
        Raises:
            ValueError: If the secret could not be found in any source.
        """
        # Ensure initialization
        if not self._initialized:
            self.initialize()
            
        # Try AWS Secrets Manager first
        if self._aws_secrets_manager:
            try:
                secret_dict = json.loads(self._aws_secrets_manager.get_secret_value())
                if key in secret_dict:
                    return secret_dict[key]
                logger.debug(f"Key '{key}' not found in AWS Secrets Manager")
            except Exception as e:
                logger.warning(f"Error accessing AWS Secrets Manager: {e}")
        
        # Try Prefect Secret block
        try:
            secret_block = Secret.load(key)
            return secret_block.get()
        except Exception as e:
            logger.debug(f"Error loading Prefect Secret block '{key}': {e}")
        
        # Try environment variable
        env_value = os.getenv(key)
        if env_value:
            return env_value
            
        # Could not find the secret
        raise ValueError(f"Secret '{key}' not found in any source")


def register_aws_credentials():
    """Register AWS credentials as a Prefect block."""
    try:
        aws_credentials = AwsCredentials(
            aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
            aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
            aws_session_token=os.getenv("AWS_SESSION_TOKEN"),  # Optional
            region_name=os.getenv("AWS_REGION", "us-west-2")
        )
        aws_credentials.save("aws-credentials", overwrite=True)
        print("AWS credentials registered successfully")
    except Exception as e:
        print(f"Error registering AWS credentials: {e}")


def register_secret_blocks():
    """Register environment variables as Prefect Secret blocks for local development."""
    # List of secrets to register
    secret_keys = [
        "SNOWFLAKE_ACCOUNT",
        "SNOWFLAKE_USER",
        "SNOWFLAKE_PASSWORD",
        "SNOWFLAKE_WAREHOUSE",
        "SNOWFLAKE_DATABASE",
        "SNOWFLAKE_SCHEMA",
        "SNOWFLAKE_ROLE"
    ]
    
    for key in secret_keys:
        value = os.getenv(key)
        if value:
            try:
                secret_block = Secret(value=value)
                secret_block.save(key, overwrite=True)
                print(f"Secret block {key} registered successfully")
            except Exception as e:
                print(f"Error registering Secret block {key}: {e}")


if __name__ == "__main__":
    # Register AWS credentials and secrets for local development
    register_aws_credentials()
    register_secret_blocks()
    
    # Test secret retrieval
    secret_manager = SecretManager()
    
    try:
        snowflake_password = secret_manager.get_secret("SNOWFLAKE_PASSWORD")
        print(f"Successfully retrieved SNOWFLAKE_PASSWORD (not showing value)")
    except Exception as e:
        print(f"Could not retrieve SNOWFLAKE_PASSWORD: {e}") 