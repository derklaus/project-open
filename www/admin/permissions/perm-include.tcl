# /packages/intranet-core/www/admin/permissions/perm-include.tcl
#
# Copyright (C) various parties
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

# This is a copy of /packages/acs-subsite/www/admin/permissions/perm-include.tcl
# Unfortunately P/O has to introduce some changes in this code that are
# not compatible with the rest of OpenACS (such as the URL where to find
# more information about users).

# expects:
# object_id
# return_url
# privs:optional, defaults to 'read', 'write', 'admin'
# user_add_url: URL to the page for adding users

set user_id [ad_conn user_id]
set admin_p [ad_permission_p $object_id admin]

if { ![exists_and_not_null return_url] } {
    set return_url [ad_return_url]
}

if { ![exists_and_not_null privs] } {
    set privs { read create write admin }
}

db_1row object_info {}

set elements [list]
lappend elements grantee_name { 
    label "Name" 
    link_url_col name_url
    display_template {
        <if @permissions.any_perm_p_@ true>
          @permissions.grantee_name@
        </if>
        <else>
          <font color="gray">@permissions.grantee_name@</font>
        </else>
    }
}

foreach priv $privs { 
    lappend select_clauses "sum(ptab.${priv}_p) as ${priv}_p"
    lappend select_clauses "(case when sum(ptab.${priv}_p) > 0 then 'checked' else '' end) as ${priv}_checked"
    lappend from_all_clauses "(case when privilege='${priv}' then 2 else 0 end) as ${priv}_p"
    lappend from_direct_clauses "(case when privilege='${priv}' then -1 else 0 end) as ${priv}_p"
    lappend from_dummy_clauses "0 as ${priv}_p"

    lappend elements ${priv}_p \
        [list \
             html { align center } \
             label [string totitle [string map {_ { }} $priv]] \
             display_template "
               <if @permissions.${priv}_p@ ge 2>
                 <img src=\"/shared/images/checkboxchecked\" border=\"0\" height=\"13\" width=\"13\" alt=\"X\" title=\"This permission is inherited, to remove, click the 'Do not inherit ...' button above.\">
               </if>
               <else>
                 <input type=\"checkbox\" name=\"perm\" value=\"@permissions.grantee_id@,${priv}\" @permissions.${priv}_checked@>
               </else>
             " \
            ]
}

# Remove all
lappend elements remove_all {
    html { align center } 
    label "Remove All"
    display_template {<input type="checkbox" name="perm" value="@permissions.grantee_id@,remove">}
}



set perm_url "[site_node_closest_ancestor_package_url]permissions/"

if { ![exists_and_not_null user_add_url] } {
    set user_add_url "${perm_url}perm-user-add"
}
set user_add_url [export_vars -base $user_add_url { object_id expanded {return_url "[ad_return_url]"}}]


set actions [list]
# lappend actions [list "Add user" $user_add_url "Grant permissions to a new user"]

set add_group_url "/admin/groups/new?group_id=&group_type_exact_p=t&group_type=group&return_url=$return_url"
lappend actions "Add a new profile" $add_group_url "Create a new profile"


if { 0 && ![empty_string_p $context_id] } {
    set inherit_p [permission::inherit_p -object_id $object_id]

    if { $inherit_p } {
        lappend actions "Do not inherit from $parent_object_name" [export_vars -base "${perm_url}toggle-inherit" {object_id {return_url [ad_return_url]}}] "Stop inheriting permissions from the $parent_object_name"
    } else {
        lappend actions "Inherit from $parent_object_name" [export_vars -base "${perm_url}toggle-inherit" {object_id {return_url [ad_return_url]}}] "Inherit permissions from the $parent_object_name"
    }
}

# Disable all actions so far
# set actions [list]



# TODO: Inherit/don't inherit

template::list::create \
    -name permissions \
    -multirow permissions \
    -actions $actions \
    -elements $elements 


set perm_form_export_vars [export_vars -form {object_id privs return_url}]

set perm_modify_url "${perm_url}perm-modify"

set application_group_id [application_group::group_id_from_package_id -package_id [ad_conn subsite_id]]


# PERMISSION: yes = 2, no = 0
# DIRECT:     yes = 1, no = -1

# 3 = permission + direct
# 2 = permission, no direct
# 1 = no permission, but direct (can't happen)
# 0 = no permission


# 2 = has permission, not direct => inherited
# 1 = has permission, it's direct => direct
# -1 = no permission 

# NOTE:
# We do not include site-wide admins in the list

db_multirow -extend { name_url } permissions permissions {} {
    if { [string equal $object_type "user"] && $grantee_id != 0 } {
        set name_url [acs_community_member_url -user_id $grantee_id]
}
}


ad_return_template

