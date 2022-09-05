# https://falconframework.org/
# pip install falcon
# pip install gunicorn

# start the server: 
# gunicorn rest_server:app

import falcon
import os
import requests
import shutil
import threading
import time

from pathlib import Path
from main import CoastSnapPy

def process_snap(data):

    # gather snap data
    filepath = Path(data['snap_filepath'])
    id = data['snap_id']
    country = str(data['snap_country']).lower()
    location = str(data['snap_location']).lower()

    # generate new filename for the processed image
    filepath = Path(filepath)
    dirpath = filepath.parent
    new_filename = f'processed_{filepath.name}'

    try:
        created_path = CoastSnapPy(
            location,
            filepath,
            outputPath=os.getenv('OUTPUT_PATH'),
            show_plots=False
        )
    except:
        created_path = False

    if created_path == False:
        message = 'processing_failed'
    elif created_path == 'NonExistent':
        message = 'non_existent_location'
    else:

        copy_path = filepath.parent / Path(created_path).name
        shutil.copyfile(
            created_path,
            copy_path
        )
        message = str(copy_path.name)

    # response with sending a put request to the Phoenix app
    response = requests.put(
        f'http://127.0.0.1:4000/api/python_ready/{id}', 
        data={ 'processed_filepath': message }
    )

    return response


class Snap:

    def on_post(self, req, resp):
        data = req.get_media()
        t = threading.Thread(target=process_snap, args=(data,))
        t.start()
        resp.media = { 'status': 'received', 'image_id': data['snap_id'] }
        resp.status = 200


# -- start the app --
app = falcon.App()
app.add_route('/snap', Snap())