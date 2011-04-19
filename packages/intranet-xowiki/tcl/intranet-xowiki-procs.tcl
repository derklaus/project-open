# intranet-xowiki-procs.tcl
ad_library {
    Procedures to support intranet-xowiki package

    @author Iuri Sampaio (iuri.sampaio@gmail.com)
    @creation-date 2011-04-18
}

namespace eval intranet_xowiki {}

# ----------------------------------------------------------------------
# Xowiki View Component
# ---------------------------------------------------------------------
ad_proc -public im_xowiki_view_component {
    {-object_id:required}
    {-return_url ""}
} {

    @author iuri sampaio (iuri.sampaio@gmail.com)
    @creation-date 2011-04-18
} {

    set project_id $object_id
    set project_name [db_exec_plsql select_project_name "select im_name_from_id($object_id)"]

    set xowiki_node_id [db_string select_xowiki_instance {
	SELECT sn.node_id FROM apm_packages ap, site_nodes sn WHERE ap.package_key= 'xowiki' AND ap.package_id = sn.object_id and sn.name = 'xowiki'
    } -default 0]
    
    if {[exists_and_not_null xowiki_node_id]} {
	set xowki_project_p [apm_package_id_from_key $project_id]
	
	if {![exists_and_not_null xowiki_project_p]} {
	    
	    site_node::instantiate_and_mount -parent_node_id $xowiki_node_id \
		-node_name $project_id -package_key "xowiki" \
		-package_name "XoWIKI $project_name"
	}
	
	set params [list [list base_url "/intranet-xowiki/"] [list return_url $return_url]]
	
	set result [ad_parse_template -params $params "/packages/intranet-xowiki/lib/page"]
	return [string trim $result]
    }
}