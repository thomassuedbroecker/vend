module.exports = function (cloudantClient, dbname, envDefined){
  
     var envdefined = envDefined;
     if (envdefined == true) {
      var db = cloudantClient.db.use(dbname);
      //console.log("** module: db-logging started" );
     }
     
     
     this.log = function (logjson,info) {

       if (envdefined == false){
          // console.log("** module: db.insert error: NO DATABASE");
          return (false);
       }

       var d = new Date();
       var month = d.getMonth() + 1;
       var today = d.getFullYear() + "-" + month + "-" + d.getDate();
       var message = { "type":"vendlog",
                       "time": d.getTime(),
                       "date": today,
                       "log": logjson,
                       "info": info};
       var d = new Date();
       
       //console.log("** module: log", d );
       db.insert(message, function(err, body, header) {
        if (err) {
          console.log("** module: db.insert error: ", err.message);
          return (false);
        } else {
          //console.log("** module:  new entry: ", body);
          return (true);
        }
       });
     };    
}