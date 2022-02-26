import ballerina/http;
import ballerina/log;
import ballerina/auth;
import ballerina/regex;
import ballerina/lang.array;

// Listener definition, there are many ways to set it
listener http:Listener ep0 = new (9090, config = {host: "localhost"});

public function main() {
    log:printInfo("SERVICE START"); // simple log that indicates the start of the application
}

// Entire service configuration, can set authentication at service level (all resources inside)
// @http:ServiceConfig {
//     auth: [
//         {
//             fileUserStoreConfig: {}   
//         }
//     ]
// }
service / on ep0 {

    // The annotation can be done in a single line or formated as shown on the resource /authTest
    @http:ResourceConfig { produces: ["application/json"]}
    resource function get healthcheck() returns ServiceStatus {
        return {status: "OK"};
    }
    resource function post convertJson(string format, string? xmlRoot, @http:Payload json payload) returns xml|record {|*http:BadRequest; string body;|} {
        log:printInfo(payload.toBalString());
        return toXml(payload);
    }

    resource function post jsonTest(@http:Payload TestJson payload) returns json|record {|*http:BadRequest; string body;|}|record {|*http:MethodNotAllowed; string body;|} {
        
        // Creates a response json object, validates if lastName is present and adds it to name
        json response = {
            "name": payload.lastName != () ? payload.name.'join(" ", payload.lastName.toString()) : payload.name
        };

        // Validates that comment exists on the payload
        if (payload.comment != ()) {
            // Adds the comment to the response json object
            response = checkpanic response.mergeJson({"comment": payload.comment.toString()});
        }

        // If you don't specify a http response object default to status code 200 OK 
        return response;
    }


    // Entire resource configuration, automatically authenticates incoming user and responds acordingly
    // Those automated responses are for all possible authentication failures (including scope not present)
    // Altough it is organized like an object it counts as a single line anotation, other anotations can be put on top of it using the same syntax
    @http:ResourceConfig {
        consumes: ["application/json"],
        produces: ["application/json"],
        auth: [
            {
                fileUserStoreConfig: {},
                scopes: ["test"]   
            }
        ]
    }
    // It is possible to set up all kinds of response objects by separing them with pipe (|)
    // Or has demonstrated bellow you can configure your own http:Response object
    resource function get authTest() returns http:Ok|http:Forbidden|http:Unauthorized|http:UnsupportedMediaType {
        string message = "Basic Authentication successful";
        
        // Template response object OK, can specify mediaType, body and headers
        http:Ok ok = {
            mediaType: "application/json",
            body: message
        };
        return ok;
    }

    // This does the authentication manually, requires setting the Authorization header on the parameters
    // The http:Response return is because we can configure more aspects of the response instead of the template http objects (http:Ok for example)
    resource function get manualAuth(@http:Header {name: "Authorization"} string authorization) returns http:Response{
        // Splits the header and grabs only the actual token
        string token = (regex:split(authorization, " "))[1];
        // this reads the credentials and returns a string tuple (user, pass)
        // [string, string] credentials = checkpanic auth:extractUsernameAndPassword(token);
        // Objects can also be instantiated by the following syntax auth:ListenerFileUserStoreBasicAuthProvider lAuth = new ();
        var lAuth = new auth:ListenerFileUserStoreBasicAuthProvider();
        // Authenticates the user and saves their info into the user variable
        auth:UserDetails user = checkpanic lAuth.authenticate(token);


        // Innit response object
        http:Response response = new ();
        // Innit response message
        string message = "";
        
        // user.scopes returns an string array (optional) that contains the scopes the user has access to
        if (array:indexOf(<string[]>user.scopes, "test", 0) != () ) {
            message = "Basic Authentication successful";
            response.statusCode = 200;
            response.reasonPhrase = "OK";
        } else {
            message = "Invalid credentials";
            response.statusCode = 401;
            response.reasonPhrase = "Unauthorized";
        }

        // Set response as a json payload with the value of the string message
        response.setJsonPayload(message);

        return response;
    }
}

// function declaration example
function toXml(json input) returns xml {
    // XMLs are writen as string and parsed into a XML type variable
    // In this case the question mark at the end of the type indicates that it is optional
    xml? a =  xml `<default></default>`;

    // Optional types are different from regular types, needs typecasting/coercion to work with regular types
    // Hence the <xml>a to cast it into a xml object
    return <xml>a;
}
