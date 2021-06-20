
    var myArray = [ 
        {'QID':'001','DID':'21738'}, {'QID':'002','DID':'21739'}, {'QID':'003','DID':'21740'}, {'QID':'004','DID':'21741'}, {'QID':'005','DID':'27683'}, {'QID':'006','DID':'46385'}, {'QID':'007','DID':'21808'}, {'QID':'008','DID':'21997'}, {'QID':'009','DID':'27701'}, {'QID':'010','DID':'21754'}, {'QID':'011','DID':'21757'}, {'QID':'012','DID':'21845'}, {'QID':'013','DID':'21769'}, {'QID':'014','DID':'21963'}, {'QID':'015','DID':'22024'}, {'QID':'016','DID':'21860'}, {'QID':'017','DID':'21774'}, {'QID':'018','DID':'22025'}, {'QID':'019','DID':'27677'}, {'QID':'020','DID':'21775'}, {'QID':'021','DID':'21954'}, {'QID':'022','DID':'22040'}, {'QID':'023','DID':'22175'}, {'QID':'024','DID':'21959'}, {'QID':'025','DID':'21790'}, {'QID':'026','DID':'21791'}, {'QID':'027','DID':'22044'}, {'QID':'028','DID':'27713'}, {'QID':'029','DID':'27714'}, {'QID':'030','DID':'21793'}, {'QID':'031','DID':'21965'}, {'QID':'032','DID':'27686'}, {'QID':'033','DID':'27688'}, {'QID':'034','DID':'21795'}, {'QID':'035','DID':'22041'}, {'QID':'036','DID':'21851'}, {'QID':'037','DID':'21797'}, {'QID':'038','DID':'21966'}, {'QID':'039','DID':'21798'}, {'QID':'040','DID':'21820'},
        {'QID':'041','DID':'21822'}, {'QID':'042','DID':'21863'}, {'QID':'043','DID':'22048'}, {'QID':'044','DID':'21824'}, {'QID':'045','DID':'22049'}, {'QID':'046','DID':'22050'}, {'QID':'047','DID':'21819'}, {'QID':'048','DID':'27771'}, {'QID':'049','DID':'21829'}, {'QID':'050','DID':'21967'}, {'QID':'051','DID':'27820'}, {'QID':'052','DID':'21968'}, {'QID':'053','DID':'21831'}, {'QID':'054','DID':'21832'}, {'QID':'055','DID':'53849'}, {'QID':'056','DID':'21834'}, {'QID':'057','DID':'21969'}, {'QID':'058','DID':'22138'}, {'QID':'059','DID':'35616'}, {'QID':'060','DID':'22177'}, {'QID':'061','DID':'21839'}, {'QID':'062','DID':'22182'}, {'QID':'063','DID':'21993'}, {'QID':'064','DID':'22180'}, {'QID':'065','DID':'22139'}, {'QID':'066','DID':'24813'}, {'QID':'067','DID':'24878'}, {'QID':'068','DID':'24823'}, {'QID':'069','DID':'24824'}, {'QID':'070','DID':'27814'}, {'QID':'071','DID':'24851'}, {'QID':'072','DID':'24840'}, {'QID':'073','DID':'27678'}, {'QID':'074','DID':'27679'}, {'QID':'075','DID':'24825'}, {'QID':'076','DID':'24952'}, {'QID':'077','DID':'24834'}, {'QID':'078','DID':'24848'}, {'QID':'079','DID':'24836'}, {'QID':'080','DID':'27770'},
        {'QID':'081','DID':'27943'}, {'QID':'082','DID':'27700'}, {'QID':'083','DID':'27795'}, {'QID':'084','DID':'27788'}, {'QID':'085','DID':'27796'}, {'QID':'086','DID':'27772'}, {'QID':'087','DID':'27844'}, {'QID':'088','DID':'27846'}, {'QID':'089','DID':'27830'}, {'QID':'090','DID':'27848'}, {'QID':'091','DID':'27865'}, {'QID':'092','DID':'27798'}, {'QID':'093','DID':'28068'}, {'QID':'094','DID':'27801'}, {'QID':'095','DID':'27833'}, {'QID':'096','DID':'27868'}, {'QID':'097','DID':'27869'}, {'QID':'098','DID':'27871'}, {'QID':'099','DID':'27872'}, {'QID':'100','DID':'27873'}, {'QID':'101','DID':'27923'}, {'QID':'102','DID':'27924'}, {'QID':'103','DID':'27926'}, {'QID':'104','DID':'27874'}, {'QID':'105','DID':'27991'}, {'QID':'106','DID':'27847'}, {'QID':'107','DID':'27787'}, {'QID':'108','DID':'27850'}, {'QID':'109','DID':'27740'}, {'QID':'110','DID':'27897'}, {'QID':'111','DID':'27852'}, {'QID':'112','DID':'27854'}, {'QID':'113','DID':'27763'}, {'QID':'114','DID':'27851'}, {'QID':'115','DID':'27842'}, {'QID':'116','DID':'27843'}, {'QID':'117','DID':'46550'}, {'QID':'118','DID':'27881'}, {'QID':'119','DID':'27882'}, {'QID':'120','DID':'27901'},
        {'QID':'121','DID':'28003'}, {'QID':'122','DID':'27863'}, {'QID':'123','DID':'27887'}, {'QID':'124','DID':'27985'}, {'QID':'125','DID':'28006'}, {'QID':'126','DID':'27866'}, {'QID':'127','DID':'27855'}, {'QID':'128','DID':'27928'}, {'QID':'129','DID':'27903'}, {'QID':'130','DID':'28008'}, {'QID':'131','DID':'27929'}, {'QID':'132','DID':'27904'}, {'QID':'133','DID':'27889'}, {'QID':'134','DID':'27930'}, {'QID':'135','DID':'27890'}, {'QID':'136','DID':'28010'}, {'QID':'137','DID':'27931'}, {'QID':'138','DID':'27856'}, {'QID':'139','DID':'27932'}, {'QID':'140','DID':'27857'}, {'QID':'141','DID':'27891'}, {'QID':'142','DID':'28013'}, {'QID':'143','DID':'27825'}, {'QID':'144','DID':'28015'}, {'QID':'145','DID':'27893'}, {'QID':'146','DID':'27894'}, {'QID':'147','DID':'27875'}, {'QID':'148','DID':'28023'}, {'QID':'149','DID':'27877'}, {'QID':'150','DID':'28052'}, {'QID':'151','DID':'27878'}, {'QID':'152','DID':'27933'}, {'QID':'153','DID':'28053'}, {'QID':'154','DID':'27934'}, {'QID':'155','DID':'27935'}, {'QID':'156','DID':'27880'}, {'QID':'157','DID':'28070'}, {'QID':'158','DID':'27954'}, {'QID':'159','DID':'27884'}, {'QID':'160','DID':'27867'},
        {'QID':'161','DID':'27885'}, {'QID':'162','DID':'28077'}, {'QID':'163','DID':'27937'}, {'QID':'164','DID':'27888'}, {'QID':'165','DID':'46651'}, {'QID':'166','DID':'27782'}, {'QID':'167','DID':'43797'}, {'QID':'168','DID':'27828'}, {'QID':'169','DID':'27829'}, {'QID':'170','DID':'27941'}, {'QID':'171','DID':'27779'}, {'QID':'172','DID':'46652'}, {'QID':'173','DID':'28086'}, {'QID':'174','DID':'27832'}, {'QID':'175','DID':'30057'}, {'QID':'176','DID':'27777'}, {'QID':'177','DID':'28087'}, {'QID':'178','DID':'27776'}, {'QID':'179','DID':'27898'}, {'QID':'180','DID':'27774'}, {'QID':'181','DID':'27775'}, {'QID':'182','DID':'27773'}, {'QID':'183','DID':'29744'}, {'QID':'184','DID':'29745'}, {'QID':'185','DID':'29746'}, {'QID':'186','DID':'29748'}, {'QID':'187','DID':'29749'}, {'QID':'188','DID':'29751'}, {'QID':'189','DID':'29752'}, {'QID':'190','DID':'29756'}, {'QID':'191','DID':'29757'}, {'QID':'192','DID':'29758'}, {'QID':'193','DID':'29729'}, {'QID':'194','DID':'29761'}, {'QID':'195','DID':'29762'}, {'QID':'196','DID':'29764'}, {'QID':'197','DID':'29765'}, {'QID':'198','DID':'29767'}, {'QID':'199','DID':'29768'}, {'QID':'200','DID':'29769'},
        {'QID':'201','DID':'29771'}, {'QID':'202','DID':'29772'}, {'QID':'203','DID':'29773'}, {'QID':'204','DID':'29774'}, {'QID':'205','DID':'29775'}, {'QID':'206','DID':'29776'}, {'QID':'207','DID':'29778'}, {'QID':'208','DID':'29780'}, {'QID':'209','DID':'29740'}, {'QID':'210','DID':'29741'}, {'QID':'211','DID':'30055'}, {'QID':'212','DID':'29782'}, {'QID':'213','DID':'30065'}, {'QID':'214','DID':'29738'}, {'QID':'215','DID':'30056'}, {'QID':'216','DID':'35643'}, {'QID':'217','DID':'35665'}, {'QID':'218','DID':'35619'}, {'QID':'219','DID':'35639'}, {'QID':'220','DID':'35677'}, {'QID':'221','DID':'35669'}, {'QID':'222','DID':'35678'}, {'QID':'223','DID':'35679'}, {'QID':'224','DID':'35680'}, {'QID':'225','DID':'35681'}, {'QID':'226','DID':'35682'}, {'QID':'227','DID':'35683'}, {'QID':'228','DID':'35684'}, {'QID':'229','DID':'35791'}, {'QID':'230','DID':'35801'}, {'QID':'231','DID':'35685'}, {'QID':'232','DID':'35865'}, {'QID':'233','DID':'35803'}, {'QID':'234','DID':'35816'}, {'QID':'235','DID':'35861'}, {'QID':'236','DID':'35807'}, {'QID':'237','DID':'35884'}, {'QID':'238','DID':'35862'}, {'QID':'239','DID':'35832'}, {'QID':'240','DID':'35833'},
        {'QID':'241','DID':'35834'}, {'QID':'242','DID':'35836'}, {'QID':'243','DID':'35837'}, {'QID':'244','DID':'35838'}, {'QID':'245','DID':'35809'}, {'QID':'246','DID':'35687'}, {'QID':'247','DID':'35811'}, {'QID':'248','DID':'46369'}, {'QID':'249','DID':'35845'}, {'QID':'250','DID':'35688'}, {'QID':'251','DID':'35847'}, {'QID':'252','DID':'35848'}, {'QID':'253','DID':'35849'}, {'QID':'254','DID':'35850'}, {'QID':'255','DID':'35813'}, {'QID':'256','DID':'35851'}, {'QID':'257','DID':'35852'}, {'QID':'258','DID':'35853'}, {'QID':'259','DID':'35817'}, {'QID':'260','DID':'35818'}, {'QID':'261','DID':'35854'}, {'QID':'262','DID':'35820'}, {'QID':'263','DID':'35855'}, {'QID':'264','DID':'46383'}, {'QID':'265','DID':'35856'}, {'QID':'266','DID':'35844'}, {'QID':'267','DID':'35857'}, {'QID':'268','DID':'35858'}, {'QID':'269','DID':'35772'}, {'QID':'270','DID':'35859'}, {'QID':'271','DID':'35860'}, {'QID':'272','DID':'35706'}, {'QID':'273','DID':'43713'}, {'QID':'274','DID':'43723'}, {'QID':'275','DID':'43725'}, {'QID':'276','DID':'43727'}, {'QID':'277','DID':'43729'}, {'QID':'278','DID':'43730'}, {'QID':'279','DID':'43777'}, {'QID':'280','DID':'43786'},
        {'QID':'281','DID':'43705'}, {'QID':'282','DID':'43784'}, {'QID':'283','DID':'43783'}, {'QID':'284','DID':'43782'}, {'QID':'285','DID':'43781'}, {'QID':'286','DID':'43780'}, {'QID':'287','DID':'43704'}, {'QID':'288','DID':'43779'}, {'QID':'289','DID':'43778'}, {'QID':'290','DID':'43900'}, {'QID':'291','DID':'43796'}, {'QID':'292','DID':'43795'}, {'QID':'293','DID':'43792'}, {'QID':'294','DID':'43791'}, {'QID':'295','DID':'43702'}, {'QID':'296','DID':'43790'}, {'QID':'297','DID':'43746'}, {'QID':'298','DID':'43789'}, {'QID':'299','DID':'43788'}, {'QID':'300','DID':'43798'}, {'QID':'301','DID':'43799'}, {'QID':'302','DID':'43813'}, {'QID':'303','DID':'43816'}, {'QID':'304','DID':'43800'}, {'QID':'305','DID':'46699'}, {'QID':'306','DID':'46839'}, {'QID':'307','DID':'46704'}, {'QID':'308','DID':'46402'}, {'QID':'309','DID':'46404'}, {'QID':'310','DID':'46682'}, {'QID':'311','DID':'46405'}, {'QID':'312','DID':'46629'}, {'QID':'313','DID':'46408'}, {'QID':'314','DID':'46630'}, {'QID':'315','DID':'46412'}, {'QID':'316','DID':'46414'}, {'QID':'317','DID':'46681'}, {'QID':'318','DID':'46416'}, {'QID':'319','DID':'46634'}, {'QID':'320','DID':'46418'},
        {'QID':'321','DID':'46390'}, {'QID':'322','DID':'46391'}, {'QID':'323','DID':'46393'}, {'QID':'324','DID':'46395'}, {'QID':'325','DID':'46396'}, {'QID':'326','DID':'46397'}, {'QID':'327','DID':'46398'}, {'QID':'328','DID':'46399'}, {'QID':'329','DID':'46400'}, {'QID':'330','DID':'46401'}, {'QID':'331','DID':'46403'}, {'QID':'332','DID':'46406'}, {'QID':'333','DID':'46407'}, {'QID':'334','DID':'46409'}, {'QID':'335','DID':'46410'}, {'QID':'336','DID':'46411'}, {'QID':'337','DID':'46413'}, {'QID':'338','DID':'46415'}, {'QID':'339','DID':'46419'}, {'QID':'340','DID':'46422'}, {'QID':'341','DID':'46425'}, {'QID':'342','DID':'46428'}, {'QID':'343','DID':'46429'}, {'QID':'344','DID':'46430'}, {'QID':'345','DID':'46431'}, {'QID':'346','DID':'46434'}, {'QID':'347','DID':'46820'}, {'QID':'348','DID':'46438'}, {'QID':'349','DID':'46439'}, {'QID':'350','DID':'46443'}, {'QID':'351','DID':'46444'}, {'QID':'352','DID':'46446'}, {'QID':'353','DID':'46448'}, {'QID':'354','DID':'46449'}, {'QID':'355','DID':'46450'}, {'QID':'356','DID':'46451'}, {'QID':'357','DID':'46452'}, {'QID':'358','DID':'46453'}, {'QID':'359','DID':'46455'}, {'QID':'360','DID':'46457'},
        {'QID':'361','DID':'46461'}, {'QID':'362','DID':'46462'}, {'QID':'363','DID':'46463'}, {'QID':'364','DID':'46464'}, {'QID':'365','DID':'46466'}, {'QID':'366','DID':'46467'}, {'QID':'367','DID':'46469'}, {'QID':'368','DID':'46470'}, {'QID':'369','DID':'46803'}, {'QID':'370','DID':'46472'}, {'QID':'371','DID':'46473'}, {'QID':'372','DID':'46476'}, {'QID':'373','DID':'46477'}, {'QID':'374','DID':'46943'}, {'QID':'375','DID':'47730'}, {'QID':'376','DID':'46480'}, {'QID':'377','DID':'46482'}, {'QID':'378','DID':'46483'}, {'QID':'379','DID':'46484'}, {'QID':'380','DID':'46485'}, {'QID':'381','DID':'46486'}, {'QID':'382','DID':'46488'}, {'QID':'383','DID':'46489'}, {'QID':'384','DID':'46491'}, {'QID':'385','DID':'46492'}, {'QID':'386','DID':'46494'}, {'QID':'387','DID':'46497'}, {'QID':'388','DID':'47140'}, {'QID':'389','DID':'47557'}, {'QID':'390','DID':'46501'}, {'QID':'391','DID':'46502'}, {'QID':'392','DID':'46503'}, {'QID':'393','DID':'47133'}, {'QID':'394','DID':'46505'}, {'QID':'395','DID':'46506'}, {'QID':'396','DID':'46507'}, {'QID':'397','DID':'46763'}, {'QID':'398','DID':'46508'}, {'QID':'399','DID':'46915'}, {'QID':'400','DID':'46510'},
        {'QID':'401','DID':'46511'}, {'QID':'402','DID':'46514'}, {'QID':'403','DID':'46515'}, {'QID':'404','DID':'46516'}, {'QID':'405','DID':'46685'}, {'QID':'406','DID':'46519'}, {'QID':'407','DID':'46521'}, {'QID':'408','DID':'46522'}, {'QID':'409','DID':'46523'}, {'QID':'410','DID':'46764'}, {'QID':'411','DID':'46765'}, {'QID':'412','DID':'46386'}, {'QID':'413','DID':'46394'}, {'QID':'414','DID':'46532'}, {'QID':'415','DID':'46392'}, {'QID':'416','DID':'46534'}, {'QID':'417','DID':'46539'}, {'QID':'418','DID':'46600'}, {'QID':'419','DID':'46544'}, {'QID':'420','DID':'46545'}, {'QID':'421','DID':'46546'}, {'QID':'422','DID':'46547'}, {'QID':'423','DID':'51350'}, {'QID':'424','DID':'51347'}, {'QID':'425','DID':'51349'}, {'QID':'426','DID':'51346'}, {'QID':'427','DID':'51235'}, {'QID':'428','DID':'51352'}, {'QID':'429','DID':'51354'}, {'QID':'430','DID':'51356'}, {'QID':'431','DID':'51357'}, {'QID':'432','DID':'51358'}, {'QID':'433','DID':'51506'}, {'QID':'434','DID':'51507'}, {'QID':'435','DID':'51508'}, {'QID':'436','DID':'51509'}, {'QID':'437','DID':'51510'}, {'QID':'438','DID':'51511'}, {'QID':'439','DID':'51344'}, {'QID':'440','DID':'53840'},
        {'QID':'441','DID':'53845'}, {'QID':'442','DID':'53877'}, {'QID':'443','DID':'53893'}, {'QID':'444','DID':'53895'}, {'QID':'445','DID':'53923'}, {'QID':'446','DID':'53908'}, {'QID':'447','DID':'53909'}, {'QID':'448','DID':'53910'}, {'QID':'449','DID':'53926'}, {'QID':'450','DID':'53911'}, {'QID':'451','DID':'53927'}, {'QID':'452','DID':'54004'}, {'QID':'453','DID':'53928'}, {'QID':'454','DID':'53881'}, {'QID':'455','DID':'53879'}, {'QID':'456','DID':'53854'}, {'QID':'457','DID':'53852'},
    ] 
    
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
        var nrows = 25;
        var ncols = 19;
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
        var vlist = getCookie("E"+id);
        var varray = [];
        
        if (vlist != undefined) {
            varray = vlist.split(',');
        }

        for (var i=0; i < (data.length/ncols); i++) { 
            row += "<tr>"
            for (var c=0; c < ncols; c++) {
                var idx = i+nrows*c
                if (idx < data.length) {
                    var fstyle = "text-decoration: underline; "
                    if (varray.indexOf(data[idx].QID) >= 0) {
                        // console.log(data[idx].QID + ":" + varray.indexOf(data[idx].QID))
                        fstyle += "color:" + txtColor + "; font-weight:bold; "
                    }
//                    row += "<td onClick='NewTab(\""+data[idx].QID+"\", \""+data[idx].DID+"\");'><font style='" + fstyle + "' href='#"+id+"-"+data[idx].QID+"' target='_self'>#"+data[idx].QID+"</font></td>"
                    row += "<td onClick='NewTab(\""+data[idx].QID+"\", \""+data[idx].DID+"\");'><font style='" + fstyle + "' target='_self'>#"+data[idx].QID+"</font></td>"
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
        setCookie("E"+seq, vlist, {secure: true, 'expires': expDate});
        setCookie("SAA"+seq, vlist, {secure: true, 'expires': expDate});
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
        var vlist = getCookie("E"+seq);
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
            if (passwd.toLowerCase() == "icttss") {
                url = "https://www.examtopics.com/discussions/amazon/view/" 
                    + discuss_id +
                    "-exam-aws-certified-solutions-architect-associate-saa-c02/";
            }
            window.open(url, "discuss");
        }
        
        buildTable(seq, myArray)
    }
    
    var passwd = getCookie('password');

    if (passwd == undefined) {
        let passwd = prompt("Please enter password for use this page");

        if (passwd.toLowerCase() == "icttss") {
            var expDate = new Date();
            expDate.setMonth(expDate.getMonth() + 1);
            expDate = expDate.toUTCString();
            setCookie('password', passwd, {secure: true, 'expires': expDate});
        }
    }
    passwd = getCookie('password');
    // Example of use:
    // setCookie('user', 'Changwha Jeong', {secure: true, 'max-age': 3600});
    // setCookie('E1', '002,020,420', {secure: true, 'max-age': 3600});
    // setCookie('E2', '012,220,400', {secure: true, 'max-age': 3600});
    // setCookie('EX', '102,120,300', {secure: true, 'max-age': 0});

        
