import os, requests, re, json, time, boto3

filename   = "%s.json"
base_url   = "https://liquipedia.net/%s/api.php?action=query&prop=revisions&titles=Liquipedia:Tournaments&rvprop=content&format=json"
page_url   = "https://liquipedia.net/%s/%s"
icon_url   = "https://liquipedia.net/%s/Special:FilePath/%s"
user_agent = "%s/%s; %s" % (os.getenv("NAME",    "twitch-events-banner-prototype"), 
                            os.getenv("VERSION", "0.0.1"), 
                            os.getenv("AUTHOR",  "@tnsc2"))

def lambda_handler(event, context):
    for game in ["starcraft", "starcraft2"]:
        data = get_liquipedia_events(game)
        if data:
            put_into_s3(game, data)

def put_into_s3(game, content):
    bucket_name = os.getenv("BUCKET_NAME")
    if not bucket_name:
        return

    s3 = boto3.resource("s3")
    s3.Bucket(bucket_name).put_object(Key=(filename % game), Body=json.dumps({
        "events":  content,
        "created": time.time()
    }), ContentType="application/json", ACL="public-read")

def get_liquipedia_events(game):
    response = requests.get((base_url % game), headers = {"User-Agent": user_agent})
    data     = response.json()
    content  = ""
    for key in data["query"]["pages"].keys():
        for revision in data["query"]["pages"][key]["revisions"]:
            content = revision["*"]
    
    matches = re.findall(r"\*Upcoming((.|\n)*)\*Ongoing", content)
    if len(matches) != 1:
        return

    return parse_liquipedia_events(game, matches[0])

def parse_liquipedia_events(game, events):
    output          = []
    filtered_events = list(filter(None, events[0].split("\n")))
    for event in filtered_events:
        match_data = {
            "link":     "",
            "name":     "",
            "start":    "",
            "end":      "",
            "icon":     "",
            "icon_url": "",
        }
        for value in event.split(" | "):
            if value.startswith("**"):
                match_data["link"]  = page_url % (game, value.replace("**", ""))
            elif value.startswith("startdate="):
                match_data["start"] = value.replace("startdate=", "")
            elif value.startswith("enddate="):
                match_data["end"]   = value.replace("enddate=", "")
            elif value.startswith("icon=") and value != "icon=":
                match_data["icon"]  = value.replace("icon=", "")
            elif value.startswith("iconfile=") and value != "iconfile=":
                match_data["icon_url"]   = icon_url % (game, value.replace("iconfile=", ""))
            elif value != "icon=" and value != "iconfile=":
                match_data["name"]  = value
        output.append(match_data)
    return output
    
if __name__ == "__main__":
    lambda_handler({}, {})