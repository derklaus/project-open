# /packages/intranet-core/users/basic-info-update.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    @param user_id
    
    @author unknown@arsdigita.com
    @author Guillermo Belcic (guillermo.belcic@project-open.com)
    @author frank.bergmann@project-open.com
} {
    user_id:integer,notnull
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
im_user_permissions $current_user_id $user_id view read write admin
if {!write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_1]"
}

# ---------------------------------------------------------------
# Query
# ---------------------------------------------------------------

db_1row user_info "
select
       first_names, 
       last_name, 
       email, 
       url,
       screen_name
from
       users 
where
       user_id = :user_id
"

# ---- Set the title now that the $name is available after the db query

set page_title "$first_names $last_name"
if {[im_permission $current_user_id view_users]} {
    set context_bar [ad_context_bar [list /intranet/users/ "[_ intranet-core.Users]"] $page_title]
} else {
    set context_bar [ad_context_bar $page_title]
}

set is_admin "disabled"
set profile_box ""
if {$admin} {

    # Get the list of current profiles
    set current_profile_list [db_list current_profiles "select unique group_id from user_group_map where group_id < 20 and user_id=:user_id"]

    set profile_box "<select name=profile size=7 multiple>\n"
    # Get the list of profiles that the current_user can set
    set option_list [im_profiles_for_new_user $current_user_id]

    foreach option $option_list {
	set group_id [lindex $option 0]
	set group_name [lindex $option 1]
	set selected [lsearch -exact $current_profile_list $group_id]
	if {$selected > -1} {
	    append profile_box "<option value=$group_id selected>$group_name</option>\n"
	} else {
	    append profile_box "<option value=$group_id>$group_name</option>\n"
	}
    }
    
    append profile_box "</select>\n"
    
    set is_admin ""
}

set body_html "
<form method=POST action=\"basic-info-update-2\">
[export_form_vars user_id]

<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=center>[_ intranet-core.lt_Update_Basic_Informat]</td>
  </tr>
  <tr>
    <td>[_ intranet-core.Name]</td>
    <td><input type=text name=first_names size=20 value=\"$first_names\"> 
        <input type=text name=last_name size=25 value=\"$last_name\">
    </td>
  </tr>
  <tr>
    <td>[_ intranet-core.Email]</td>
    <td><input type=text name=email size=30 value=\"$email\" $is_admin></td>
  </tr>
  <tr>
    <td>[_ intranet-core.Home_Page]</td>
    <td><input type=text name=url size=50 value=\"$url\"></td>
  </tr>"
if {![string equal "" $profile_box]} {
    append body_html "
  <tr>
    <td>[_ intranet-core.Profile]</td>
    <td>$profile_box</td>
  </tr>"
}
append body_html "
</table>
<br>
<br>
<center><input type=submit value=\"[_ intranet-core.Update]\"></center>
"
set page_body "$body_html"
doc_return  200 text/html [im_return_template]