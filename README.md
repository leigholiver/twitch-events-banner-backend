# twitch-events-banner-backend

backend to grab upcoming events from liquipedia and populate an s3 static site

[starcraft json](https://twitch.nydus.club/starcraft.json) [starcraft2 json](https://twitch.nydus.club/starcraft2.json)

creates the following resources:
- s3 static site using the contents of `src/s3`
- lambda function to retrieve the upcoming tournaments from the liquipedia API, and generate json files in the s3 bucket
- cloudwatch event rule to trigger the lambda function periodically


### notes

the lambda uses the `Liquipedia:Tournaments` page to grab the upcoming events

you can get a list of images on a page, but im not sure how to specify the infobox image or grab that reliably
`https://liquipedia.net/starcraft2/api.php?action=query&prop=images&titles=ESL%20Pro%20Tour/2020/21/Masters/Fall/CN&format=json`


### deployment

copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your domain name etc

use terraform to create the resources using `terraform init`, `terraform apply`

create a CNAME dns record on pointing to `s3-website.[your aws region].amazonaws.com`
