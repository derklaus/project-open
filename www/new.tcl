# /packages/intranet-helpdesk/www/new.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


# -----------------------------------------------------------
# Page Head
#
# There are two different heads, depending whether it's called
# "standalone" (TCL-page) or as a Workflow Panel.
# -----------------------------------------------------------

# Skip if this page is called as part of a Workflow panel
if {![info exists task]} {

    ad_page_contract {
	@author frank.bergmann@project-open.com
    } {
	ticket_id:integer,optional
	{ ticket_name "" }
	{ ticket_nr "" }
	{ ticket_sla_id "" }
	{ task_id "" }
	{ return_url "" }
	edit_p:optional
	message:optional
	{ ticket_status_id "[im_ticket_status_open]" }
	{ ticket_type_id 0 }
	{ return_url "/intranet-helpdesk/" }
	{ vars_from_url ""}
	{ plugin_id:integer 0 }
	{ view_name "standard"}
	form_mode:optional
    }

    set show_components_p 1
    set enable_master_p 1
    set show_user_info_p 1

} else {
    
    set task_id $task(task_id)
    set case_id $task(case_id)

    set vars_from_url ""
    set return_url [im_url_with_query]

    set ticket_id [db_string pid "select object_id from wf_cases where case_id = :case_id" -default ""]
    set transition_key [db_string transition_key "select transition_key from wf_tasks where task_id = :task_id"]
    set task_page_url [export_vars -base [ns_conn url] { ticket_id task_id return_url}]

    set show_components_p 0
    set enable_master_p 0
    set show_user_info_p 0
    set ticket_sla_id ""

    set plugin_id 0
    set view_name "standard"

}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set current_url [im_url_with_query]
set action_url "/intranet-helpdesk/new"
set focus "ticket.var_name"
set td_class(0) "class=roweven"
set td_class(1) "class=rowodd"

if {[info exists ticket_id] && "" == $ticket_id} { unset ticket_id }

if {0 == $ticket_type_id || "" == $ticket_type_id} {
    if {[exists_and_not_null ticket_id]} { 
	set ticket_type_id [db_string ttype_id "select ticket_type_id from im_tickets where ticket_id = :ticket_id" -default 0]
    }
}
if {0 != $ticket_type_id} { 
    set ticket_type [im_category_from_id $ticket_type_id]
    set page_title [lang::message::lookup "" intranet-helpdesk.New_TicketType "New %ticket_type%"]
} else {
    set page_title [lang::message::lookup "" intranet-helpdesk.New_Ticket "New Ticket"]
}
set context [list $page_title]

# ----------------------------------------------
# Calculate form_mode

if {"edit" == [template::form::get_action ticket]} { set form_mode "edit" }
if {![info exists ticket_id]} { set form_mode "edit" }
if {![info exists form_mode]} { set form_mode "display" }

set edit_ticket_status_p [im_permission $current_user_id edit_ticket_status]

# Show the ADP component plugins?
if {"edit" == $form_mode} { set show_components_p 0 }

# Can the currrent user create new helpdesk customers?
set user_can_create_new_customer_p 1
set user_can_create_new_customer_contact_p 1

set ticket_exists_p 0
if {[exists_and_not_null ticket_id]} {
    set ticket_exists_p [db_string ticket_exists_p "select count(*) from im_tickets where ticket_id = :ticket_id"]
}

# ---------------------------------------------
# The base form.
# Define this in the beginning, so we can check the form state
# ---------------------------------------------

set actions [list {"Edit" edit}]
if {[im_permission $current_user_id add_tickets]} { lappend actions {"Delete" delete} }

ad_form \
    -name ticket \
    -cancel_url $return_url \
    -action $action_url \
    -actions $actions \
    -has_edit 1 \
    -mode $form_mode \
    -export {next_url return_url}


# ------------------------------------------------------------------
# Delete?
# ------------------------------------------------------------------

set button_pressed [template::form get_action ticket]
if {"delete" == $button_pressed} {
     db_dml mark_ticket_deleted "
	update	im_tickets
	set	ticket_status_id = [im_ticket_status_deleted]
	where	ticket_id = :ticket_id
     "
    ad_returnredirect $return_url
}


