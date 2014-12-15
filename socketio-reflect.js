var statsFileName = "usageStats"+dateFormat (new Date (), "_%Y%m%d_%H%M%S.json", false);
var connectStats = {};

var http    =   require('http');
var fs      =   require('fs');
var url = require("url");

var connect = require('connect');
var serveStatic  = require('serve-static');

var app = connect()
var server = require('http').createServer(app);
var io = require('socket.io')(server);

app.use(serveStatic(__dirname))

// Enables CORS
var enableCORS = function(req, res, next) {
	if(res.header) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Content-Length, X-Requested-With, *');

        // intercept OPTIONS method
    if ('OPTIONS' == req.method) {
        res.send(200);
    } else {
        next();
    };
  }
};

// enable CORS!
app.use(enableCORS);

// Socket io ecoute maintenant notre application !
var io = require('socket.io');

// Socket io ecoute maintenant notre application !
io = io.listen(server);

io.set('origins', '*:*');
// Quand une personne se connecte au serveur
io.sockets.on('connection', function (socket) {
		console.log(prefixLog(socket)+"Connected" );
 	  var ipStats = getConnectStats(socket);
 	  ipStats.lastSeen = new Date();
  	ipStats.lastConnected = new Date();
  	ipStats.connectCount++;
    // On donne la liste des messages (evenement cree du cote client)
    //socket.emit('recupererMessages', messages);
    // Quand on recoit un nouveau message
			socket.on('client2Server', function (data) {
        // On l'ajout au tableau (variable globale commune a tous les clients connectes au serveur)
        // On envoie a tout les clients connectes (sauf celui qui a appelle l'evenement) le nouveau message
			socket.broadcast.emit('server2Client', data);
			console.log(prefixLog(socket)+'data: ' + data);
			receiveEvent(socket, data);
    });
    socket.on('ping', function (data) {
        // On l'ajout au tableau (variable globale commune a tous les clients connectes au serveur)
        // On envoie a tout les clients connectes (sauf celui qui a appelle l'evenement) le nouveau message
			socket.broadcast.emit('pong', data);
			console.log(prefixLog(socket)+'data: ' + data);
    });
    socket.on('disconnect', function () {
	    console.log(prefixLog(socket)+"Disconnected");
	    var ipStats = getConnectStats(socket);
 	  	ipStats.lastSeen = new Date();
  		ipStats.lastDisconnected = new Date();
  		ipStats.playtime = ipStats.playtime + (ipStats.lastDisconnected-ipStats.lastConnected)/1000;
  		//console.log(ipStats);
  		writeStats();
	  });   
});

// Notre application ecoute sur le port 8080
server.listen(8080);
console.log(dateFormat (new Date (), "%Y-%m-%d %H:%M:%S ", false)+' Server started. Listen on 8080');

function receiveEvent(socket, event) {
  var ipStats = getConnectStats(socket);
 	var lastSeen = ipStats.lastSeen;
 	ipStats.lastSeen = new Date();
 	if(ipStats.lastSeen - lastSeen > 30*1000) { //30s de timeout : on considère déconnecté 10s après
 		ipStats.playtime = ipStats.playtime + 10 + (lastSeen-ipStats.lastConnected)/1000;
  	ipStats.lastConnected = ipStats.lastSeen;
  	ipStats.connectCount++;
 	}
  var eventType = event[0];
  if (eventType == "PLAYER") {
  	ipStats.lastId = event[1];
  	ipStats.lastName = event[2];
  	lastLive = ipStats.lastLive;
  	ipStats.lastLive = event[3];
	ipStats.maxScore = Math.max(ipStats.maxScore, parseInt(event[6]));
  	if(lastLive != ipStats.lastLive && ipStats.lastLive == 'false') {
  		ipStats.deadCount++;
  	}
	if(lastLive != ipStats.lastLive && ipStats.lastLive == 'false') {
  		ipStats.deadCount++;
  	}
  	if(ipStats.knownNames.indexOf(event[2])<0) {
  		ipStats.knownNames.push(event[2]);
  	}
  }
}

function getConnectStats(socket) {
	var connectIp = getIp(socket);
 	var ipStats = connectStats[connectIp];
 	if(!ipStats) {
 	  	ipStats = {
 	  	ip : connectIp,
 	  	connectCount : 0,
 	  	deadCount : 0,
 	  	bombCount : 0,
 	  	lastSeen : new Date(),
 	  	lastId: "",
 	  	lastName: "",
 	  	lastLive: "false",
 	  	knownNames: [],
 	  	playtime : 0,
		maxScore : 0
 	  }
 	}
 	connectStats[connectIp] = ipStats;
 	return ipStats;
}
function getIp(socket) {
	var remoteHeaderIp = socket.handshake.headers['x-forwarded-for'];
	var remoteIp = remoteHeaderIp;
	if(remoteIp || remoteIp == undefined) {
		//remoteIp = socket.request.connection.remoteAddress;
		remoteIp = socket.client.conn.remoteAddress;
		
	}
	//console.log("header:"+remoteHeaderIp+", ip:"+socket.request.connection.remoteAddress+" => "+remoteIp);
	return remoteIp;
}

function getPort(socket) {
	var remoteHeaderPort = socket.handshake.headers['x-forwarded-port'];
	var remotePort = remoteHeaderPort;
	if(remotePort || remotePort == undefined) {
		remotePort = socket.request.connection.remotePort;
	}
	return remotePort;
}

function prefixLog(socket) {
 	var remoteHeaderPort = socket.handshake.headers['x-forwarded-port'];
	var remoteIp = getIp(socket);
	var remotePort = getPort(socket);
	return dateFormat (new Date (), "%Y-%m-%d %H:%M:%S ", false)+ "["+remoteIp + ":" +remotePort+"] "
}

function dateFormat (date, fstr, utc) {
  utc = utc ? 'getUTC' : 'get';
  return fstr.replace (/%[YmdHMS]/g, function (m) {
    switch (m) {
    case '%Y': return date[utc + 'FullYear'] (); // no leading zeros required
    case '%m': m = 1 + date[utc + 'Month'] (); break;
    case '%d': m = date[utc + 'Date'] (); break;
    case '%H': m = date[utc + 'Hours'] (); break;
    case '%M': m = date[utc + 'Minutes'] (); break;
    case '%S': m = date[utc + 'Seconds'] (); break;
    default: return m.slice (1); // unknown code, remove %
    }
    // add leading zero if required
    return ('0' + m).slice (-2);
  });
}

function writeStats() {
	var fs = require('fs');
	fs.writeFile(statsFileName,JSON.stringify(connectStats, null, '\t'), function(err) {
	    if(err) {
	        console.log(err);
	    } else {
	        console.log("The file was saved!");
	    }
	}); 
}