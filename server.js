var express = require('express');
var app = express();

// load and save values to the filesystem
var fs = require('fs'); 

// use environment variables file
const dotenv = require('dotenv');
dotenv.config();

var bodyParser = require('body-parser');
app.use(bodyParser.json() );  
app.use(bodyParser.urlencoded({extended: true}));

// *******
// Cors
// *******
var cors = require("cors"); // Cors
app.use(cors());
var port = process.env.PORT || 8080;
var auth = require('basic-auth'); 

// *******
// File log
// *******
var disable_file_log = false;
// *******
// Cloudant
// *******
// Create the connection to the cloudant service
var Cloudant = require("@cloudant/cloudant");

var envDefined = false;
var usernameCloudant = "init";
var passwordCloudant = "init";
var urlCloudant = "init";
var portCloudant = "init";
var url = "init";
var dbname = "init";

// console.log("** Cloudant url: ", url)
var cloudantClient = Cloudant(
  { username: usernameCloudant, password: passwordCloudant, url: url },
  function(err, cloudant, info) {
    if (envDefined == false){
      return console.log("**  Failed to initialize Cloudant: NO DATABASE");
    }

    if (err) {
      return console.log("**  Failed to initialize Cloudant: " + err.message);
    }
    // console.log("** Cloudant init information ", info);
    // Lists all the databases.
    cloudant.db
      .list()
      .then(body => {
        body.forEach(db => {
          console.log("** Database :", db);
        });
      })
      .catch(err => {
        console.log(err);
      });
  }
);

// *******
// Custom modules
// *******
var Logging = require('./modules/db-logging');
var logging = new Logging(cloudantClient, dbname, envDefined);

// ***************
// Vendingmachine init
// ***************
/* Vendingmachine codes*/

var values = ["1111","2222","3333","4444","5555"];

/* Vendingmachine users*/
var vending_username='user';
var vending_password='user';
var vendingadmin_username='admin';
var vendingadmin_password='admin';

/* files and usage*/
var accesscodes_filename="accesscodes/container-accesscodes.json";
var log_filename="logs/log.txt";
var vend_usage="demo";


// ***************
// Service check
// ***************
var service_origin="Watson Assistant Service";
var service_origin_header="x-watson-origin";
var user_agent="Watson Assistant Service";

// ***************
// Verify environment
// ***************

checkEnv();

// ***************
// REST calls
// ***************

// Return one code
app.post('/getAccessCode', (req, res) => {
    headers=JSON.stringify(req.headers);
    message="invocation: [/getAccessCode] req=[ " + req.headers.host + " ; " + headers + " ]";
    logtofile(message);

    var credentials = auth(req);
   
    var randomvalue = Math.floor(Math.random() * values.length);
    var value = values[randomvalue];
    var returnvalue = {};
    console.log("** randomvalue: " + randomvalue );
    console.log("** value: " + value );
    
    if (!credentials) {
      console.log("** user: " + undefined);
      console.log("** password: " + undefined);
    } else {
      console.log("** user: " + credentials.name);
      console.log("** password: " + credentials.pass);
    }
    
    console.log("** Request  \n ", req.toString());
    console.log("** Headers  \n ", JSON.stringify(req.headers));
    
    if (!credentials || !check(credentials.name, credentials.pass)) {
      res.statusCode = 401;
      res.setHeader('WWW-Authenticate', 'Basic realm="example"');
      returnvalue = { "message": "Access denied" };
      console.log("** 401", returnvalue);
      logging.log(returnvalue,"getAccessCode");
      res.json(returnvalue);
    } else {
      if (!checkServiceSource(req.headers)){
        res.statusCode = 406;
        res.setHeader('WWW-Authenticate', 'Basic realm="example"');
        returnvalue = { "message": "Access denied not a valid source" };
        console.log("** 406", returnvalue);
        logging.log(returnvalue,"getAccessCode");
        res.json(returnvalue);
      } else {
        res.statusCode = 200;
        returnvalue = { "message": value};
        console.log("** 200", returnvalue);
        logging.log(returnvalue,"getAccessCode");
        res.json(returnvalue);
      }
    }  
});

