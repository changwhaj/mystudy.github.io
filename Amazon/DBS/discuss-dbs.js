const PASSKEY = "tuning";

// Usage
// zeroPad(1,10);   //=> 01
// zeroPad(1,100);   //=> 001
function zeroPad(nr,base){
    var  len = (String(base).length - String(nr).length)+1;
    return len > 0? new Array(len).join('0')+nr : nr;
}

document.addEventListener('keydown', function (e) {
    if(event.which=="17")
        cntrlIsPressed = true;
});

document.addEventListener('keyup', function (e) {
    cntrlIsPressed = false;
});

var cntrlIsPressed = false;
//document.addEventListener("keydown", keyDownTextField, false);

// 주어진 이름의 쿠키를 반환하는데,
// 조건에 맞는 쿠키가 없다면 undefined를 반환합니다.
function getCookie(name) {
    let matches = document.cookie.match(new RegExp(
    "(?:^|; )" + name.replace(/([\.$?*|{}\(\)\[\]\\\/\+^])/g, '\\$1') + "=([^;]*)"
    ));
    return matches ? decodeURIComponent(matches[1]) : undefined;
}

function setCookie(name, value, options = {}) {

    options = {
        path: '/',
        // 필요한 경우, 옵션 기본값을 설정할 수도 있습니다.
        ...options
    };
    
    if (options.expires instanceof Date) {
        options.expires = options.expires.toUTCString();
    }
    
    let updatedCookie = encodeURIComponent(name) + "=" + encodeURIComponent(value);
    
    for (let optionKey in options) {
        updatedCookie += "; " + optionKey;
        let optionValue = options[optionKey];
        if (optionValue !== true) {
        updatedCookie += "=" + optionValue;
        }
    }
    
    document.cookie = updatedCookie;
}

function deleteCookie(name) {
    setCookie(name, "", {
    'max-age': -1
    })
}

function changeTable() {
    if (document.getElementById("seq").innerHTML == "X") {
        buildTable(seq, myArray)
    } else {
        buildTable("X", myArray)
    }
}

function buildTable(id, data) {
    var nrows = 20;
    var ncols = 10;
    var table = document.getElementById('table1')
    var btnText = "오답노트"
    var txtColor = "green"

    if (id == "X") { 
        btnText = "문제풀이"
        txtColor = "red"
    }
    var row = "<tr><th align=left colspan="+ncols+"><input type='button' id='btn' onclick='changeTable();' value='" + btnText + "'/>&nbsp;차수: <label id='seq'>" + id + 
                "</label>&nbsp </th></tr>"
    
    // alert(document.cookie); // 모든 쿠키 보여주기
    var vlist = getCookie("DBS"+id);
    var varray = [];
    
    if (vlist != undefined) {
        varray = vlist.split(',');
    }

    for (var i=0; i < (data.length/ncols)+1; i++) { 
        row += "<tr>"
        for (var c=0; c < ncols; c++) {
            var idx = i+nrows*c
            if (idx < data.length) {
                var fstyle = "text-decoration: underline; "
                if (varray.indexOf(data[idx].QID) >= 0) {
                    // console.log(data[idx].QID + ":" + varray.indexOf(data[idx].QID))
                    fstyle += "color:" + txtColor + "; font-weight:bold; "
                }
                if (data[idx].DID == "") {
                    row += "<td onClick='NewTab(\""+data[idx].QID+"\", \""+data[idx].DID+"\");'><font style='color:cyan; font-style:italic; text-decoration: underline;'>#"+data[idx].QID+"</font></td>"
                } else {
                    row += "<td onClick='NewTab(\""+data[idx].QID+"\", \""+data[idx].DID+"\");'><font style='" + fstyle + "' target='_self'>#"+data[idx].QID+"</font></td>"
                }
            }
        }
        row += "</tr>" 
    }
    table.innerHTML = row 
} 

function setSequence(seq, vlist) {
    var expDate = new Date();
    expDate.setMonth(expDate.getMonth() + 1);
    expDate = expDate.toUTCString();
    setCookie("DBS"+seq, vlist, {secure: true, 'expires': expDate});
}

function setVlist(question_id, vlist, toggle) {
    var varray = [];
    
    if (vlist != undefined) {
        varray = vlist.split(',');
    } else {
        return question_id
    }
    
    var idx = varray.indexOf(question_id);
    if (idx < 0) {
        return vlist + "," + question_id 
    } else if (toggle == true) {
        varray.splice(idx, 1)
        // console.log("varray: " + varray + ", vlist: " + vlist)
        return varray.join(",");
    } else {
        return vlist
    }
}

function NewTab(question_id, discuss_id) {
    var seq = document.getElementById("seq").innerHTML
    var vlist = getCookie("DBS"+seq);
    var varray = []
            
    if (vlist != undefined) {
        varray = vlist.split(',');
    }
    // console.log("Clicked QID: " + question_id + ", DID: " + discuss_id)
    
    if (cntrlIsPressed || seq == "X") {
        let newList = setVlist(question_id, vlist, true);
        setSequence(seq, newList)
    } else {
        let newList = setVlist(question_id, vlist, false);
        if (vlist != newList) {
            setSequence(seq, newList)
        }

        var url = "https://aws.amazon.com/"
        if (passwd == PASSKEY) {
        // if (discuss_id == "") {
            url = "https://changwhaj.github.io/assets/exam/aws/DBS/page/DBS-P" 
                + String(parseInt(question_id/10+0.9)) +
                ".html";
            url = "https://changwhaj.github.io/assets/exam/aws/DBS/DBS-Q" + question_id + ".html"
        } else {
            url = "https://www.examtopics.com/discussions/amazon/view/"
                + discuss_id +
                "-exam-aws-certified-database-specialty-topic-1-question-" + String(parseInt(question_id)) + "/";
            // console.log("Clicked QID: " + question_id + ", GID: " + String(parseInt(question_id/10+0.9)))
            //url = "https://www.examtopics.com/exams/amazon/aws-certified-database-specialty/view/" 
            //    + String(parseInt(question_id/4+0.9)) +
                "/";
        }
        
        var winDiscuss = window.open(url, "discuss");
        var teste = function(){
            //console.log("Find Element for google-cache-hdr");
            window.parent.postMessage({ childData : 'test data' }, '*');
            var div = winDiscuss.document.getElementById("bN015htcoyT__google-cache-hdr");
            if(typeof(div)!="undefined"){
                winDiscuss.alert("Found!");
                div.innerHTML = '';
                clearInterval(id);
            }
        }
        // var id = setInterval(teste, 5000);               
    }
    
    buildTable(seq, myArray);
}

var passwd = getCookie('passdbs');

if (passwd == undefined) {
    let passwd = prompt("Please enter password for use this page");

    if (passwd.toLowerCase() == PASSKEY) {
        var expDate = new Date();
        expDate.setMonth(expDate.getMonth() + 1);
        expDate = expDate.toUTCString();
        setCookie('passdbs', passwd, {secure: true, 'expires': expDate});
    }
}
passwd = getCookie('passdbs');
