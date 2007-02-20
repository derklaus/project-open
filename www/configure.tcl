# /packages/intranet-sysconfig/www/configure.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Configures the system according to Wizard variables
} {
    { sector "default" }
    { deptcomp "" }
    { features "default" }
    { orgsize "" }
    { prodtest "test" }
    { name "Tigerpond" }
    { name_name "Tigerpond, Inc." }
    { name_email "sysadmin@tigerpond.com" }
    { logo_file "" }
    { logo_url "http://www.project-open.com" }
    profiles_array:array,optional
}

# Default value if profiles_array wasn't specified in a default call
if {![info exists profiles_array]} {
    array set profiles_array {employees,all_projects on project_managers,all_projects on project_managers,all_companies on}
}



# ---------------------------------------------------------------
# Output headers
# Allows us to write out progress info during the execution
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set content_type "text/html"
set http_encoding "iso8859-1"

append content_type "; charset=$http_encoding"

set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"

util_WriteWithExtraOutputHeaders $all_the_headers
ns_startcontent -type $content_type

ns_write "[im_header] [im_navbar]"




# ---------------------------------------------------------------
# Enabling everything
# ---------------------------------------------------------------

ns_write "<h2>Resetting System to Default</h2>\n"

ns_write "<li>Enabling menus ... "
catch {db_dml enable_menus "update im_menus set enabled_p = 't'"}  err
ns_write "done<br><pre>$err</pre>\n"

ns_write "<li>Enabling categories ... "
catch {db_dml enable_categories "update im_categories set enabled_p = 't'"}  err
ns_write "done<br><pre>$err</pre>\n"

ns_write "<li>Enabling components ... "
catch {db_dml enable_components "update im_component_plugins set enabled_p = 't'"}  err
ns_write "done<br><pre>$err</pre>\n"

ns_write "<li>Enabling projects ... "
catch {db_dml enable_projects "update im_projects set project_status_id = [im_project_status_open] where project_status_id = [im_project_status_deleted]"}  err
ns_write "done<br><pre>$err</pre>\n"

# ---------------------------------------------------------------
# Set Name, Email, Logo
# ---------------------------------------------------------------

ns_write "<h2>Setting Name='$name_name', Email='$name_email', Logo</h2>\n";

ns_write "<li>setting name ... "
catch {db_dml set_name "update im_companies set company_name = :name_name where company_path='internal' "} err
ns_write "done<br><pre>$err</pre>\n"

ns_write "<li>setting email ... "
parameter::set_from_package_key -package_key "acs-kernel" -parameter "HostAdministrator" -value $name_email
parameter::set_from_package_key -package_key "acs-kernel" -parameter "OutgoingSender" -value $name_email
parameter::set_from_package_key -package_key "acs-kernel" -parameter "AdminOwner" -value $name_email
parameter::set_from_package_key -package_key "acs-kernel" -parameter "SystemOwner" -value $name_email
parameter::set_from_package_key -package_key "acs-mail-lite" -parameter "NotificationSender" -value $name_email
parameter::set_from_package_key -package_key "acs-subsite" -parameter "NewRegistrationEmailAddress" -value $name_email
ns_write "done<br>\n"

ns_write "<li>setting url ... "
parameter::set_from_package_key -package_key "acs-kernel" -parameter "SystemURL" -value "http://[ad_host]:[ad_port]/" 
ns_write "done<br>\n"

if { ![empty_string_p $logo_file]
} {
    ns_write "<li>setting logo... "

    set logo_path logo[file extension $logo_file]
    file rename -force [acs_root_dir]/www/sysconf-logo.tmp [acs_root_dir]/www/$logo_path
    parameter::set_from_package_key -package_key "intranet-core" -parameter "SystemLogo" -value "/$logo_path"
    parameter::set_from_package_key -package_key "intranet-core" -parameter "SystemLogoLink" -value $logo_url
    ns_write "done<br>\n"
}

# ---------------------------------------------------------------
# Profile Configuration
# ---------------------------------------------------------------

ns_write "<h2>Profiles</h2>\n";

set subsite_id [ad_conn subsite_id]

array set group_ids {
    employees        463
    project_managers 467
    senior_managers  469
}

