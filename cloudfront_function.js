function handler(event) {
    var request = event.request;

    var destination = "${destination}"; //${destination} is replaced by Terraform
    var isStaticRedirect = Boolean("${is_static_redirect}"); //${is_static_redirect} is replaced by Terraform

    if (isStaticRedirect) { //Add the request uri unless it's a static redirect
        var locationHeader = destination;
    }
    else {
        var locationHeader = destination + request.uri;
    }

    var response = {
        statusCode: 301,
        statusDescription: 'Moved Permanently',
        headers: {
            "location": { "value": locationHeader }
        }
    };

    return response;
}