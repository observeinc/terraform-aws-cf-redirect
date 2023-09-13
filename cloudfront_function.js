function handler(event) {
    var request = event.request;

    var destination = "{destination}" //{destination} is replaced by Terraform
    var isStaticRedirect = false

    if(!isStaticRedirect) { //Add the request uri unless it's a static redirect
        var locationHeader = destination + request.uri
    }
    else {
        var locationHeader = destination
    }

    var response = {
        statusCode: 301,
        statusDescription: 'Moved Permanently',
        headers: {
            "location": {"value": locationHeader }
        }
    }

    return response;
}