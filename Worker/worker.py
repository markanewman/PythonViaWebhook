import base64
import configparser
import logging
import sys
import tempfile
import time
import uuid
from process import work
from applicationinsights import channel
from applicationinsights.logging import LoggingHandler
from azure.storage.queue import QueueService
from azure.storage.blob import BlockBlobService
from pathlib import Path

__version__ = '0.0.1'
__incoming__ = 'todo'
__outgoing__ = 'done'

def worker(ikey, storage_account_name, storage_account_key):
    setup_logging(ikey)
    logging.info('Worker - Starting')
    state = work.init()
    queue_service = QueueService(account_name = storage_account_name, account_key = storage_account_key)
    blob_service = BlockBlobService(account_name = storage_account_name, account_key = storage_account_key)
    process_queue(state, queue_service, blob_service)
    logging.info('Worker - Complete')
    logging.shutdown()

def setup_logging(ikey):
    telemetry_channel = channel.TelemetryChannel()
    telemetry_channel.context.application.ver = __version__
    telemetry_channel.context.properties['worker.id'] = str(uuid.uuid4())	
    handler = LoggingHandler(ikey, telemetry_channel = telemetry_channel)
    logging.basicConfig(handlers = [handler], format = '%(levelname)s: %(message)s', level = logging.DEBUG)

def process_queue(state, queue_service, blob_service):
    num_messages = 16
    visibility_timeout = 60 * 60
    getmore = True
    tmp_dir = tempfile.TemporaryDirectory()
    while getmore:
        getmore = False
        messages = queue_service.get_messages(__incoming__, num_messages = num_messages, visibility_timeout = visibility_timeout)
        for message in messages:
            getmore = True
            process_message(state, message, tmp_dir.name, queue_service, blob_service)

def process_message(state, message, tmp_dir_name, queue_service, blob_service):
    logging.info('Message Processing - Starting', extra = {'message.id': message.id})
    blob_name = base64.decodebytes(message.content.encode()).decode()
    logging.info('Message Processing - Running', extra = {'message.id': message.id, 'blob_name': blob_name})
    file_names = stage_files(message, blob_service, blob_name, tmp_dir_name)
    if safe_execute(state, file_names['in'], file_names['out']):
        blob_service.create_blob_from_path(__outgoing__, blob_name, file_names['out'])
        queue_service.put_message(__outgoing__, blob_name)
        queue_service.delete_message(__incoming__, message.id, message.pop_receipt)
    logging.info('Message Processing - Complete', extra = {'message.id': message.id})

def stage_files(message, blob_service, blob_name, tmp_dir_name):
    logging.debug('File Staging - Starting', extra = {'message.id': message.id})
    file_in_path = Path(tmp_dir_name).joinpath(str(uuid.uuid4()))
    file_out_path = Path(tmp_dir_name).joinpath(str(uuid.uuid4()))
    xxx = blob_service.get_blob_to_path(__incoming__, blob_name , file_path = file_in_path)
    open(file_out_path, 'w').close()
    logging.debug('File Staging - Complete', extra = {'message.id': message.id}) 
    return {'in' : file_in_path, 'out': file_out_path}

def safe_execute(state, file_in_path, file_out_path):
    try:
        work.execute(state, file_in_path, file_out_path)
        return True
    except e:
        logging.error(e)
        return False

if __name__ == '__main__':
    config = configparser.ConfigParser()
    config.read('secrets.ini')
    worker(config['AZURE']['iKey'], config['AZURE']['AccountName'], config['AZURE']['AccountKey'])
