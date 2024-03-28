# show-sbom task

Shows the Software Bill of Materials (SBOM) generated for the built image in CyloneDX JSON format.

The parameter named PLATFORM can be used to specify the arch to display the sbom for in the case of a multi-arch image. 
In the case of a single arch image, the parameter is ignored. 
If PLATFORM is empty and the image is multi-arch, the task defaults to 'linux/amd64'

## Parameters
| name      | description                                                                                                                                                                                               | default value | required  |
|-----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|-----------|
| IMAGE_URL | Fully qualified image name to show SBOM for.                                                                                                                                                              |               | true      |
| PLATFORM  | Specific architecture to display the SBOM for. An example arch would be "linux/amd64". If IMAGE_URL refers to a multi-arch image and this parameter is empty, the task will default to use "linux/amd64". | linux/amd64   | false     |

