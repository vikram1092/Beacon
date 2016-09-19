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
    
    
    
    internal func getCountryImage(_ countryCode: String) -> UIImage {
        
        let link  = "Countries/" + countryCode.lowercased() + "/128.png"
        
        if let image = UIImage(named: link) {
            
            return image
        }
        
        return UIImage(named: "Countries/Unknown/128.png")!
    }
    
    
    internal func getCountryName(_ countryCode: String) -> String {
        
        var countryName = "Unknown"
        print("Country:" + countryCode.lowercased())
        
        //Find country and obtain the 2 digit ISO code
        for country in countryTable {
            
            if country[1] == countryCode.lowercased() {
                countryName = country[0]
                break
            }
        }
        
        return countryName
    }
    
    
    internal func getStateName(_ stateCode: String) -> String {
        
        
        var stateName = "Unknown"
        print("State:" + stateCode.lowercased())
        
        //Find state and obtain name from the 2 digit code
        for state in usaStateTable {
            
            if state[1] == stateCode.lowercased() {
                stateName = state[0]
                break
            }
        }
        
        return stateName
    }
    
    
    internal func getStateCode(_ stateName: String) -> String {
        
        
        var stateCode = "Unknown"
        print("State:" + stateCode.lowercased())
        
        //Find state and obtain name from the 2 digit code
        for state in usaStateTable {
            
            if state[0].lowercased() == stateName.lowercased() {
                stateCode = state[1]
                break
            }
        }
        
        return stateCode
    }
    
    
    internal func getStateImage(_ stateCode: String) -> UIImage {
        
        let link  = "Countries/States of the United States/" + stateCode.lowercased() + "/128.png"
        
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
        ["Washington, D.C.", "dc"],
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
        ["Antigua & Barbuda","ag"],
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
        ["Bosnia & Herzegovina","ba"],
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
        ["Central African Rep.","cf"],
        ["Chad","td"],
        ["Chile","cl"],
        ["China","cn"],
        ["Christmas Island","cx"],
        ["Cocos (Keeling) Islands","cc"],
        ["Colombia","co"],
        ["Comoros","km"],
        ["Congo","cg"],
        ["Rep. of Congo","cd"],
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
        ["Heard Is & McDonald Is","hm"],
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
        ["Northern Mariana Is","mp"],
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
        ["Russia","ru"],
        ["Rwanda","rw"],
        ["Saint Barthélemy","bl"],
        ["Saint Helena, Ascension & Tristan da Cunha","sh"],
        ["Saint Kitts and Nevis","kn"],
        ["Saint Lucia","lc"],
        ["Saint Martin (French part)","mf"],
        ["Saint Pierre & Miquelon","pm"],
        ["Saint Vincent & Grenadines","vc"],
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
        ["South Georgia & South Sandwich Is","gs"],
        ["South Sudan","ss"],
        ["Spain","es"],
        ["Sri Lanka","lk"],
        ["Sudan","sd"],
        ["Suriname","sr"],
        ["Svalbard and Jan Mayen","sj"],
        ["Swaziland","sz"],
        ["Sweden","se"],
        ["Switzerland","ch"],
        ["Syria","sy"],
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
