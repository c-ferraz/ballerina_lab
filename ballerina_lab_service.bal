import ballerina/http;

listener http:Listener ep0 = new (9090, config = {host: "localhost"});

service / on ep0 {
    resource function get healthcheck() returns ServiceStatus {
        return {status: "OK"};
    }
    resource function post convertJson(string format, string? xmlRoot, @http:Payload record {||} payload) returns xml|record {|*http:BadRequest; string body;|} {
        
        return toXml({});
    }
    resource function get authTest() returns string|record {|*http:Unauthorized; string body;|} {

        return "";
    }
}

function toXml(json input) returns xml {
    return xml `<default></default>`;
}