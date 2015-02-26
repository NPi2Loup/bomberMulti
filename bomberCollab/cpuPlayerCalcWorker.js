  importScripts('cpuPlayerCalc.js');
  
  onmessage = function(e) {
  //console.log('Message received from main script: '+e.data[2]);
	var bestMove = innerComputeBestMove(e.data[0],e.data[1]);
	//console.log('Posting message back to main script: '+e.data[2]);
	postMessage([bestMove,e.data[2]]);	
  }