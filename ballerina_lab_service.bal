import ballerina/http;
import ballerina/log;

listener http:Listener ep0 = new (9090, config = {host: "localhost"});

public function main(){
    log:printInfo("SERVICE START");
}

service / on ep0 {
    resource function get healthcheck() returns ServiceStatus {
        return {status: "OK"};
    }
    resource function post convertJson(string format, string? xmlRoot, @http:Payload json payload) returns xml|record {|*http:BadRequest; string body;|} {
        log:printInfo(payload.toBalString());
        return toXml(payload);
    }

    resource function post jsonTest(@http:Payload TestJson payload) returns json|record {|*http:BadRequest; string body;|}|record {|*http:MethodNotAllowed; string body;|} {

        json response = {
            "name": payload.lastName != () ? payload.name.'join(" ", payload.lastName.toString()) : payload.name
        };

        if (payload.comment != ()){
            response = checkpanic response.mergeJson( {"comment": payload.comment.toString()} );
        }
        
        return response;
    }

    resource function get authTest() returns string|record {|*http:Unauthorized; string body;|} {
        
        return "";
    }
}

function toXml(json input) returns xml {
    xml? a;
    return xml `<default></default>`;
}
