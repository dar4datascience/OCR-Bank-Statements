import os
from typing import Iterator, MutableSequence, Optional, Sequence, Tuple

from google.protobuf.json_format import MessageToDict
from google.api_core.client_options import ClientOptions
from google.cloud import documentai  # type: ignore
from tabulate import tabulate

project_id = os.getenv("PROJECT_ID", "")
location = os.getenv("API_LOCATION", "")
GOOGLE_APPLICATION_CREDENTIALS = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")

assert project_id, "PROJECT_ID is undefined"
assert location in ("us", "eu"), "API_LOCATION is incorrect"
assert GOOGLE_APPLICATION_CREDENTIALS, "GOOGLE_APPLICATION_CREDENTIALS is undefined"

# TODO(developer): Uncomment these variables before running the sample.
# project_id = "YOUR_PROJECT_ID"
# location = "YOUR_PROCESSOR_LOCATION"  # Format is "us" or "eu"
# processor_display_name = "YOUR_PROCESSOR_DISPLAY_NAME" # Must be unique per project, e.g.: "My Processor"

def predict_with_hsbc_processor(project_id,
location,
file_path):
    
    # You must set the `api_endpoint` if you use a location other than "us".
    opts = ClientOptions(api_endpoint=f"{location}-documentai.googleapis.com")
    
    # Create a client
    client = documentai.DocumentProcessorServiceClient(client_options=opts)
    
    # Initialize request argument(s)
    request = documentai.GetProcessorRequest(
    name=f"projects/{project_id}/locations/{location}/processors/bb6921b1953a8ea7"
    )
    
    # Make the request
    processor = client.get_processor(request=request)
    
    # Print the processor information
    print(f"Processor Name: {processor.name}")

    # Read the file into memory
    with open(file_path, "rb") as image:
        image_content = image.read()

    # Load binary data
    raw_document = documentai.RawDocument(
        content=image_content,
        mime_type="application/pdf",  # Refer to https://cloud.google.com/document-ai/docs/file-types for supported file types
    )

    # Configure the process request
    # `processor.name` is the full resource name of the processor, e.g.:
    # `projects/{project_id}/locations/{location}/processors/{processor_id}`
    request = documentai.ProcessRequest(name=processor.name, raw_document=raw_document)

    result = client.process_document(request=request)

    # For a full list of `Document` object attributes, reference this page:
    # https://cloud.google.com/document-ai/docs/reference/rest/v1/Document
    document = result.document

    # # Read the text recognition output from the processor
    # print("The document contains the following text:")
    # print(document.text)


    return(document)
  