// List codes
app.post('/listAccessCodes', (req, res) => {
  headers=JSON.stringify(req.headers);
  message="invocation: [/listAccessCodes] req=[ " + req.headers.host + " ; " + headers + " ]";
  logtofile(message);

  var credentials = auth(req);
  var returnvalue = {};

  var codes = {
    code: []
  };

  for(var i in values) {    
    var item = values[i];   
    codes.code.push({ 
        "accesscode" : item
    });
  }
  
  /*
  if (!credentials) {
    console.log("** user: " + undefined);
    console.log("** password: " + undefined);
  } else {
    console.log("** user: " + credentials.name);
    console.log("** password: " + credentials.pass);
  }
  */

  if (!credentials || !checkAdmin(credentials.name, credentials.pass)) {
    res.statusCode = 401;
    res.setHeader('WWW-Authenticate', 'Basic realm="example"');
    returnvalue = { "accesscode": "0", "info":"Access denied" };
    console.log("** 401", returnvalue);
    logging.log(returnvalue,"listAccessCodes");
    res.json(returnvalue);
  } else {
    res.
    statusCode = 200;
    returnvalue = codes;
    //console.log("** 200", returnvalue);
    saveAccessCodes(returnvalue);
    logging.log(returnvalue,"listAccessCodes");
    res.json(returnvalue);
  }  
});

// Update codes
app.post('/updateAccessCodes', (req, res) => {
  headers=JSON.stringify(req.headers);
  message="invocation: /updateAccessCodes req=[ " + req.headers.host + " ; " + headers + " ]";
  logtofile(message);

  var credentials = auth(req);
  var returnvalue = {};
 
  /*
  if (!credentials) {
    console.log("** user: " + undefined);
    console.log("** password: " + undefined);
  } else {
    console.log("** user: " + credentials.name);
    console.log("** password: " + credentials.pass);
  }
  */

  if (!credentials || !checkAdmin(credentials.name, credentials.pass)) {
    res.statusCode = 401;
    res.setHeader('WWW-Authenticate', 'Basic realm="example"');
    returnvalue = { "accesscode": "0", "info":"Access denied" };
    console.log("** 401", returnvalue);
    logging.log(returnvalue,"updateAccessCodes");
    res.json(returnvalue);
  } else {
    // 1. request contains content
    if (req != undefined) {
      //console.log("** Request  \n ", req.toString());
      //console.log("** Headers  \n ", JSON.stringify(req.headers));
      const contentType = req.headers["content-type"];
      
      // 2. right format
      if (contentType && contentType.indexOf("application/json") !== -1) {
        //console.log("** Content Type OK");       
        // 3. Body exists
        if (req.body != undefined) {
          // console.log("** Body is defined \n ", JSON.stringify(req.body));          
          // 4. right format
          if (req.body.codes != undefined){
              saveAccessCodes(req.body);
              var input_codes = req.body.codes;
              var input_codes_count = input_codes.length;
              console.log("** Input codes  \n ", JSON.stringify(input_codes));
              // console.log("** Input codes length \n ", input_codes_count);

              var new_codes = new Array(input_codes.length);
              
              // extract new codes
              for (var i=0; i<input_codes_count; i++){
                new_codes[i] = parseInt(input_codes[i].accesscode);
                // console.log("** Input codes length \n ", new_codes[i]);
              }
              
              // assign new codes
              values = new_codes;
              
              res.statusCode = 201;
              returnvalue = { "status":"success", "count":input_codes_count};

              console.log("** 201", returnvalue);
              logging.log(returnvalue,"updateAccessCodes");
              res.json(returnvalue);
          } else {
            res.statusCode = 406;
            returnvalue = { "info":"Not acceptable wrong format (missing codes)" };
            console.log("** 406", returnvalue);
            logging.log(returnvalue,"updateAccessCodes");
            res.json(returnvalue);
          }         
        } else {
          res.statusCode = 406;
          returnvalue = { "info":"Not acceptable wrong format (no body)" };
          console.log("** 406", returnvalue);
          logging.log(returnvalue,"updateAccessCodes");
          res.json(returnvalue);
        }
      } else {
        res.statusCode = 406;
        returnvalue = { "info":"Not acceptable wrong format" };
        console.log("** 406", returnvalue);
        logging.log(returnvalue,"updateAccessCodes");
        res.json(returnvalue);
      }
    } else {
      res.statusCode = 406;
      returnvalue = { "info":"Not acceptable wrong format" };
      console.log("** 406", returnvalue);
      logging.log(returnvalue,"updateAccessCodes");
      res.json(returnvalue);
    }
  }  
});

// Health check
app.get('/health', function(req, res) {
  var returnvalue = {};
  headers=JSON.stringify(req.headers);
  message="invocation: /health req=[ " + req.headers.host + " ; " + headers + " ]";
  logtofile(message);
  
  if(envDefined == false){
    res.body=returnvalue;
    res.statusCode = "200";
    returnvalue = { "message": "health: vend is running in example mode" };
    console.log("** 200", returnvalue);
    // loging.log(returnvalue,"health");
    res.json(JSON.stringify(returnvalue));
  } else {
    res.body=returnvalue;
    res.statusCode = "200";
    returnvalue = { "message": "health: vend is running in production" };
    console.log("** 200", returnvalue);
    // logging.log(returnvalue,"health");
    res.json(JSON.stringify(returnvalue));
  }
});

