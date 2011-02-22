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

// For adding and removing objects from the select
function unselect() {
	var objSourceElement = document.getElementById('Form').selected;
	var objTargetElement = document.getElementById('Form').available;
	for (var i = 0; i < objSourceElement.length; i ++){
		objSourceElement.options[i].selected = true;
	}
	MoveOption(objSourceElement, objTargetElement);
}

var error = "false";
function MoveOption(objSourceElement, objTargetElement) {
        var aryTempSourceOptions = new Array();
        var x = 0;

        //looping through source element to find selected options
        for (var i = 0; i < objSourceElement.length; i++) {
                if (objSourceElement.options[i].selected) {
                        //need to move this option to target element
                        var intTargetLen = objTargetElement.length++;
                        objTargetElement.options[intTargetLen].text = objSourceElement.options[i].text;
                        objTargetElement.options[intTargetLen].value = objSourceElement.options[i].value;
                } else {
                        //storing options that stay to recreate select element
                        var objTempValues = new Object();
                        objTempValues.text = objSourceElement.options[i].text;
                        objTempValues.value = objSourceElement.options[i].value;
                        aryTempSourceOptions[x] = objTempValues;
                        x++;
                }
        }

        //resetting length of source
        objSourceElement.length = aryTempSourceOptions.length;
        //looping through temp array to recreate source select element
        for (var i = 0; i < aryTempSourceOptions.length; i++) {
                objSourceElement.options[i].text = aryTempSourceOptions[i].text;
                objSourceElement.options[i].value = aryTempSourceOptions[i].value;
                objSourceElement.options[i].selected = false;
        }
        getTotal();
}

// To get the number of elements in the select
function getTotal(){
        document.getElementById("selectedGenomes").innerHTML=document.getElementById("selected").length;
        document.getElementById("availableGenomes").innerHTML=document.getElementById("available").length;

	if(document.getElementById("available").length > 0){
		document.getElementById("getAll").checked = false;
	}
}

// To visually move all the elements when select all is selected
function MoveAll(objSourceElement, objTargetElement){
	//alert("will move all");
	for (var i = 0; i < objSourceElement.length; i ++){
		objSourceElement.options[i].selected = true;
	}
	MoveOption(objSourceElement,  objTargetElement);
}

// On load deselect the select all button
function DeSelect(){
	document.getElementById("getAll").checked = false;	
}

// When form is submitted, it gets the selected elements 
function getSelected(){
        var s = document.getElementById("selected");
        //alert (s);
        for (var i = 0; i < s.length; i++) {
                s.options[i].selected = true;
        }
}


function validateForm(){
        // check if there is selected genomes
        if( (document.getElementById("selected").length < 1) && (document.getElementById("getAll").checked == false)){
                document.getElementById("errorMsg").innerHTML = ".. Error: Please select Genome(s).";
                return false;
        }
        //--------------------------------------------------------

        // check for the e-value
        var regExp = /^[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?$/;
        var evalue = document.getElementById("evalue").value;
        var result = evalue.match(regExp);
        if (result == null){
                document.getElementById("errorMsg").innerHTML = ".. Error: Unrecognised E-value provided.";
                return false;
        }
        //-------------------------------------------------------

        // program type
        var program = document.getElementById("program").selectedIndex;
        var progValue = document.getElementById("program").options[program].value;

        // database type 
        var database = document.getElementById("database").selectedIndex;
        var dataValue = document.getElementById("database").options[database].value;

        if ( ((progValue == "blastn") || (progValue == "blastx") || (progValue == "tblastx")) && (dataValue == "aaseqs")){
                document.getElementById("errorMsg").innerHTML = ".. Error: Wrong BLAST program chosen.";
                return false;
        }
        if ( ((progValue == "blastp") || (progValue == "tblastn")) && (dataValue != "aaseqs")){
                document.getElementById("errorMsg").innerHTML = ".. Error: Wrong BLAST program chosen.";
                return false;
        }
                
        var file = document.getElementById("uploadFile").value;
        var sequence = document.getElementById("sequence").value;
        //alert(file);
        //alert(sequence);
        
        if ((file == "") && (sequence == "") ){
                document.getElementById("errorMsg").innerHTML = ".. Error: No sequence(s) or sequence(s) file provided."
                return false;
        }
        //-----------------------------------------------------------

        // email validation
        var filter = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
        var email = document.getElementById("email").value;
        //alert("email - <"+email+">");

        if (!filter.test(email) && (email != "")){
                document.getElementById("errorMsg").innerHTML = ".. Error: Please provide a valid e-mail address";
                return false;
        }

        if (error == "true"){
                return false;
        }
        getSelected();
        return true;
}


var check = "check";
function checkZero(){
        var number = /^[0-9]+$/;
        //var val = document.getElementById(id).value;
        
        //alert(error);
        error = "false";

        for(var i = 0; i < 9; i++){
                var checkNow = check+i;
                //alert (checkNow);
                validateCheck(checkNow);
        }
}

function validateCheck(id){
        //alert(id);
        var number = /^[0-9]+$/;
        var val= document.getElementById(id).value;
        if ((val < 0) || (!number.test(val))){
                document.getElementById("errorMsg").innerHTML = ".. Error: Value is either less than 0 or non-numeric";
                error = "true";
                //alert(error);
        }
}
