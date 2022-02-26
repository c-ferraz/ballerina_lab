import ballerina/io;
import ballerina/log;
import ballerina/http;
import ballerina/lang.value;

//This defines a listener, the port param is mandatory but it is nice to use the config one
listener http:Listener default = new (port = 9090, config = {host: "172.17.168.228"});

public function main() {
    io:println("Hello, World!");
    log:printInfo("APPLICATION START");
}

//Service indicates a path into a listener, bellow a service you can set resources that are the endpoints of the api
//It is possible to set some global configurations using anotations under a service and it will affect all resources inside
service / on default {

    //When defining a resource you must define the HTTP verb, the path and the return, the path is added to the resource, in this example it will look like {host}/hw
    //You can define multiple return types by using a pipe to indicate the diferent types of responses you want
    resource function get hw() returns http:Ok|json|xml{

        //The bellarina/http module provides boilerplate http responses defined by status code where you can define the mediaType, body and headers
        http:Ok r = {
            mediaType: "application/json",
            body: "Hello World",
            headers: {}
        };

        return r;
        //return <http:Ok>{mediaType: "application/json", body: "Hello World", headers: {}};
        //Casting an object is done by adding the type into <> before the object, like the example above
    }

    resource function get status() returns http:Response{
        //While the http:Ok is a record the http:Response is a class, and behave diferent
        //By using the response class you can customaize all types of responses to the client
        http:Response r = new();
        r.statusCode = 200;
        r.reasonPhrase = "OK";
        r.setJsonPayload({status: "UP"});
        return r;
    }

    //The http:ResourceConfig annotation defines settings for this resource only
    //Some examples are auth, allowed content-types and cors settings
    @http:ResourceConfig {
        consumes: ["application/json"],
        produces: ["text/plain"]
    }
    resource function post user(@http:Payload json user) returns http:Created|http:BadRequest{


        
        if (user.firstName == () || user.lastName == () || user.age == ()) {
            http:BadRequest r = {
                body: "One or more required fields not found."
            };
            return r;

        }

        string firstName = checkpanic value:ensureType(user.firstName);
        
        http:Created r = {
        body: "User " + firstName + " created (But not really)."
        };

        return r;
    }

    //The bellow resource path defines a URI parameter
    resource function get user/[int id]() returns http:Ok{

        //You can use parameters and variables inside a XML by using ${name} inside the expression
        xml payload = xml `<user>
                            <id>${id}</id>
                            <firstName>John</firstName>
                            <lastName>Doe</lastName>
                            <age>34</age>
                        </user>`;

        return <http:Ok>{mediaType: "application/xml", body: payload};
    }
}