# ------------------------------------------------------------------
# Form_mode == Edit 
# Make sure everything's there for creating a ticket
# ------------------------------------------------------------------

if {"edit" == $form_mode} {

    # ------------------------------------------------------------------
    # Redirect if the type of the object hasn't been defined and
    # if there are DynFields specific for subtypes.
    if {("" == $ticket_type_id || 0 == $ticket_type_id) && ![exists_and_not_null ticket_id]} {
	set all_same_p [im_dynfield::subtype_have_same_attributes_p -object_type "im_ticket"]
	set all_same_p 0
	if {!$all_same_p} {
	    ad_returnredirect [export_vars -base "/intranet/biz-object-type-select" {{object_type "im_ticket"} {return_url $current_url} {type_id_var ticket_type_id} ticket_name ticket_nr ticket_sla_id {pass_through_variables {ticket_nr ticket_name ticket_sla_id}}}]
	}
    }


    # ------------------------------------------------------------------
    # Redirect if the SLA hasn't been defined yet

    if {("" == $ticket_sla_id || 0 == $ticket_sla_id) && ![exists_and_not_null ticket_id]} {
	ad_returnredirect [export_vars -base "select-sla" {{return_url $current_url} ticket_name ticket_status_id ticket_type_id ticket_nr {pass_through_variables {ticket_nr ticket_name ticket_status_id ticket_type_id}}}]
    }

}


# ------------------------------------------------------------------
# Get information about the ticket
# in order to set options right
# ------------------------------------------------------------------

if {$ticket_exists_p} {

    db_1row ticket_info "
	select
		t.*, p.*,
		p.company_id as ticket_customer_id
	from
		im_projects p,
		im_tickets t
	where
		p.project_id = t.ticket_id
		and p.project_id = :ticket_id
    "

}

# Check if we can get the ticket_customer_id.
# We need this field in order to limit the customer contacts to show.
if {![exists_and_not_null ticket_customer_id] && [exists_and_not_null ticket_sla_id]} {
    set ticket_customer_id [db_string cid "select company_id from im_projects where project_id = :ticket_sla_id" -default ""]
}


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set title_label [lang::message::lookup {} intranet-helpdesk.Name {Title}]
set title_help [lang::message::lookup {} intranet-helpdesk.Title_Help {Please enter a descriptive name for the new ticket.}]

set ticket_elements [list]
lappend ticket_elements ticket_id:key
lappend ticket_elements {ticket_name:text(text) {label $title_label} {html {size 50}} {help_text $title_help} }
lappend ticket_elements {ticket_nr:text(hidden),optional }
lappend ticket_elements {start_date:date(hidden),optional }
lappend ticket_elements {end_date:date(hidden),optional }


# ------------------------------------------------------------------
# Form options
# ------------------------------------------------------------------

# customer_options
#
set customer_options [im_company_options -type "Customer" -include_empty 0]
if {$user_can_create_new_customer_p} {
    set customer_options [linsert $customer_options 0 [list "Create New Customer" "new"]]
}
set customer_options [linsert $customer_options 0 [list "" ""]]

if {[exists_and_not_null ticket_customer_id]} {
    set customer_sla_options [im_helpdesk_ticket_sla_options -customer_id $ticket_customer_id -include_create_sla_p 1]
    set customer_contact_options [im_user_options -biz_object_id $ticket_customer_id -include_empty_p 0]
} else {
    set customer_sla_options [im_helpdesk_ticket_sla_options -include_create_sla_p 1]
    set customer_contact_options [im_user_options -include_empty_p 0]
}

# customer_contact_options
#
if {$user_can_create_new_customer_p} {
    set customer_contact_options [linsert $customer_contact_options 0 [list "Create New Customer Contact" "new"]]
}
set customer_contact_options [linsert $customer_contact_options 0 [list "" ""]]


# ------------------------------------------------------------------
# Check permission if the user is allowed to create a ticket for somebody else
# ------------------------------------------------------------------

