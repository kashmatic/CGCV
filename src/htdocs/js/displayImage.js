/*
 * #########################################################
 * ## Copyright 2008 The Trustees of Indiana University
 * ##
 * ## Licensed under the Apache License, Version 2.0 (the "License");
 * ## you may not use this file except in compliance with the License.
 * ## You may obtain a copy of the License at
 * ##
 * ##      http://www.apache.org/licenses/LICENSE-2.0
 * ##
 * ## Unless required by applicable law or agreed to in writing, software
 * ## distributed under the License is distributed on an "AS IS" BASIS,
 * ## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * ## See the License for the specific language governing permissions and
 * ## limitations under the License.
 * #########################################################
 *
 *
 * #################################################################################
 * ##
 * ## Author  => Kashi V Revanna
 * ## Company => The Center for Genomics and Bioinformatics
 * ## Contact => biohelp@cgb.indiana.edu
 * ## Written => 14th Nov 2008
 * ##
 * ##################################################################################
 */

//=========
// for empty space in the start and end place
function emptySpace(id){
	document.getElementById(id).value="";
}

function showZoom(id, zstart, zend, length, evalue){
	var s = "start"+id;
	var e = "end"+id;
	var start = document.getElementById(s);
	start.value = zstart-5000;
	var end = document.getElementById(e);
	end.value = zend+5000;
	
	getValue('show', length, evalue, id);
}
//=========
//for different pages
function getSelected (id, select, noRows){
	var url="test.cgi?"
	url += "rowstart="+select;
	url += "&noRows="+noRows;

	document.getElementById("rowstart").value = select;
	document.getElementById("noofrows").value = noRows;
	document.displayForm.submit();
}

//========
// TO display information in the div
function writeText(divName, txt){
	document.getElementById(divName).innerHTML = txt;
}
//=========
// To get the order
var activeRow = 0;
function setActiveRow(el) {
	var rows = document.getElementById("movingTable").rows;
	for(var i = 0; i < rows.length; i++) {
		if(rows[i] == el) activeRow = i;
	}
}
function moveActiveRow(move) {
	var rows = document.getElementById("movingTable").rows;
	var oldRow1 = rows[activeRow].innerHTML; // desc
	var oldRow2 = rows[activeRow+1].innerHTML; //controls
	var oldRow3 = rows[activeRow+2].innerHTML; // image
	oldRow3 = oldRow3.replace(/%0A%09%09%09&amp;/ig,"&");

	var newRow1 = rows[activeRow+move].innerHTML; // desc

	var newRow2 = rows[activeRow+move+1].innerHTML; //controls
	var newRow3 = rows[activeRow+move+2].innerHTML; // image
	newRow3 = newRow3.replace(/%0A%09%09%09&amp;/ig,"&");


	rows[activeRow].innerHTML = newRow1;
	rows[activeRow+1].innerHTML = newRow2;
	rows[activeRow+2].innerHTML = newRow3;
	
	rows[activeRow+move+2].innerHTML = oldRow3;
	rows[activeRow+move+1].innerHTML = oldRow2;
	rows[activeRow+move].innerHTML = oldRow1;

	setActiveRow(rows[activeRow+move]);
}

function moveRow(cell, move) {
	setActiveRow(cell.parentNode);
	moveActiveRow(move);
}

function doSubmit() {
	var rows = document.getElementById("movingTable").rows;
	var ret = new Array();
	for(var i = 0; i < rows.length;i++) {
		ret[ret.length] = rows[i].getElementsByTagName("td")[0].innerHTML;
	}
	return ret.join("|..");
}

//====================================

// For getting the imagemap information
var ELEMENT = "imageMap";
function getCoords(genome,dir){
	ELEMENT = "imageMap"+genome;
	xmlHttp=GetXmlHttpObject();
	if (xmlHttp==null) {
		alert ("Your browser does not support AJAX!");
		return;
	} 
	var url="updateMap.cgi?";
	url += "input="+ELEMENT;
	url += "&dir="+dir;
	xmlHttp.onreadystatechange=stateChanged;
	xmlHttp.open("GET",url,true);
	xmlHttp.send(null);
}

function sleep(ms){
	var start = new Date().getTime();
	while (new Date().getTime() < start + ms);
}

function GetXmlHttpObject() {
	var xmlHttp=null;
	try {
		// Firefox, Opera 8.0+, Safari
		xmlHttp=new XMLHttpRequest();
	}
	catch (e) {
		// Internet Explorer
		try {
			xmlHttp=new ActiveXObject("Msxml2.XMLHTTP");
		}
		catch (e) {
			xmlHttp=new ActiveXObject("Microsoft.XMLHTTP");
		}
	}
	return xmlHttp;
}

function stateChanged() {
	if (xmlHttp.readyState==4) {
		document.getElementById(ELEMENT).innerHTML=xmlHttp.responseText;
		ELEMENT = "imageMap";
	}
}

