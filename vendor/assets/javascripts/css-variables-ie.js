'use strict';
var linkEle = document.querySelectorAll('link');
var changeCSSVFiles = [];
for(var li=0;li < linkEle.length;li++) {
	changeCSSVFiles.push(linkEle.item(li).getAttribute('href'));
}
var ua = window.navigator.userAgent.toLowerCase();
if( ua.match(/(msie|MSIE)/) || ua.match(/(T|t)rident/) ) {
	for (var si=0;si < changeCSSVFiles.length;si++) {
		changeCSSVariables(changeCSSVFiles[si]);
	}
}
function changeCSSVariables(cssfile){
	if ( cssfile.match(/(\/|\.\/)/g) ) {
	} else {
		cssfile = './'+cssfile;
	}
	var xhr = new XMLHttpRequest();
	try{
		xhr.open( "GET", cssfile);
	}catch(e){
		console.log('XMLHttpRequest Open Error : '+e);
	}
	xhr.addEventListener('load',function(){
		if(xhr.status === 200){
			var getStyleSheet=xhr.responseText;
			var allMatchCssVariables = getStyleSheet.match(/--[a-zA-Z0-9-].*?;/g);
			var iniMatchCssVariables = [];
			if ( allMatchCssVariables ) {
				for (var i=0;i < allMatchCssVariables.length;i++) {
					if ( allMatchCssVariables[i].match(/:/g) ) {
						iniMatchCssVariables.push(allMatchCssVariables[i].replace(/\s+/g, ""));
					}
				}
			}
			if ( iniMatchCssVariables ) {
				for (var j=0;j < iniMatchCssVariables.length;j++) {
					var arrVarName = iniMatchCssVariables[j].split(':');
					for (var k=0;k < iniMatchCssVariables.length;k++) {
						var regexp = new RegExp('var\\(\\s*'+arrVarName[0]+'\\s*\\)', 'g');
						if ( iniMatchCssVariables[k].match(regexp) ) {
							iniMatchCssVariables[k] = iniMatchCssVariables[k].replace(/var\(\s*(.*?)\s*\)/g, arrVarName[1]);
						}
					}
				}
				for (var l=0;l < iniMatchCssVariables.length;l++) {
					var arrSearchVar = iniMatchCssVariables[l].split(':');
					arrSearchVar[1] = arrSearchVar[1].replace(/;/g,'');
					
					var regexp2 = new RegExp('var\\(\\s*'+arrSearchVar[0]+'\\s*\\)', 'g');
					getStyleSheet = getStyleSheet.replace(regexp2,arrSearchVar[1]);
					
					var regexp3 = new RegExp('var\\(\\s*'+arrSearchVar[0]+'\\s*,\\s*(.*)\\)','g');
					getStyleSheet = getStyleSheet.replace(regexp3,'$1');
				}
			}
			var endFlg = false;
			var regexp4 = new RegExp('var\\(\\s*.*?\\s*,\\s*(.*)\\s*\\)','g');
			while ( !endFlg ) {
				if ( getStyleSheet.match(regexp4) ) {
					getStyleSheet = getStyleSheet.replace(regexp4,'$1');
				} else {
					endFlg = true;
				}
			}
			var style = document.createElement('style');
			style.type = 'text/css';
			style.innerHTML = getStyleSheet;
			document.getElementsByTagName('head')[0].appendChild(style);
		}
	},false);
	try {
		xhr.send();
	}catch(e) {
		console.log('XMLHttpRequest Send Error : '+e);
	}
}