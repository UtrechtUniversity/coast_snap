# https://falconframework.org/
# pip install falcon
# pip install gunicorn

# start the server: 
# gunicorn rest_server:app

import falcon
import requests
import threading
import time

from pathlib import Path
from PIL import Image

def process_snap(data):
    # sleep for 10 secs 
    time.sleep(5)
    
    # gather snap data
    filepath = Path(data['snap_filepath'])
    id = data['snap_id']
    country = data['snap_country']
    location = data['snap_location']

    # generate new filename for the processed image
    filepath = Path(filepath)
    dirpath = filepath.parent
    new_filename = f'processed_{filepath.name}'

    # rotate file
    image  = Image.open(filepath)
    rotated = image.rotate(90)
    # save file
    new_filepath = Path(dirpath, new_filename)
    rotated.save(new_filepath)

    # response with sending a put request to the Phoenix app
    response = requests.put(
        f'http://127.0.0.1:4000/api/python_ready/{id}', 
        data={ 'processed_filepath': str(new_filepath) }
    )
    return response

class Snap:

    def on_post(self, req, resp):
        data = req.get_media()
        t = threading.Thread(target=process_snap, args=(data,))
        t.start()
        resp.media = { 'status': 'received', 'image_id': data['snap_id'] }
        resp.status = 200

# -- snip --

app = falcon.App()
app.add_route('/snap', Snap())