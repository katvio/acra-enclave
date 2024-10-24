import os
import base64
import boto3
from botocore.exceptions import ClientError, NoRegionError

def decrypt_master_key():
    try:
        # Read the encrypted master key from file
        with open('/keys/encrypted_master_key', 'rb') as f:
            encrypted_key = f.read()

        # Create a KMS client
        # Use the KMS proxy endpoint provided by Enclaver and specify the region
        kms_client = boto3.client('kms',
                                  endpoint_url='http://localhost:9999',
                                  region_name='us-east-1')  # Specify your region here

        # Decrypt the key
        response = kms_client.decrypt(
            CiphertextBlob=base64.b64decode(encrypted_key),
            KeyId='XXX',
            EncryptionContext={'acra': 'master_key'}
        )

        # Get the plaintext key
        decrypted_key = response['Plaintext']

        # Write the decrypted key to a file
        with open('/keys/master_key.bin', 'wb') as f:
            f.write(decrypted_key)

        print("Master key decrypted successfully")
    except FileNotFoundError:
        print("Error: Encrypted master key file not found")
    except NoRegionError:
        print("Error: No AWS region specified. Please set the AWS_DEFAULT_REGION environment variable or specify the region in the boto3.client() call.")
    except ClientError as e:
        print(f"Error decrypting master key: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")

if __name__ == '__main__':
    decrypt_master_key()