#helper to pull docker image to local registry
param(
$localregistry = "192.168.2.40:5000",
$tag = "latest",
$image
)
$localimage = "$($localregistry)/$($image):$($tag)"
docker pull $image
docker tag $image $localimage 
docker push $localimage