foreach i [array names group_ids] {
    ns_write "<li>"
    ns_write [lang::message::lookup "" "intranet-sysconfig.profiles_$i" $i] 

    set party_id $group_ids($i)

    if {[info exists profiles_array($i,all_companies)] || $i=="senior_managers"} {
	if {[catch { db_string setting_profiles "select acs_permission__grant_permission(:subsite_id, :party_id, 'edit_companies_all')" } err]} { ns_write $err }
	if {[catch { db_string setting_profiles "select acs_permission__grant_permission(:subsite_id, :party_id, 'view_companies_all')" } err]} { ns_write $err }
    }	  

    if {[info exists profiles_array($i,all_projects)] || $i=="senior_managers"} {
	if {[catch { db_string setting_profiles "select acs_permission__grant_permission(:subsite_id, :party_id, 'edit_projects_all')" } err]} { ns_write $err }
	if {[catch { db_string setting_profiles "select acs_permission__grant_permission(:subsite_id, :party_id, 'view_projects_all')" } err]} { ns_write $err }
	if {[catch { db_string setting_profiles "select acs_permission__grant_permission(:subsite_id, :party_id, 'view_timesheet_tasks_all')" } err]} {	ns_write $err }
	
    }
    if {[info exists profiles_array($i,finance)] || $i=="senior_managers"} {
	foreach j [list add_budget add_budget_hours add_costs add_finance add_invoices add_payments fi_read_all fi_write_all view_costs view_expenses_all view_finance view_hours_all view_invoices view_payments] {
	    if {[catch { db_string setting_profiles "select acs_permission__grant_permission(:subsite_id, :party_id, :j)" } err]} {	    ns_write $err }
	}
    }
    ns_write "...done<br>\n"
}

# ---------------------------------------------------------------
# Sector Configuration
# ---------------------------------------------------------------

switch $sector {
    it_consulting - biz_consulting - advertizing - engineering {
	set install_pc 1
	set install_pt 0
    }
    translation {
	set install_pc 1
	set install_pt 1
    }
    default {
	set install_pc 1
	set install_pt 1
    }
}


set install_pc 1
set install_pt 1


# ---------------------------------------------------------------
# Disable Consulting Stuff