if {[im_permission $current_user_id add_tickets_for_customers]} {

    lappend ticket_elements {ticket_sla_id:text(select) {label "[lang::message::lookup {} intranet-helpdesk.SLA SLA]"} {options $customer_sla_options}}
    lappend ticket_elements {ticket_customer_contact_id:text(select) {label "[lang::message::lookup {} intranet-helpdesk.Customer_Contact {<nobr>Customer Contact</nobr>}]"} {options $customer_contact_options}}

} else {

    lappend ticket_elements {ticket_sla_id:text(hidden) {options $customer_sla_options}}
    set ticket_customer_contact_id $current_user_id
    set ticket_sla_id "error"

    lappend ticket_elements {ticket_customer_contact_id:text(hidden) {label "[lang::message::lookup {} intranet-helpdesk.Customer_Contact {<nobr>Customer Contact</nobr>}]"} {options $customer_contact_options}}
}



# ---------------------------------------------
# Status & Type
if {$edit_ticket_status_p} {
    lappend ticket_elements {ticket_status_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-helpdesk.Status Status]"} {custom {category_type "Intranet Ticket Status"}} }
}

lappend ticket_elements {ticket_type_id:text(hidden) {label "[lang::message::lookup {} intranet-helpdesk.Type Type]"} {custom {category_type "Intranet Ticket Type"}}}


# ---------------------------------------------
# Extend the form with new fields
# ---------------------------------------------

ad_form -extend -name ticket -form $ticket_elements



set dynfield_ticket_type_id ""
if {[info exists ticket_type_id]} { set dynfield_ticket_type_id $ticket_type_id}

set dynfield_ticket_id ""
if {[info exists ticket_id]} { set dynfield_ticket_id $ticket_id }

set field_cnt [im_dynfield::append_attributes_to_form \
                       -form_display_mode $form_mode \
                       -object_subtype_id $dynfield_ticket_type_id \
                       -object_type "im_ticket" \
                       -form_id "ticket" \
                       -object_id $dynfield_ticket_id \
]


# ------------------------------------------------------------------
# Search 
# ------------------------------------------------------------------

# Set the form variables if we have been redirected from a "new" page.
set url_vars_set [ns_conn form]
foreach var_from_url $vars_from_url {
    ad_set_element_value -element $var_from_url [im_opt_val $var_from_url]
}

# Rediret to SLANewPage if the ticket_sla_id was set to "new"
set ticket_sla_id_value [template::element get_value ticket ticket_sla_id]
if {"new" == $ticket_sla_id_value && $user_can_create_new_customer_p} {

    # Copy all ticket form values to local variables
    template::form::get_values ticket

    # Get the list of all variables in the form
    set form_vars [template::form::get_elements ticket]

    # Remove the "ticket_id" field, because we want ad_form in edit mode.
    set ticket_id_pos [lsearch $form_vars "ticket_id"]
    set form_vars [lreplace $form_vars $ticket_id_pos $ticket_id_pos]

    # Remove the "ticket_customer_id" field to allow the user to select the new customer.
    set ticket_customer_id_pos [lsearch $form_vars "ticket_customer_id"]
    set form_vars [lreplace $form_vars $ticket_customer_id_pos $ticket_customer_id_pos]

    # calculate the vars for _this_ form
    set export_vars_varlist [list]
    foreach form_var $form_vars {
	lappend export_vars_varlist [list $form_var [im_opt_val $form_var]]
    }

    # Add the "vars_from_url" to tell this form to set from values for these vars when we're back again.
    lappend export_vars_varlist [list vars_from_url $form_vars]

    # Determine the current_url where we have to come back to.
    set current_url [export_vars -base [ad_conn url] $export_vars_varlist]

    # Prepare the URL to create a new customer. 
    set new_customer_url [export_vars -base "/intranet/companies/new" {{company_type_id [im_company_type_customer]} {return_url $current_url}}]
    ad_returnredirect $new_customer_url
}



