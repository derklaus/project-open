-- upgrade-3.4.0.7.6-3.4.0.7.7.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.7.6-3.4.0.7.7.sql','');



-- BrowserWarning Component on HomePage
SELECT  im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Browser Warning',		-- plugin_name
	'intranet-core',		-- package_name
	'top',				-- location
	'/intranet/index',		-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_browser_warning_component'	-- component_tcl
);


SELECT im_grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Browser Warning'),
	(select group_id from groups where group_name = 'Registered Users'), 
	'read'
);