// Basic return
app.get('/', function(req, res) {
  headers=JSON.stringify(req.headers);
  message="invocation: [ / ] req=[ " + req.headers.host + " ; " + headers + " ]";
  var credentials = auth(req);
  var returnvalue = {};
  
  if (!credentials ) {
    console.log("** user: " + undefined);
    console.log("** password: " + undefined);
  } else {
    console.log("** user: " + credentials.name);
    console.log("** password: " + credentials.pass);
  }

  if (!credentials || !checkAdmin(credentials.name, credentials.pass)) {
    if(envDefined == false){
      res.statusCode = 200;
      res.setHeader('WWW-Authenticate', 'Basic realm="example"');
      returnvalue = { "message": "vend test - " + vend_usage };
      console.log("** 200", returnvalue);

      // ********** MOUNT VOLUME *********
      var codes = {
        code: []
      };
    
      for(var i in values) {    
        var item = values[i];   
        codes.code.push({ 
            "accesscode" : item
        });
      }

      saveAccessCodes(codes);
      res.json(JSON.stringify(returnvalue));

    } else {

      res.statusCode = 401;
      res.setHeader('WWW-Authenticate', 'Basic realm="example"');
      returnvalue = { "message": "vend is running, but Access denied" };
      console.log("** 401", returnvalue);
      logging.log(returnvalue,"baseurl");
      res.json(JSON.stringify(returnvalue));

    }  
  } else {

    res.body=returnvalue;
    res.statusCode = 206;
    returnvalue = { "message": "vend is running and Access granted" };
    console.log("** 206", returnvalue);
    logging.log(returnvalue,"baseurl");
    res.json(JSON.stringify(returnvalue));

  }  
});

// ***************
// Functions
// ***************

function check (name, pass) {
  var valid = true;
 
  var username=vending_username;
  var password=vending_password;
  
  if ((name.localeCompare(username) === 0) || (pass.localeCompare(password) === 0)) {
    valid = true;
  } else {
    valid = false;
  }

  return valid;
}

function checkAdmin (name, pass) {
  var valid = true
 
  var username=vendingadmin_username;
  var password=vendingadmin_password;
  
  if ((name.localeCompare(username) === 0) || (pass.localeCompare(password) === 0)) {
    valid = true;
  } else {
    valid = false;
  }

  return valid;
}

// load the access codes from a local file on the server
function loadAccessCodes(){
  try { 
    if ( envDefined == true ) {
      var content = fs.readFileSync(accesscodes_filename);
      var new_codes = new Array(content.length);
                
      // extract new codes
      for (var i=0; i<input_codes_count; i++){
            new_codes[i] = parseInt(input_codes[i].accesscode);
            console.log("** Input codes length \n ", new_codes[i]);
      }
                
      // assign new codes
      values = new_codes;
      console.log("** File loaded successfully: ", accesscodes_filename);
      console.log("** Content of the file: ", JSON.stringify(content));
      return true;
    } else{
      return false;
    } 
    
  } catch(err) { 
    console.error("** Error load file", err); 
    return false;
  } 
}

// save the uploaded access codes in a local file on the server
function saveAccessCodes(codes){
  try { 

    fs.writeFileSync(accesscodes_filename, JSON.stringify(codes));
    logging.log(codes,"save_access_codes"); 
    console.log("** File written successfully: ", accesscodes_filename);
    return true;

  } catch(err) {

    var error = { "error": "Error save file"}
    logging.log(error,"save_access_codes"); 
    console.error("** Error save file", err); 
    return false;

  } 
}

