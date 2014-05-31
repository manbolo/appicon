#!/usr/bin/env python
from StringIO import StringIO
import requests
from PIL import Image
from slugify import slugify


def download_icon(icon_url, title, mask):
    """
    """
    # Download icon an apply mask.
    icon_data = requests.get(icon_url)
    icon = Image.open(StringIO(icon_data.content))
    icon.putalpha(mask)

    # Compute and save thumbnails.
    for size in [1024, 512, 120, 114, 60, 57]:
        icon_resized = icon.resize((size, size), Image.ANTIALIAS)
        icon_resized.save("icon_{0}_{1}x{1}.png".format(title, size))


def download_app_metadata(app_id, mask):
    """
    """
    print("download_app_json {}".format(app_id))

    url = "http://itunes.apple.com/us/lookup?id={}".format(app_id)
    r = requests.get(url)
    if r.status_code != 200:
        print('Error downloading {} {}'.format(url, r.status_code))
        return

    results = r.json()

    meta = results["results"][0]
    icon_url = meta["artworkUrl512"]
    title = slugify(meta["trackCensoredName"])

    download_icon(icon_url, title, mask)


def download_icon_mask():
    """
    """
    # Download the mask from Github, this way we don't
    # have to provide mask.png and the script is self contained.
    mask_url = "https://raw.githubusercontent.com/manbolo/appicon/master/mask.png"
    mask_data = requests.get(mask_url)
    mask = Image.open(StringIO(mask_data.content))
    mask = mask.convert('L')
    return mask


def download_apps():
    """
    """
    app_ids = [
        "400274934",  # Meon
        "598581396",  # Kingdom Rush Frontiers
    ]

    mask = download_icon_mask()

    [download_app_metadata(app_id, mask) for app_id in app_ids]


if __name__ == '__main__':

    download_apps()