if {!$install_pc} {
    ns_write "<h2>Disabling 'Consulting' Components</h2>"

    # ToDo
    ns_write "<li>Disabling 'Consulting' Categories ... "
    set project_type_consulting_id [db_string t "select category_id from im_categories where category = 'Consulting Project'"]
    catch {db_dml disable_trans_cats "
	update im_categories 
	set enabled_p = 'f'
	where category_id in (
		select child_id
		from im_category_hierarchy
		where parent_id = :project_type_consulting_id
	    UNION
		select :project_type_consulting_id
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"
  
    ns_write "<li>Disabling 'Consulting' Projects ... "
    catch {db_dml disable_trans_cats "
	update im_projects
	set project_status_id = [im_project_status_deleted]
	where project_type_id in (
		select child_id
		from im_category_hierarchy
		where parent_id = :project_type_consulting_id
	    UNION
		select :project_type_consulting_id
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"

    ns_write "<li>Disabling 'Consulting' Menus ... "
    catch {db_dml disable_trans_cats "
	update im_menus
	set enabled_p = 'f'
	where menu_id in (
		select menu_id from im_menus where lower(name) like '%timesheet task%'
	UNION	select menu_id from im_menus where lower(name) like '%wiki%%'
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"

    ns_write "<li>Disabling 'Consulting' Components ... "
    catch {db_dml disable_trans_cats "
	update im_component_plugins
	set enabled_p = 'f'
	where plugin_id in (
		select plugin_id from im_component_plugins where package_name in (
			'timesheet2-invoices', 'intranet-timesheet2-tasks',
			'intranet-ganttproject', 'intranet-wiki'
		)
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"



}

# ---------------------------------------------------------------
# Disable Translation Stuff

if {!$install_pt} {
    ns_write "<h2>Disabling 'Translation' Components</h2>\n"

    ns_write "<li>Disabling 'Translation' Categories ... "
    set project_type_translation_id [db_string t "select category_id from im_categories where category = 'Translation Project'"]
    catch {db_dml disable_trans_cats "
	update im_categories 
	set enabled_p = 'f'
	where category_id in (
		select child_id
		from im_category_hierarchy
		where parent_id = :project_type_translation_id
	    UNION
		select :project_type_translation_id
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"


    ns_write "<li>Disabling 'Translation' Projects ... "
    catch {db_dml disable_trans_cats "
	update im_projects
	set project_status_id = [im_project_status_deleted]
	where project_type_id in (
		select child_id
		from im_category_hierarchy
		where parent_id = :project_type_translation_id
	    UNION
		select :project_type_translation_id
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"

    ns_write "<li>Disabling 'Translation' Menus ... "
    catch {db_dml disable_trans_cats "
	update im_menus
	set enabled_p = 'f'
	where menu_id in (
		select menu_id from im_menus where label like '%_trans_%'
	UNION	select menu_id from im_menus where lower(name) like '%trans%'
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"

    ns_write "<li>Disabling 'Translation' Components ... "
    catch {db_dml disable_trans_cats "
	update im_component_plugins
	set enabled_p = 'f'
	where plugin_id in (
		select plugin_id from im_component_plugins where package_name like '%trans%'
	)
    "}  err
    ns_write "done<br><pre>$err</pre>\n"


}


# ---------------------------------------------------------------
# Feature Simplifications
# ---------------------------------------------------------------

set disable(intranet-bug-tracker) 0
set disable(intranet-chat) 0
set disable(intranet-big-brother) 0
set disable(intranet-expenses) 0
set disable(intranet-filestorage) 0
set disable(intranet-forum) 0
set disable(intranet-freelance) 0
set disable(intranet-freelance-invoices) 0
set disable(intranet-ganttproject) 0
set disable(intranet-search-pg) 0
set disable(intranet-search-pg-files) 0
set disable(intranet-simple_survey) 0
set disable(intranet-sysconfig) 0
set disable(intranet-timesheet2) 0
set disable(intranet-timesheet2-invoices) 0
set disable(intranet-timesheet2-tasks) 0
set disable(intranet-timesheet2-task-popup) 1
set disable(intranet-translation) 0
set disable(intranet-trans-rfq) 0
set disable(intranet-trans-quality) 0
set disable(intranet-wiki) 0
set disable(intranet-workflow) 0

switch $features {
    minimum {
	set disable(intranet-bug-tracker) 1
	set disable(intranet-chat) 1
	set disable(intranet-big-brother) 1
	set disable(intranet-expenses) 1
	set disable(intranet-forum) 1
	set disable(intranet-filestorage) 1
	set disable(intranet-freelance) 1
	set disable(intranet-freelance-invoices) 1
	set disable(intranet-ganttproject) 1
	set disable(intranet-simple_survey) 1
	set disable(intranet-timesheet2) 1
	set disable(intranet-timesheet2-invoices) 1
	set disable(intranet-timesheet2-tasks) 1
	set disable(intranet-timesheet2-task-popup) 1
	set disable(intranet-trans-rfq) 1
	set disable(intranet-trans-quality) 1
	set disable(intranet-wiki) 1
	set disable(intranet-workflow) 1

        db_dml fincomp "update im_component_plugins set enabled_p = 'f' where plugin_name = 'Project Finance Summary Component'"
	
	parameter::set_from_package_key -package_key "intranet-core" -parameter "EnableCloneProjectLinkP" -value "0"
	parameter::set_from_package_key -package_key "intranet-core" -parameter "EnableExecutionProjectLinkP" -value "0"
	parameter::set_from_package_key -package_key "intranet-core" -parameter "EnableNestedProjectsP" -value "0"
	parameter::set_from_package_key -package_key "intranet-core" -parameter "EnableNewFromTemplateLinkP" -value "0"

    }
    frequently_used {
	set disable(intranet-bug-tracker) 1
	set disable(intranet-chat) 1
	set disable(intranet-big-brother) 1
	set disable(intranet-forum) 1
	set disable(intranet-ganttproject) 1
	set disable(intranet-simple_survey) 1
	set disable(intranet-trans-rfq) 1
	set disable(intranet-wiki) 1
    }
    default { 
	set disable(intranet-big-brother) 1
    }
}



# ---------------------------------------------------------------
# Disable Modules

foreach package [array names disable] {
    
    set dis $disable($package)
    if {$dis} {
	ns_write "<h2>Disabling '$package'</h2>\n"
	
	ns_write "<li>Disabling '$package' Menus ... "
	catch {db_dml disable_trans_cats "
		update	im_menus
		set	enabled_p = 'f'
		where	package_name = :package
        "}  err
	ns_write "done<br><pre>$err</pre>\n"

	ns_write "<li>Disabling '$package' Components ... "
	catch {db_dml disable_trans_cats "
		update	im_component_plugins
		set	enabled_p = 'f'
		where	package_name = :package
        "}  err
	ns_write "done<br><pre>$err</pre>\n"
    }
}


# ---------------------------------------------------------------
# Disabling components
# ---------------------------------------------------------------

ns_write "<h2>Disabling 'intranet-sysconfig' Components</h2>\n"

ns_write "<li>Disabling 'intranet-sysconfig' Components ... "
catch {db_dml disable_trans_cats "
		update	im_component_plugins
		set	enabled_p = 'f'
		where	package_name = 'intranet-sysconfig'
"}  err
ns_write "done<br><pre>$err</pre>\n"



# ---------------------------------------------------------------
# Disable the 100 - Task category
# This disable is overwritten by the enable all above
# ---------------------------------------------------------------

db_dml disable_task_project_type "update im_categories set enabled_p = 'f' where category_id = 100"



# ---------------------------------------------------------------
# Install TSearch2
#
# TSearch2 installation depends on the PostgreSQL version:
#	7.4.x - No install (crashes Backup/Restore)
#	8.0.1 - tsearch2.801.tcl
#	8.0.8 - tsearch2.808.tcl
# ---------------------------------------------------------------

set tsearch_installed_p [db_string tsearch_exists "select count(*) from pg_class where relname = lower('pg_ts_cfg') and relkind = 'r'"]

set search_pg_installed_p [db_string search_pg "
	select	count(*) 
	from	apm_package_versions 
	where
		enabled_p = 't' 
		and package_key like 'intranet-search-pg'
"]

set search_pg_installed_p 1

if {!$search_pg_installed_p} {

    ns_write "<h2>Installing Full-Text Search</h2>\n"


    set psql_version "0.0.0"
    set err_msg ""
    if {[catch {
	set psql_string [exec psql --version] 
	regexp {([0-9]\.[0-9]\.[0-9])} $psql_string match psql_version
    } err_msg]} {
	ns_write "<li>Error getting PostgreSQL version number: <pre>'$err_msg'</pre> \n"
    } else {
	ns_write "<li>Found psql version '$psql_version'\n"
    }


    set pageroot [ns_info pageroot]
    set serverroot [join [lrange [split $pageroot "/"] 0 end-1] "/"]
    set search_sql_dir "$serverroot/packages/intranet-search-pg/sql/postgresql"
    
    ns_write "<li>Found search_sql_dir: $search_sql_dir\n"
    
    set install_package_p 1
    if {!$tsearch_installed_p} {
	switch $psql_version {
	    "8.0.1" - "8.0.8" {
		set sql_file "$search_sql_dir/tsearch2.$psql_version.sql"
		set result ""
		ns_write "<li>Sourcing $sql_file ...\n"
		catch { set result [db_source_sql_file -callback apm_ns_write_callback $sql_file] } err
		ns_write "done<br><pre>$err</pre>\n"
		ns_write "<li>Result: <br><pre>$result</pre>\n"
	    }
	    default {
		set install_package_p 0
		ns_write "<li>PostgreSQL Version $psql_version not supported.\n"
	    }
	}
    } else {
	ns_write "<li>TSearch2 already installed - no action taken.\n"
    }
    
    # Set the default configuration for TSearch2 (stemming etc...)
    if {$install_package_p} {
	
	ns_write "<li>Set the default locale for TSearch2  ...\n"
	set lc_messages [db_string lc_messages "show lc_messages"]
	db_dml pg_ts_cfg "update pg_ts_cfg set locale=:lc_messages where ts_name='default'"
	ns_write "done\n"
	
    }
    
    
    # Install the package
    if {$install_package_p} {
	set enable_p 1
	set package_path "$serverroot/packages/intranet-search-pg"
	set callback "apm_ns_write_callback"
	set data_model_files [list [list "sql/postgresql/intranet-search-pg-create.sql" data_model_create "intranet-search-pg"]]
	set mount_path "intranet-search"
	set spec_file "$serverroot/packages/intranet-search-pg/intranet-search-pg.info"
	if {[catch {
	    set version_id [apm_package_install \
				-enable=$enable_p \
				-package_path $package_path \
				-callback $callback \
				-load_data_model \
				-data_model_files $data_model_files \
				-mount_path $mount_path \
				$spec_file \
            ]
	} err_msg]} {
	    ns_write "<li>Error installing package: <pre>'$err_msg'</pre> \n"
	}
    }

}

# ---------------------------------------------------------------
# Finish off page
# ---------------------------------------------------------------


ns_write "<p>&nbsp;</p>\n"
ns_write "<blockquote><b>Please return now to the <a href='/intranet/'>Home Page</a></b>.</blockquote>\n"
ns_write "<p>&nbsp;</p>\n"




# Remove all permission related entries in the system cache
util_memoize_flush_regexp ".*"
im_permission_flush


ns_write "[im_footer]\n"


