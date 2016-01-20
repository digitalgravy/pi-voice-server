var https = require('https'),
    pem = require('pem'),
    fs = require('fs'),
    path = require('path');

pem.createCertificate({days:3600, selfSigned:true}, function(err, keys){
  for(key in keys){
    console.log(keys[key])
    fs.writeFile(path.resolve(__dirname, 'ssl/', key), keys[key], function(err){
      if(err) console.log('Error!', err);
    })
  }
});