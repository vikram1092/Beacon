//
//  CountryTable.swift
//  Spore
//
//  Created by Vikram Ramkumar on 3/14/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit

class CountryTable {
    
    
    
    internal func getCountryImage(countryCode: String) -> UIImage {
        
        let link  = "Countries/" + countryCode.lowercaseString + "/128.png"
        
        if let image = UIImage(named: link) {
            
            return image
        }
        
        return UIImage(named: "Countries/Unknown/128.png")!
    }
    
    
    internal func getCountryName(countryCode: String) -> String {
        
        var countryName = "Unknown"
        print("Country:" + countryCode.lowercaseString)
        
        //Find country and obtain the 2 digit ISO code
        for country in countryTable {
            
            if country[1] == countryCode.lowercaseString {
                countryName = country[0]
                break
            }
        }
        
        return countryName
    }
    
    
    internal func getStateName(stateCode: String) -> String {
        
        
        var stateName = "Unknown"
        print("State:" + stateCode.lowercaseString)
        
        //Find state and obtain name from the 2 digit code
        for state in usaStateTable {
            
            if state[1] == stateCode.lowercaseString {
                stateName = state[0]
                break
            }
        }
        
        return stateName
    }
    
    
    internal func getStateCode(stateName: String) -> String {
        
        
        var stateCode = "Unknown"
        print("State:" + stateCode.lowercaseString)
        
        //Find state and obtain name from the 2 digit code
        for state in usaStateTable {
            
            if state[0].lowercaseString == stateName.lowercaseString {
                stateCode = state[1]
                break
            }
        }
        
        return stateCode
    }
    
    
    internal func getStateImage(stateCode: String) -> UIImage {
        
        let link  = "Countries/States of the United States/" + stateCode.lowercaseString + "/128.png"
        
        if let image = UIImage(named: link) {
            
            return image
        }
        
        return UIImage(named: "Countries/Unknown/128.png")!
    }
    
    
    var usaStateTable = [["Alabama", "al"],
        ["Alaska", "ak"],
        ["Arizona", "az"],
        ["Arkansas", "ar"],
        ["California", "ca"],
        ["Colorado", "co"],
        ["Connecticut", "ct"],
        ["Delaware", "de"],
        ["Florida", "fl"],
        ["Georgia", "ga"],
        ["Hawaii", "hi"],
        ["Idaho", "id"],
        ["Illinois", "il"],
        ["Indiana", "in"],
        ["Iowa", "ia"],
        ["Kansas", "ks"],
        ["Kentucky", "ky"],
        ["Louisiana", "la"],
        ["Maine", "me"],
        ["Maryland", "md"],
        ["Massachusetts", "ma"],
        ["Michigan", "mi"],
        ["Minnesota", "mn"],
        ["Mississippi", "ms"],
        ["Missouri", "mo"],
        ["Montana", "mt"],
        ["Nebraska", "ne"],
        ["Nevada", "nv"],
        ["New Hampshire", "nh"],
        ["New Jersey", "nj"],
        ["New Mexico", "nm"],
        ["New York", "ny"],
        ["North Carolina", "nc"],
        ["North Dakota", "nd"],
        ["Ohio", "oh"],
        ["Oklahoma", "ok"],
        ["Oregon", "or"],
        ["Pennsylvania", "pa"],
        ["Rhode Island", "ri"],
        ["South Carolina", "sc"],
        ["South Dakota", "sd"],
        ["Tennessee", "tn"],
        ["Texas", "tx"],
        ["Utah", "ut"],
        ["Vermont", "vt"],
        ["Virginia", "va"],
        ["Washington", "wa"], 
        ["West Virginia", "wv"], 
        ["Wisconsin", "wi"], 
        ["Wyoming", "wy"], 
        ["American Samoa", "as"], 
        ["District of Columbia", "dc"], 
        ["Federated States of Micronesia", "fm"], 
        ["Guam", "gu"], 
        ["Marshall Islands", "mh"], 
        ["Northern Mariana Islands", "mp"], 
        ["Palau", "pw"], 
        ["Puerto Rico", "pr"], 
        ["Virgin Islands", "vi"]]
    
    
    var countryTable = [["Afghanistan","af"],
        ["Åland Islands","ax"],
        ["Albania","al"],
        ["Algeria","dz"],
        ["American Samoa","as"],
        ["Andorra","ad"],
        ["Angola","ao"],
        ["Anguilla","ai"],
        ["Antarctica","aq"],
        ["Antigua and Barbuda","ag"],
        ["Argentina","ar"],
        ["Armenia","am"],
        ["Aruba","aw"],
        ["Australia","au"],
        ["Austria","at"],
        ["Azerbaijan","az"],
        ["Bahamas","bs"],
        ["Bahrain","bh"],
        ["Bangladesh","bd"],
        ["Barbados","bb"],
        ["Belarus","by"],
        ["Belgium","be"],
        ["Belize","bz"],
        ["Benin","bj"],
        ["Bermuda","bm"],
        ["Bhutan","bt"],
        ["Bolivia","bo"],
        ["Bonaire, Sint Eust. & Saba","bq"],
        ["Bosnia and Herzegovina","ba"],
        ["Botswana","bw"],
        ["Bouvet Island","bv"],
        ["Brazil","br"],
        ["British Indian Ocean Territory","io"],
        ["Brunei Darussalam","bn"],
        ["Bulgaria","bg"],
        ["Burkina Faso","bf"],
        ["Burundi","bi"],
        ["Cambodia","kh"],
        ["Cameroon","cm"],
        ["Canada","ca"],
        ["Cabo Verde","cv"],
        ["Cayman Islands","ky"],
        ["Central African Republic","cf"],
        ["Chad","td"],
        ["Chile","cl"],
        ["China","cn"],
        ["Christmas Island","cx"],
        ["Cocos (Keeling) Islands","cc"],
        ["Colombia","co"],
        ["Comoros","km"],
        ["Congo","cg"],
        ["Congo","cd"],
        ["Cook Islands","ck"],
        ["Costa Rica","cr"],
        ["Côte d'Ivoire","ci"],
        ["Croatia","hr"],
        ["Cuba","cu"],
        ["Curaçao","cw"],
        ["Cyprus","cy"],
        ["Czech Republic","cz"],
        ["Denmark","dk"],
        ["Djibouti","dj"],
        ["Dominica","dm"],
        ["Dominican Republic","do"],
        ["Ecuador","ec"],
        ["Egypt","eg"],
        ["El Salvador","sv"],
        ["Equatorial Guinea","gq"],
        ["Eritrea","er"],
        ["Estonia","ee"],
        ["Ethiopia","et"],
        ["Falkland Islands (Malvinas)","fk"],
        ["Faroe Islands","fo"],
        ["Fiji","fj"],
        ["Finland","fi"],
        ["France","fr"],
        ["French Guiana","gf"],
        ["French Polynesia","pf"],
        ["French Southern Territories","tf"],
        ["Gabon","ga"],
        ["Gambia","gm"],
        ["Georgia","ge"],
        ["Germany","de"],
        ["Ghana","gh"],
        ["Gibraltar","gi"],
        ["Greece","gr"],
        ["Greenland","gl"],
        ["Grenada","gd"],
        ["Guadeloupe","gp"],
        ["Guam","gu"],
        ["Guatemala","gt"],
        ["Guernsey","gg"],
        ["Guinea","gn"],
        ["Guinea-Bissau","gw"],
        ["Guyana","gy"],
        ["Haiti","ht"],
        ["Heard Island and McDonald Islands","hm"],
        ["Holy See","va"],
        ["Honduras","hn"],
        ["Hong Kong","hk"],
        ["Hungary","hu"],
        ["Iceland","is"],
        ["India","in"],
        ["Indonesia","id"],
        ["Iran","ir"],
        ["Iraq","iq"],
        ["Ireland","ie"],
        ["Isle of Man","im"],
        ["Israel","il"],
        ["Italy","it"],
        ["Jamaica","jm"],
        ["Japan","jp"],
        ["Jersey","je"],
        ["Jordan","jo"],
        ["Kazakhstan","kz"],
        ["Kenya","ke"],
        ["Kiribati","ki"],
        ["North Korea","kp"],
        ["South Korea","kr"],
        ["Kuwait","kw"],
        ["Kyrgyzstan","kg"],
        ["Laos","la"],
        ["Latvia","lv"],
        ["Lebanon","lb"],
        ["Lesotho","ls"],
        ["Liberia","lr"],
        ["Libya","ly"],
        ["Liechtenstein","li"],
        ["Lithuania","lt"],
        ["Luxembourg","lu"],
        ["Macao","mo"],
        ["Macedonia ","mk"],
        ["Madagascar","mg"],
        ["Malawi","mw"],
        ["Malaysia","my"],
        ["Maldives","mv"],
        ["Mali","ml"],
        ["Malta","mt"],
        ["Marshall Islands","mh"],
        ["Martinique","mq"],
        ["Mauritania","mr"],
        ["Mauritius","mu"],
        ["Mayotte","yt"],
        ["Mexico","mx"],
        ["Micronesia","fm"],
        ["Moldova","md"],
        ["Monaco","mc"],
        ["Mongolia","mn"],
        ["Montenegro","me"],
        ["Montserrat","ms"],
        ["Morocco","ma"],
        ["Mozambique","mz"],
        ["Myanmar","mm"],
        ["Namibia","na"],
        ["Nauru","nr"],
        ["Nepal","np"],
        ["Netherlands","nl"],
        ["New Caledonia","nc"],
        ["New Zealand","nz"],
        ["Nicaragua","ni"],
        ["Niger","ne"],
        ["Nigeria","ng"],
        ["Niue","nu"],
        ["Norfolk Island","nf"],
        ["Northern Mariana Islands","mp"],
        ["Norway","no"],
        ["Oman","om"],
        ["Pakistan","pk"],
        ["Palau","pw"],
        ["Palestine, State of","ps"],
        ["Panama","pa"],
        ["Papua New Guinea","pg"],
        ["Paraguay","py"],
        ["Peru","pe"],
        ["Philippines","ph"],
        ["Pitcairn","pn"],
        ["Poland","pl"],
        ["Portugal","pt"],
        ["Puerto Rico","pr"],
        ["Qatar","qa"],
        ["Réunion","re"],
        ["Romania","ro"],
        ["Russian Federation","ru"],
        ["Rwanda","rw"],
        ["Saint Barthélemy","bl"],
        ["Saint Helena, Ascension and Tristan da Cunha","sh"],
        ["Saint Kitts and Nevis","kn"],
        ["Saint Lucia","lc"],
        ["Saint Martin (French part)","mf"],
        ["Saint Pierre and Miquelon","pm"],
        ["Saint Vincent and the Grenadines","vc"],
        ["Samoa","ws"],
        ["San Marino","sm"],
        ["Sao Tome and Principe","st"],
        ["Saudi Arabia","sa"],
        ["Senegal","sn"],
        ["Serbia","rs"],
        ["Seychelles","sc"],
        ["Sierra Leone","sl"],
        ["Singapore","sg"],
        ["Sint Maarten (Dutch part)","sx"],
        ["Slovakia","sk"],
        ["Slovenia","si"],
        ["Solomon Islands","sb"],
        ["Somalia","so"],
        ["South Africa","za"],
        ["South Georgia and the South Sandwich Islands","gs"],
        ["South Sudan","ss"],
        ["Spain","es"],
        ["Sri Lanka","lk"],
        ["Sudan","sd"],
        ["Suriname","sr"],
        ["Svalbard and Jan Mayen","sj"],
        ["Swaziland","sz"],
        ["Sweden","se"],
        ["Switzerland","ch"],
        ["Syrian Arab Republic","sy"],
        ["Taiwan","tw"],
        ["Tajikistan","tj"],
        ["Tanzania","tz"],
        ["Thailand","th"],
        ["Timor-Leste","tl"],
        ["Togo","tg"],
        ["Tokelau","tk"],
        ["Tonga","to"],
        ["Trinidad and Tobago","tt"],
        ["Tunisia","tn"],
        ["Turkey","tr"],
        ["Turkmenistan","tm"],
        ["Turks and Caicos Islands","tc"],
        ["Tuvalu","tv"],
        ["Uganda","ug"],
        ["Ukraine","ua"],
        ["UAE","ae"],
        ["United Kingdom","gb"],
        ["USA","us"],
        ["US Minor Outlying Islands","um"],
        ["Uruguay","uy"],
        ["Uzbekistan","uz"],
        ["Vanuatu","vu"],
        ["Venezuela","ve"],
        ["Vietnam","vn"],
        ["Virgin Islands (British)","vg"],
        ["Virgin Islands (U.S.)","vi"],
        ["Wallis and Futuna","wf"],
        ["Western Sahara","eh"],
        ["Yemen","ye"],
        ["Zambia","zm"],
        ["Zimbabwe","zw"]]
}