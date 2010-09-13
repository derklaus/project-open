# /packages/intranet-ganttproject/www/taskjuggler.xml.tcl
#
# Copyright (C) 2003 - 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Create a TaskJuggler .tpj file for scheduling
    @author frank.bergmann@project-open.com
} {
    project_id:integer 
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set today [db_string today "select to_char(now(), 'YYYY-MM-DD')"]
set user_id [ad_maybe_redirect_for_registration]

set hours_per_day 8.0
set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]


# ---------------------------------------------------------------
# Get information about the project
# ---------------------------------------------------------------

if {![db_0or1row project_info "
	select	g.*,
                p.*,
		p.project_id as main_project_id,
                p.start_date::date as project_start_date,
                p.end_date::date as project_end_date,
		c.company_name,
                im_name_from_user_id(p.project_lead_id) as project_lead_name
	from	im_projects p left join im_gantt_projects g on (g.project_id=p.project_id),
		im_companies c
	where	p.project_id = :project_id
		and p.company_id = c.company_id
"]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-ganttproject.Project_Not_Found "Didn't find project \#%project_id%"]
    return
}


# ---------------------------------------------------------------
# Create the TJ Header
# ---------------------------------------------------------------

set base_tj "
/*
 * This file has been automatically created by \]project-open\[
 * Please do not edit manually. 
 */

project p$main_project_id \"$project_name\" \"1.0\" $project_start_date $project_end_date {
    currency \"$default_currency\"
}
"


# ---------------------------------------------------------------
# Create the TJ Footer
# ---------------------------------------------------------------

set footer_tj "

csvtaskreport \"taskjuggler.tasks.csv\"

"




# ---------------------------------------------------------------
# Resource TJ Entries
# ---------------------------------------------------------------

set project_resources_sql "
	select distinct
                p.*,
		im_name_from_user_id(p.person_id) as user_name,
		pa.email,
		uc.*,
		e.*
	from 	users_contact uc,
		acs_rels r,
		im_biz_object_members bom,
		persons p,
		parties pa
		LEFT OUTER JOIN im_employees e ON (pa.party_id = e.employee_id)
	where
		r.rel_id = bom.rel_id
		and r.object_id_two = uc.user_id
		and uc.user_id = p.person_id
		and uc.user_id = pa.party_id
		and r.object_id_one in (
			select	children.project_id as subproject_id
			from	im_projects parent,
				im_projects children
			where	children.project_status_id not in (
					[im_project_status_deleted],
					[im_project_status_canceled]
				)
				and children.tree_sortkey between
					parent.tree_sortkey and
					tree_right(parent.tree_sortkey)
				and parent.project_id = :main_project_id
		   UNION
			select :main_project_id
		)
"

set resource_tj ""
db_foreach project_resources $project_resources_sql {

    set user_tj "resource r$person_id \"$user_name\" {\n"

    if {"" != $hourly_cost} {
	append user_tj "\trate [expr $hourly_cost * $hours_per_day]\n"
    }

    set absences_sql "
	select	ua.start_date::date as absence_start_date,
		ua.end_date::date + 1 as absence_end_date 
	from	im_user_absences ua
	where	ua.owner_id = :person_id and
		ua.end_date >= :project_start_date
	order by start_date
    "
    db_foreach resource_absences $absences_sql {
	append user_tj "\tvacation $absence_start_date - $absence_end_date\n"
    }

    append user_tj "}\n"
    append resource_tj "$user_tj\n"

}

# ---------------------------------------------------------------
# Task TJ Entries
# ---------------------------------------------------------------

# Start writing out the tasks recursively
set tasks_tj [im_taskjuggler_write_subtasks $main_project_id]

set tj_content "
$base_tj
$resource_tj
$tasks_tj
$footer_tj
"


# ---------------------------------------------------------------
# Write to file
# ---------------------------------------------------------------

set project_dir [im_filestorage_project_path $main_project_id]

set tj_folder "taskjuggler"
set tj_file "taskjuggler.tjp"

# Create a "taskjuggler" folder
set tj_dir "$project_dir/$tj_folder"
if {[catch {
    if {![file exists $tj_dir]} {
	ns_log Notice "exec /bin/mkdir -p $tj_dir"
	exec /bin/mkdir -p $tj_dir
	ns_log Notice "exec /bin/chmod ug+w $tj_dir"
	exec /bin/chmod ug+w $tj_dir
    } 
} err_msg]} { 
    ad_return_complaint 1 "<b>Error creating TaskJuggler directory</b>:<br>
    <pre>$err_msg</pre>"
    ad_script_abort
}

if {[catch {
    set fl [open "$tj_dir/$tj_file" "w"]
    puts $fl $tj_content
    close $fl
} err]} {
    ad_return_complaint 1 "<b>Unable to write to $tj_dir/$tj_file</b>:<br><pre>\n$err</pre>"
    ad_script_abort
}


# ---------------------------------------------------------------
# Run TaskJuggler
# ---------------------------------------------------------------


if {[catch {
    set cmd "cd $tj_dir; taskjuggler $tj_file"
    ns_log Notice "exec $cmd"
    exec bash -c $cmd
} err]} {
    ad_return_complaint 1 "<b>Error executing TaskJuggler</b>:<br>
	<pre>
	$err
	</pre>
	<b>Source</b><br>
	Here is the TaskJuggler file that has caused the issue:
	<pre>
	$tj_content
	</pre>
    "
    ad_script_abort
}



ad_return_complaint 1 "<pre>$tj_content</pre>"



ns_return 200 application/octet-stream "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>[$doc asXML -indent 2 -escapeNonASCII]"


