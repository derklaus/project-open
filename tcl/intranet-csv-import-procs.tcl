# /packages/intranet-cvs-import/tcl/intranet-cvs-import-procs.tcl
#
# Copyright (C) 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc -public im_csv_import_label_from_object_typet {
    -object_type:required
} {
    Returns the main navbar lable for the object_type
} {
    switch $object_type {
	im_company { return "companies" }
	im_project { return "projects" }
	person { return "users" }
	default { return "" }
    }
}




# ---------------------------------------------------------------------
# Available Fields per Object Type
# ---------------------------------------------------------------------

ad_proc -public im_csv_import_object_fields {
    -object_type:required
} {
    Returns the main navbar lable for the object_type
} {
    switch $object_type {
	im_project {
	    set object_fields {
		customer_name
		parent_nrs
		project_nr
		project_name
		project_status
		project_type
		start_date
		end_date
		customer_contact
		on_track_status
		percent_completed
		project_manager
		project_priority
		program
		milestone_p
		description
		note
		material
		uom
		planned_units
		billable_units
		cost_center_code
		timesheet_task_priority
		sort_order
		project_budget
		project_budget_currency
		project_budget_hours
		presales_probability
		presales_value
		project_path
		confirm_date
		source_language
		subject_area
		final_company
		expected_quality
		customer_project_nr
	    }
	}
	default {
	    ad_return_complaint 1 "Unknown object type '$object_type'"
	    ad_script_abort
	}
    }

    set dynfield_sql "
	select	aa.*,
		a.*,
		w.*
	from	im_dynfield_widgets w,
		im_dynfield_attributes a,
		acs_attributes aa
	where	a.widget_name = w.widget_name and
		a.acs_attribute_id = aa.attribute_id and
		aa.object_type in ('im_project', 'im_timesheet_task') and
		(also_hard_coded_p is null OR also_hard_coded_p = 'f')
    "
    db_foreach dynfields $dynfield_sql {
	lappend object_fields $attribute_name
    }    

    return $object_fields
}


# ---------------------------------------------------------------------
# Available Parsers
# ---------------------------------------------------------------------

ad_proc -public im_csv_import_parsers {
    -object_type:required
} {
    Returns the list of available parsers
} {
    switch $object_type {
	im_project {
	    set parsers {
		no_change	"No Change"
		date_european	"European Data Parser (DD.MM.YYYY)"
	    }
	}
	default {
	    ad_return_complaint 1 "Unknown object type '$object_type'"
	    ad_script_abort
	}
    }
    return $parsers
}



# ---------------------------------------------------------------------
# Guess the most appropriate parser for a column
# ---------------------------------------------------------------------

ad_proc -public im_csv_import_guess_parser {
    {-sample_values {}}
    -object_type:required
    -field_name:required
} {
    Returns the best guess for a parser for the given field
} {
    # Abort if there are not enough values
    if {[llength $sample_values] < 2} { return "" }

    # Available parsers
    set date_european_p 1
    set date_american_p 1
    set number_plain_p 1
    set number_european_p 1
    set number_american_p 1

    # set the parserst to 0 if one of the values doesn't fit
    foreach val $sample_values { 

	if {![regexp {^(.+)\.(.+)\.(....)$} $val match]} { set date_european_p 0 } 
	if {![regexp {^[0-9]+$} $val match]} { set number_plain 0 } 

    }

    if {$date_european_p} { return "date_european" }
    if {$number_plain_p} { return "number_plain" }

    return ""
}


# ---------------------------------------------------------------------
# Convert the list of parent_nrs into the parent_id
# ---------------------------------------------------------------------

ad_proc -public im_csv_import_convert_project_parent_nrs { 
    {-parent_id ""}
    parent_nrs 
} {
    Returns {parent_id err}
} {
    ns_log Notice "im_csv_import_convert_project_parent_nrs -parent_id $parent_id $parent_nrs"

    # Recursion end - just return the parent.
    if {"" == $parent_nrs} { return [list $parent_id ""] }
    
    # Lookup the first parent_nr below the current parent_id
    set parent_nr [lindex $parent_nrs 0]
    set parent_nrs [lrange $parent_nrs 1 end]

    set parent_sql "= $parent_id"
    if {"" == $parent_id} { set parent_sql "is null" }

    set parent_id [db_string pid "
	select	project_id
	from	im_projects
	where	parent_id $parent_sql and
		lower(project_nr) = lower(:parent_nr)
    "]

    if {"" == $parent_id} {
	return [list "" "Didn't find project with project_nr='$project_nr' and parent_id='$parent_id'"]
    }

    return [im_csv_import_convert_project_parent_nrs -parent_id $parent_id $parent_nrs]
}