# Rediret to UserNewPage if the ticket_customer_contact_id was set to "new"
set ticket_customer_contact_id_value [template::element get_value ticket ticket_customer_contact_id]
if {"new" == $ticket_customer_contact_id_value && $user_can_create_new_customer_contact_p} {

    # Copy all ticket form values to local variables
    template::form::get_values ticket

    # Get the list of all variables in the form
    set form_vars [template::form::get_elements ticket]

    # Remove the "ticket_id" field, because we want ad_form in edit mode.
    set ticket_id_pos [lsearch $form_vars "ticket_id"]
    set form_vars [lreplace $form_vars $ticket_id_pos $ticket_id_pos]

    # Remove the "ticket_customer_contact_id" field to allow the user to select the new customer_contact.
    set ticket_customer_contact_id_pos [lsearch $form_vars "ticket_customer_contact_id"]
    set form_vars [lreplace $form_vars $ticket_customer_contact_id_pos $ticket_customer_contact_id_pos]

    # calculate the vars for _this_ form
    set export_vars_varlist [list]
    foreach form_var $form_vars {
	lappend export_vars_varlist [list $form_var [im_opt_val $form_var]]
    }

    # Add the "vars_from_url" to tell this form to set from values for these vars when we're back again.
    lappend export_vars_varlist [list vars_from_url $form_vars]

    # Determine the current_url where we have to come back to.
    set current_url [export_vars -base [ad_conn url] $export_vars_varlist]

    # Prepare the URL to create a new customer_contact. 
    set new_customer_contact_url [export_vars -base "/intranet/users/new" {
	{profile [im_customer_group_id]} 
	{return_url $current_url}
	{also_add_to_biz_object {$ticket_customer_id_value 1300}}
    }]
    ad_returnredirect $new_customer_contact_url
}


# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

# Fix for problem changing to "edit" form_mode
set form_action [template::form::get_action "ticket"]
if {"" != $form_action} { set form_mode "edit" }

ad_form -extend -name ticket -on_request {

    # Populate elements from local variables

} -select_query {

	select	t.*,
		p.*,
		p.parent_id as ticket_sla_id,
		p.project_name as ticket_name,
		p.project_nr as ticket_nr,
		p.company_id as ticket_customer_id
	from	im_projects p,
		im_tickets t
	where	p.project_id = t.ticket_id and
		t.ticket_id = :ticket_id

} -new_data {

    # Create a new forum topic of type "Note"
    set topic_id [db_nextval im_forum_topics_seq]

    db_transaction {
	set ticket_nr [db_nextval im_ticket_seq]
	set start_date [db_string now "select now()::date from dual"]
	set end_date [db_string now "select (now()::date)+1 from dual"]
	set start_date_sql [template::util::date get_property sql_date $start_date]
	set end_date_sql [template::util::date get_property sql_timestamp $end_date]
	
	set ticket_id [db_string ticket_insert {}]
	db_dml ticket_update {}
	db_dml project_update {}

	# Add the current user to the project
        im_biz_object_add_role $current_user_id $ticket_id [im_biz_object_role_project_manager]
	
	# Start a new workflow case
	im_workflow_start_wf -object_id $ticket_id -object_type_id $ticket_type_id -skip_first_transition_p 1
	
	# Write Audit Trail
	im_project_audit $ticket_id
	

	# Create a new forum topic of type "Note"
	set topic_type_id [im_topic_type_id_task]
	set topic_status_id [im_topic_status_id_open]
	set message ""

	if {[info exists ticket_note]} { append message $ticket_note }
	if {[info exists ticket_description]} { append message $ticket_description }
	if {"" == $message} { set message [lang::message::lookup "" intranet-helpdesk.Empty_Forum_Message "No message specified"]}

	db_dml topic_insert {
                insert into im_forum_topics (
                        topic_id, object_id, parent_id,
                        topic_type_id, topic_status_id, owner_id,
                        subject, message
                ) values (
                        :topic_id, :ticket_id, null,
                        :topic_type_id, :topic_status_id, :current_user_id,
                        :ticket_name, :message
                )
	}

	
	# Error handling. Doesn't work yet for some unknown reason
    } on_error {
	ad_return_complaint 1 "<b>Error inserting new ticket</b>:<br>&nbsp;<br>
	<pre>$errmsg</pre>"
    }


} -edit_data {

    set ticket_nr [string tolower $ticket_nr]
    if {"" == $ticket_nr} { set ticket_nr [db_nextval im_ticket_seq] }
    set start_date_sql [template::util::date get_property sql_date $start_date]
    set end_date_sql [template::util::date get_property sql_timestamp $end_date]

    db_dml ticket_update {}
    db_dml project_update {}

    im_dynfield::attribute_store \
	-object_type "im_ticket" \
	-object_id $ticket_id \
	-form_id ticket

    # Write Audit Trail
    im_project_audit $ticket_id

} -on_submit {

	ns_log Notice "new: on_submit"

} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort

} -validate {
    {ticket_name
	{ [string length $ticket_name] < 1000 }
	"[lang::message::lookup {} intranet-helpdesk.Ticket_name_too_long {Ticket Name too long (max 1000 characters).}]" 
    }
}



# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

set user_id $current_user_id

set info_actions [list {"Edit" edit}]
set info_action_url "/intranet/users/view"
ad_form \
    -name userinfo \
    -action $info_action_url \
    -actions $info_actions \
    -mode "display" \
    -export {next_url return_url} \
    -form {
	{user_id:key}
	{email:text(text) {label "[_ intranet-core.Email]"} {html {size 30}}}
	{first_names:text(text) {label "[_ intranet-core.First_names]"} {html {size 30}}}
	{last_name:text(text) {label "[_ intranet-core.Last_name]"} {html {size 30}}}
    } -select_query {
	select	u.*
	from	cc_users u
	where	u.user_id = :user_id
    }


# ------------------------------------------------------------------
# Contact information
# ------------------------------------------------------------------

# ToDo: Convert into component and use component for /users/view

set read 1
set write 1

db_1row user_info "
	select	u.*,
		uc.*,
		(select country_name from country_codes where iso = uc.ha_country_code) as ha_country_name,
		(select country_name from country_codes where iso = uc.wa_country_code) as wa_country_name
	from	cc_users u
		LEFT OUTER JOIN users_contact uc ON (u.user_id = uc.user_id)
	where	u.user_id = :user_id
"

set view_id [db_string get_view_id "select view_id from im_views where view_name='user_contact'"]

set column_sql "
	select	column_name,
		column_render_tcl,
		visible_for
	from	im_view_columns
	where	view_id=:view_id
		and group_id is null
	order by sort_order
"

set contact_html "
<form method=POST action=/intranet/users/contact-edit>
[export_form_vars user_id return_url]
<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=center>[_ intranet-core.Contact_Information]</td>
  </tr>
"

set ctr 1
db_foreach column_list_sql $column_sql {
        if {"" == $visible_for || [eval $visible_for]} {
	    append contact_html "
            <tr $td_class([expr $ctr % 2])>
            <td>"
            set cmd0 "append contact_html $column_name"
            eval "$cmd0"
            append contact_html " &nbsp;</td><td>"
	    set cmd "append contact_html $column_render_tcl"
	    eval $cmd
	    append contact_html "</td></tr>\n"
            incr ctr
        }
}    
append contact_html "</table>\n</form>\n"


# ---------------------------------------------------------------
# Ticket Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
if {[info exists ticket_id]} { ns_set put $bind_vars ticket_id $ticket_id }


if {![info exists ticket_id]} { set ticket_id "" }

set ticket_menu_id [db_string parent_menu "select menu_id from im_menus where label='helpdesk'" -default 0]
set sub_navbar [im_sub_navbar \
    -components \
    -current_plugin_id $plugin_id \
    -base_url "/intranet-helpdesk/new?ticket_id=$ticket_id" \
    -plugin_url "/intranet-helpdesk/new" \
    $ticket_menu_id \
    $bind_vars "" "pagedesriptionbar" "helpdesk_summary"] 

