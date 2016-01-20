# Create the SSL certificates

You'll need to generate the self-signed SSL certificates so that Node.js can serve the website over HTTPS (click [here](http://superuser.com/questions/596378/always-allow-microphone-usage-in-google-chrome) for why it must be served over SSL). There is a script that will do this for you. Execute the following code from the root directory of the project:

```shell
node makepem.js
```