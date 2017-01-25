# Google Vision Api filter plugin for Embulk

Google Vision Api filter plugin for Embulk.

Very easy image recognition.

## Overview

* **Plugin type**: filter

## Configuration

- **out_key_name**: out_key_name (string)
- **image_path_key_name**: image_path_key_name (string)
- **features**: features (array)
  - **type**: FACE_DETECTION or LANDMARK_DETECTION or LOGO_DETECTION or LABEL_DETECTION or TEXT_DETECTION or SAFE_SEARCH_DETECTION or IMAGE_PROPERTIES (string)
  - **maxResults**: maxResults (integer)
- **delay**: delay (integer, default: 0)
- **image_num_per_request**: image_num_per_request (integer, default: 16)
- **google_api_key**: google_api_key (string, default: ENV['GOOGLE_API_KEY'])

## Example

### input
```yaml
    - { image_path: 'http://www.embulk.org/docs/_images/embulk-logo.png' }
```

* respond localfile path and http URI(http://〜) and GCS Image(gs://〜).

### setting
```yaml
filters:
  - type: google_vision_api
    image_path_key_name: image_path
    out_key_name: image_info
    image_num_per_request: 5
    features: 
      - {type: FACE_DETECTION, "maxResults":5 }
      - {type: LANDMARK_DETECTION, "maxResults":5 }
      - {type: LOGO_DETECTION, "maxResults":5 }
      - {type: LABEL_DETECTION, "maxResults":5 }
      - {type: TEXT_DETECTION, "maxResults":5 }
      - {type: SAFE_SEARCH_DETECTION, "maxResults":5 }
      - {type: IMAGE_PROPERTIES, "maxResults":5 }
```

### output
```
image_path (string) : http://www.embulk.org/docs/_images/embulk-logo.png
image_info (  json) : {"labelAnnotations":[{"mid":"/m/0dwx7","description":"logo","score":0.86478204},{"mid":"/m/03gq5hm","description":"font","score":0.8472268},{"mid":"/m/0215n","description":"cartoon","score":0.82311255},{"mid":"/m/03g09t","description":"clip art","score":0.69382942},{"mid":"/m/01cd9","description":"brand","score":0.59691668}],"textAnnotations":[{"locale":"id","description":"embulk\n","boundingPoly":{"vertices":[{"x":67,"y":475},{"x":812,"y":475},{"x":812,"y":629},{"x":67,"y":629}]}},{"description":"embulk","boundingPoly":{"vertices":[{"x":68,"y":475},{"x":813,"y":475},{"x":813,"y":629},{"x":68,"y":629}]}}],"safeSearchAnnotation":{"adult":"VERY_UNLIKELY","spoof":"UNLIKELY","medical":"UNLIKELY","violence":"VERY_UNLIKELY"},"imagePropertiesAnnotation":{"dominantColors":{"colors":[{"color":{"red":231,"green":59,"blue":11},"score":0.26240975,"pixelFraction":0.029842343},{"color":{"red":243,"green":176,"blue":124},"score":0.0057866224,"pixelFraction":0.010698198},{"color":{"red":252,"green":250,"blue":248},"score":0.0025187095,"pixelFraction":0.6255005},{"color":{"red":232,"green":79,"blue":16},"score":0.17388013,"pixelFraction":0.023773775},{"color":{"red":225,"green":75,"blue":27},"score":0.14469221,"pixelFraction":0.034909911},{"color":{"red":222,"green":52,"blue":17},"score":0.13995738,"pixelFraction":0.018768769},{"color":{"red":243,"green":106,"blue":31},"score":0.090499125,"pixelFraction":0.025525525},{"color":{"red":243,"green":128,"blue":38},"score":0.064238794,"pixelFraction":0.050425425},{"color":{"red":242,"green":104,"blue":47},"score":0.033798043,"pixelFraction":0.014451952},{"color":{"red":238,"green":131,"blue":65},"score":0.027836611,"pixelFraction":0.010948448}]}}}
```

## Vision API Limits

| Type of Limit | Usage Limit |
|:-----------|------------:|
| MB per image |  4 MB |
| MB per request |  8 MB |
| Requests per second | 10 |
| Requests per feature per day | 700,000 |
| Requests per feature per month | 20,000,000 |
| Images per second | 8 |
| Images per request |  16 |

see. [Usage Limits  \|  Google Cloud Vision API  \|  Google Cloud Platform](https://cloud.google.com/vision/limits)


## Build

```
$ rake
```
