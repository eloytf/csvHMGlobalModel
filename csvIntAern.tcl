proc readCSV {path} {
    #requiere csv con elementos separados por espacios
    set chan [open $path r]
    set fileData [read $chan]
    set data [split $fileData "\n"]
    set processedData [dict create]
    # dict lappend $processedData "Props" [lindex $data 0]
    
    # skip line one
    foreach line $data {
        set line [split $line ","]
        dict lappend processedData [lindex $line 0] [lindex $line 1]
        dict lappend processedData [lindex $line 0] [lindex $line 2]
        dict lappend processedData [lindex $line 0] [lindex $line 3]
        # dict lappend processedData [lindex $line 0] [split [lindex $line 4]  ";"] (sería para elementos separados por puntos y comas
        dict lappend processedData [lindex $line 0] [lindex $line 4]
    # puts $processedData
        
        
    }
    set processedData [dict remove $processedData [lindex [dict keys $processedData] 0]]
    set processedData [dict remove $processedData {}]
    set processedData

}
proc createDics {} {
    #not used
    #id of property, and list of elements still left
    set data [dict create]
    hm_createmark properties 1 "advanced" "all"
    foreach k [hm_getmark properties 1] {
        dict lappend data [hm_getentityvalue property $k name 1] [hm_attributevalue prop $k 95] [hm_getentityvalue material [hm_getentityvalue prop $k materialid 0] name 1]
    }
    set data
}
proc printDict {di} {
    #not used
	#input: a dictionary with elements as keys and list of results as values
	#returns nothing
	#prints to text file
	set path [tk_getSaveFile]
	set chan [open $path w]

	foreach k [dict keys $di] {

		puts -nonewline $chan $k
		puts -nonewline $chan ","
        foreach j [dict get $di $k] {
        
            puts $chan $j
        
        }

	}

	close $chan

}
proc isIDTaken {entity id} {
    #returns 1 if id used in hm
    #0 otherwise
    hm_createmark $entity 1 "advanced" all
    set entityList [hm_getmark $entity 1]
    if {[lsearch $entityList $id]==-1} {
        return 0
    } else {
        return 1
    }

}


proc isSolverIDTaken {entity id} {
    #returns 1 if id used in hm
    #0 otherwise
    hm_createmark $entity 1 "advanced" all
    set entityList [hm_getmark $entity 1]
    set entitySolverList {}
    foreach ent $entityList {
        lappend entitySolverList [lindex [hm_getsolverid2 $entity $ent] 0]
    }
    if {[lsearch $entitySolverList $id]==-1} {
        return 0
    } else {
        return 1
    }


}



proc updateElements {propname elemList {force True} } {
    #assigns propname to elemlist
    #if force==True, empties the property, i.e., only elements in elemList have propname assigned
    

        if {$force} {
            
            hm_createmark elements 1 "by property name" $propname
            
            if { [llength [hm_getmark elements 1]]>0} {
                *propertyupdate elements 1 ""
            }
        
        }
        
        if {[llength $elemList]>0} {
        
            hm_createmark elements 1 $elemList
        
            if { [ catch {
            *propertyupdate elements 1 $propname
            } ] } {
            tk_messageBox -message "Some elements on the list may not exist in HM model"
            }
        }


}
proc CreateProp {propname attributeslist} {
    #Creates Property with name propname with attributes (id, thickness, material and elementlist)
    #If Id is already taken, property will have an arbitrary id
    #calls updateElements
    #returns none (could easily return new id)
    
    if {[isSolverIDTaken "props" [lindex $attributeslist 0]]} {
        tk_messageBox -message "Property ID is already taken. Renumbering arbitrarily"
        *createentity props cardimage=PSHELL name=$propname
        *createmark props 1 -1
        set id [hm_getmark props 1]
        
        set matname [lindex $attributeslist 2]
        
        if {![isMatInHM $matname]} {
    
            *createentity mats cardimage=MAT1 name=$matname
        
        }
        
        *setvalue props name=$propname STATUS=1 95=[lindex $attributeslist 1] material={mats [hm_getentityvalue material $matname id 0]}
        updateElements $propname [lindex $attributeslist 3] 
        # Write renumber of props to log
    } else {
        *createentity props cardimage=PSHELL name=$propname

        set matname [lindex $attributeslist 2]
        
        if {![isMatInHM $matname]} {
    
            *createentity mats cardimage=MAT1 name=$matname
        
        }
        
        *setvalue props name=$propname id={props [lindex $attributeslist 0]} STATUS=1 95=[lindex $attributeslist 1] material={mats [hm_getentityvalue material $matname id 0]}
        updateElements $propname [lindex $attributeslist 3]
    }
    
}
proc UpdateProp {propname attributeslist} {
    #Updates Property with attributes (id, thickness, material and elementlist)
    #If Id is already taken, property id is not updated
    #calls updateElements
    #returns none (could easily return new id)
   
    if {[isSolverIDTaken "props" [lindex $attributeslist 0]]} {
        tk_messageBox -message "Property ID is already taken. Leaving ID as it is in HM"
        
        set matname [lindex $attributeslist 2]
        
        if {![isMatInHM $matname]} {

            *createentity mats cardimage=MAT1 name=$matname
        
        }
        
        *setvalue props name=$propname STATUS=1 95=[lindex $attributeslist 1] material={mats [hm_getentityvalue material $matname id 0]}
        updateElements $propname [lindex $attributeslist 3]
        
    } else {
        set matname [lindex $attributeslist 2]
        
        if {![isMatInHM $matname]} {

            *createentity mats cardimage=MAT1 name=$matname
        
        }
        *setvalue props name=$propname id={props [lindex $attributeslist 0]} STATUS=1 95=[lindex $attributeslist 1] material={mats [hm_getentityvalue material $matname id 0]}
        updateElements $propname [lindex $attributeslist 3]
    }

}
proc isPropInHM {propname} {
    #check if property wih propname exists in HM
    #returns 1 if so. 0 otherwise

    hm_createmark props 1 "advanced" all
    set propList {}
    foreach propid [hm_getmark props 1] { lappend propList [hm_getentityvalue props $propid name 1]}
    if {[lsearch $propList $propname]==-1} {
        return 0
    } else {
        return 1
    }

}
proc isMatInHM {matname} {
    #check if material wih matname exists in HM
    #returns 1 if so. 0 otherwise

    hm_createmark mats 1 "advanced" all
    set matlist {}
    foreach matid [hm_getmark mats 1] { lappend matlist [hm_getentityvalue mats $matid name 1]}
    if {[lsearch $matlist $matname]==-1} {
        return 0
    } else {
        return 1
    }

}
proc updateHM {propname attributeslist} {
    #updates HM with information read from csv via readCSV.
    #calls UpdateProp or CreateProp.


    if {[isPropInHM $propname]} {
    
    UpdateProp $propname $attributeslist
    
    } else {
    
    CreateProp $propname $attributeslist
    
    }

}
proc Main {} {
    #Calls updateHM in loop over data in the dictionary created from csv

    set data [readCSV [tk_getOpenFile]]
    foreach propname [dict keys $data] {
       *mixedpropertywarning 0
       updateHM $propname [dict get $data $propname]
       *mixedpropertywarning 1
    }
}

Main