// verify the existing environment variables
function checkEnv(){
  var message = "";

  if (process.env.VEND_USAGE == undefined) {

    message = "VEND_USAGE : undefined ";
    logtofile(message);

  } else {

    message = "VEND_USAGE : " + process.env.VEND_USAGE;
    vend_usage=process.env.VEND_USAGE;
    logtofile(message);

  }

  // user
  if (process.env.USER == undefined) {

    message = "USER : undefined ";
    logtofile(message);

  } else {

    message = "USER : " + process.env.USER;
    vending_username=process.env.USER;
    logtofile(message);

  }

  if (process.env.USER_PASSWORD == undefined) {

    message = "USER_PASSWORD : undefined ";
    logtofile(message);

  } else {

    message = "USER_PASSWORD : " + process.env.USER_PASSWORD;
    vending_password=process.env.USER_PASSWORD;
    logtofile(message);

  }

  // admin
  if (process.env.ADMINUSER == undefined) {

    message = "ADMINUSER : undefined ";
    logtofile(message);

  } else {

    message = "ADMINUSER : " + process.env.ADMINUSER;
    vendingadmin_username=process.env.ADMINUSER;
    logtofile(message);

  }

  if (process.env.ADMINUSER_PASSWORD == undefined) {

    message = "ADMINUSER_PASSWORD : undefined ";
    //(message);

  } else {

    message = "ADMINUSER_PASSWORD : " + process.env.ADMINUSER_PASSWORD;
    vendingadmin_password=process.env.ADMINUSER_PASSWORD;
    logtofile(message);

  }
  
  // cloudant
  if ((process.env.CLOUDANT_USERNAME == undefined) ||
      (process.env.CLOUDANT_PASSWORD == undefined) ||
      (process.env.CLOUDANT_URL == undefined) ||
      (process.env.CLOUDANT_NAME  == undefined) ||
      (process.env.CLOUDANT_PORT == undefined) ||
      (process.env.CLOUDANT_USERNAME === "") ||
      (process.env.CLOUDANT_PASSWORD === "") ||
      (process.env.CLOUDANT_URL === "") ||
      (process.env.CLOUDANT_NAME  === "") ||
      (process.env.CLOUDANT_PORT === "")){

    envDefined = false;
    console.log("** envDefined: " + envDefined);

  } else {

    usernameCloudant = process.env.CLOUDANT_USERNAME;
    passwordCloudant = process.env.CLOUDANT_PASSWORD
    urlCloudant = process.env.CLOUDANT_URL;
    portCloudant = process.env.CLOUDANT_PORT;
    url = "" + urlCloudant + ":" + portCloudant + "";
    dbname = process.env.CLOUDANT_NAME;
    envDefined = true;
    console.log("** envDefined: " + envDefined); 

  }
}

// use hardcoded values to create a initial access code file
function initAccessCodes(){
  var message = "";
  try {    
    var codes = {
      code: []
    };
  
    for(var i in values) {    
      var item = values[i];   
      codes.code.push({ 
          "accesscode" : item
      });
    } 

    if (envDefined==true) {

      fs.writeFileSync(accesscodes_filename, JSON.stringify(codes));
      console.log("** File written successfully: ", accesscodes_filename);
      logging.log(codes,"init_access_codes"); 
      message = "Info - envDefined==true"    
      logtofile(message);

    } else { 

      message = "Info - envDefined==false"    
      logtofile(message);

    }
    
    return true;
  } catch(err) { 

    console.error("** Error save file", err); 
    var error = { "error": "Error save file"}
    logging.log(error,"init_access_codes"); 
    return false;

  } 
}

// verify http request header
function checkServiceSource(Headers){

  console.log("** headers ",JSON.stringify(Headers));
  
  // Problem inside the JSON with the "-" vs "_"
  var extract =  JSON.stringify(Headers);
  var str = extract.replace("user-agent", "user_agent");
  var headers =  JSON.parse(str);
  //console.log("** headers (str) (1): ",JSON.stringify(headers));

  // 1. Check Header
  if (headers.user_agent != undefined){
      //console.log("** check header level 1 - ok");
      // 2. Check Header
      if (headers.user_agent === user_agent){
        //console.log("** check header level 2 - ok");

        extract =  JSON.stringify(headers);
        str = extract.replace(service_origin_header, service_origin_header);
        headers =  JSON.parse(str);
        //console.log("** headers (str) (2): ",JSON.stringify(headers));

        // 3. Check Header
        var verify = headers[service_origin_header];
        if (verify != undefined) {
          //console.log("** check header level 3 - ok");
          // 4. Check Header content
          if (verify === service_origin){
            //console.log("** check header level 4 - ok"); 
            return true;
          } else {
            //console.log("** check header level 4 - fail");
            return false;
          }
        } else {
          //console.log("** check header level 3 - fail");
          return false;
        }
      } else {
        //console.log("** check header level 2 - fail");
        return false;
      }
  } else {
    //console.log("** check header level 1 - fail");
    return false;
  }
}

// log to a file
function logtofile(message) {
  
  if (disable_file_log == false ) {
    var d = new Date();
    var month = d.getMonth() + 1;
    var today = d.getFullYear() + "-" + month + "-" + d.getDate();
    d.getHours
    var log_entry = "*** INF0: " + today +  " (" + 
                    d.getHours() + ":" + 
                    d.getMinutes () + ":" + 
                    d.getSeconds() + ")" + 
                    " [" + d.getTime() + "] " + message + "\r\n";
    console.log("** Write to logfile ", log_filename );
    fs.writeFile(log_filename, log_entry, { flag: "a+" }, (err) => {
      if (err) throw err;
      console.log("** Logfile updated successfully: ", log_filename);
    });

  } else {
    console.log("-> disable_file_log == true")
  }
 
}

/*****************************/
/* Run server                */
/*****************************/

const server = app.listen(port, function () {
    console.log('vend backend is running on port ', port);
    if (loadAccessCodes()==false){
        initAccessCodes();
    }  
});

module.exports = server;

