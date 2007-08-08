-- /packages/intranet-confdb/sql/postgres/intranet-confdb-create.sql
--
-- Copyright (c) 2007 ]project-open[
-- All rights reserved.
--
-- @author	frank.bergmann@project-open.com

-- ConfigurationItems
--
-- Each project can have any number of sub-confdb

select acs_object_type__create_type (
	'im_conf_item',			-- object_type
	'Configuration Item',		-- pretty_name
	'Configuration Items',		-- pretty_plural
	'im_biz_object',		-- supertype
	'im_conf_items',		-- table_name
	'conf_item_id',			-- id_column
	'intranet-confdb',	-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_conf_item__name'		-- name_method
);

create table im_conf_items (
	conf_item_id		integer
				constraint im_conf_items_pk
				primary key
				constraint im_conf_item_prj_fk
				references acs_objects,
	conf_item_name		varchar(1000) not null,
	conf_item_nr		varchar(500) not null,

	-- Unique code for label
	conf_item_code		varchar(500),

	-- Single "main" parent.
	conf_item_parent_id	integer
				constraint im_conf_items_parent_fk
				references im_conf_items,

	-- Cache for CI hierarchy
	tree_sortkey		varbit,
	max_child_sortkey	varbit,

	-- Where is the CI located in the company hierarchy?
	conf_item_cost_center_id integer
				constraint im_conf_items_cost_center_fk
				references im_cost_centers,

	-- Is there an owner? Takes the owner from parent if null.
	conf_item_owner_id	integer
				constraint im_conf_items_owner_fk
				references persons,

	-- Type - deeply nested...
	conf_item_type_id	integer not null
				constraint im_conf_items_type_fk
				references im_categories,
	conf_item_status_id	integer not null
				constraint im_conf_items_status_fk
				references im_categories,
	sort_order		integer,
	description		text,
	note			text
);


create index im_conf_item_parent_id_idx on im_conf_items(conf_item_parent_id);
create index im_conf_item_treesort_idx on im_conf_items(tree_sortkey);
create index im_conf_item_status_id_idx on im_conf_items(conf_item_status_id);
create index im_conf_item_type_id_idx on im_conf_items(conf_item_type_id);
create unique index im_conf_item_conf_item_code_idx on im_conf_items(conf_item_code);

-- Dont allow the same name for the same parent
alter table im_conf_items add
	constraint im_conf_items_name_un
	unique(conf_item_name, conf_item_parent_id);

-- Dont allow the same conf_item_nr  for the same parent
alter table im_conf_items add
	constraint im_conf_items_nr_un
	unique(conf_item_nr, conf_item_parent_id);



-- This is the sortkey code
--
create or replace function im_conf_item_insert_tr ()
returns trigger as '
declare
	v_max_child_sortkey	im_conf_items.max_child_sortkey%TYPE;
	v_parent_sortkey	im_conf_items.tree_sortkey%TYPE;
begin
	IF new.conf_item_parent_id is null THEN
		new.tree_sortkey := int_to_tree_key(new.conf_item_id+1000);
	ELSE
		select tree_sortkey, tree_increment_key(max_child_sortkey)
		into v_parent_sortkey, v_max_child_sortkey
		from im_conf_items
		where conf_item_id = new.conf_item_parent_id
		for update;

		update im_conf_items
		set max_child_sortkey = v_max_child_sortkey
		where conf_item_id = new.conf_item_parent_id;

		new.tree_sortkey := v_parent_sortkey || v_max_child_sortkey;
	END IF;
	new.max_child_sortkey := null;
	return new;
end;' language 'plpgsql';

create trigger im_conf_item_insert_tr
before insert on im_conf_items
for each row
execute procedure im_conf_item_insert_tr();



create or replace function im_conf_items_update_tr () 
returns trigger as '
declare
	v_parent_sk	varbit default null;
	v_max_child_sortkey	varbit;
	v_old_parent_length	integer;
begin
	IF new.conf_item_id = old.conf_item_id
		and ((new.conf_item_parent_id = old.conf_item_parent_id)
		or (new.conf_item_parent_id is null and old.conf_item_parent_id is null)) THEN
		return new;
	END IF;

	-- the tree sortkey is going to change so get the new one and update it and all its
	-- children to have the new prefix...
	v_old_parent_length := length(new.tree_sortkey) + 1;

	IF new.conf_item_parent_id is null THEN
		v_parent_sk := int_to_tree_key(new.conf_item_id+1000);
	ELSE
		SELECT tree_sortkey, tree_increment_key(max_child_sortkey)
		INTO v_parent_sk, v_max_child_sortkey
		FROM im_conf_items
		WHERE conf_item_id = new.conf_item_parent_id
		FOR UPDATE;

		UPDATE im_conf_items
		SET max_child_sortkey = v_max_child_sortkey
		WHERE conf_item_id = new.conf_item_parent_id;

		v_parent_sk := v_parent_sk || v_max_child_sortkey;
	END IF;

	UPDATE im_conf_items
	SET tree_sortkey = v_parent_sk || substring(tree_sortkey, v_old_parent_length)
	WHERE tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);

	return new;
end;' language 'plpgsql';

create trigger im_conf_items_update_tr after update
on im_conf_items
for each row
execute procedure im_conf_items_update_tr ();




-- ------------------------------------------------------------
-- ConfItem Package
-- ------------------------------------------------------------

create or replace function im_conf_item__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, integer
) returns integer as '
DECLARE
	p_conf_item_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date		alias for $3;
	p_creation_user		alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_conf_item_name	alias for $7;
	p_conf_item_nr		alias for $8;
	p_conf_item_parent_id	alias for $9;
	p_conf_item_type_id	alias for $10;
	p_conf_item_status_id	alias for $11;

	v_conf_item_id	integer;
BEGIN
	v_conf_item_id := acs_object__new (
		p_conf_item_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);
	insert into im_conf_items (
		conf_item_id, conf_item_name, conf_item_nr,
		conf_item_parent_id, conf_item_type_id, conf_item_status_id
	) values (
		v_conf_item_id, p_conf_item_name, p_conf_item_nr,
		p_conf_item_parent_id, p_conf_item_type_id, p_conf_item_status_id
	);
	return v_conf_item_id;
end;' language 'plpgsql';

create or replace function im_conf_item__delete (integer) returns integer as '
DECLARE
	v_conf_item_id		alias for $1;
BEGIN
	-- Erase the im_conf_items item associated with the id
	delete from 	im_conf_items
	where		conf_item_id = v_conf_item_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_conf_item_id;

	PERFORM	acs_object__delete(v_conf_item_id);

	return 0;
end;' language 'plpgsql';

create or replace function im_conf_item__name (integer) returns varchar as '
DECLARE
	v_conf_item_id	alias for $1;
	v_name		varchar;
BEGIN
	select	conf_item_name
	into	v_name
	from	im_conf_items
	where	conf_item_id = v_conf_item_id;

	return v_name;
end;' language 'plpgsql';


-- Helper functions to make our queries easier to read
create or replace function im_conf_item_name_from_id (integer)
returns varchar as '
DECLARE
	p_conf_item_id		alias for $1;
	v_conf_item_name	text;
BEGIN
	select conf_item_name
	into v_conf_item_name
	from im_conf_items
	where conf_item_id = p_conf_item_id;

	return v_conf_item_name;
end;' language 'plpgsql';


create or replace function im_conf_item_nr_from_id (integer)
returns varchar as '
DECLARE
	p_conf_item_id	alias for $1;
	v_name		text;
BEGIN
	select conf_item_nr
	into v_name
	from im_conf_items
	where conf_item_id = p_conf_item_id;

	return v_name;
end;' language 'plpgsql';



-- ------------------------------------------------------------
-- Categories
-- ------------------------------------------------------------

-- 11700-11799	Intranet Conf Item Status
-- 11800-11999	Intranet Conf Item Type


-- ---------------------------------------------------------
-- Conf Item Status

insert into im_categories(category_id, category, category_type)
values (11700, 'Active', 'Intranet Conf Item Status');

insert into im_categories(category_id, category, category_type)
values (11702, 'Preactive', 'Intranet Conf Item Status');

insert into im_categories(category_id, category, category_type)
values (11716, 'Archived', 'Intranet Conf Item Status');

insert into im_categories(category_id, category, category_type)
values (11718, 'Zombie', 'Intranet Conf Item Status');

insert into im_categories(category_id, category, category_type)
values (11720, 'Inactive', 'Intranet Conf Item Status');




create or replace view im_conf_item_status as
select category_id as conf_item_status_id, category as conf_item_status
from im_categories
where category_type = 'Intranet Conf Item Status';



-- ---------------------------------------------------------
-- Conf Item Type

-- Top-level "ontology" of CIs
insert into im_categories(category_id, category, category_type, enabled_p)
values (11800, 'Hardware', 'Intranet Conf Item Type', 'f');
insert into im_categories(category_id, category, category_type, enabled_p)
values (11802, 'Software', 'Intranet Conf Item Type', 't');
insert into im_categories(category_id, category, category_type, enabled_p)
values (11804, 'Process', 'Intranet Conf Item Type', 'f');
insert into im_categories(category_id, category, category_type, enabled_p)
values (11806, 'License', 'Intranet Conf Item Type', 'f');
insert into im_categories(category_id, category, category_type, enabled_p)
values (11808, 'Specs', 'Intranet Conf Item Type', 'f');
insert into im_categories(category_id, category, category_type, enabled_p)
-- reserved to 11819


values (11980, 'Host Table', 'Intranet Conf Item Type', 't');
insert into im_categories(category_id, category, category_type, enabled_p)
values (11982, 'Host Program', 'Intranet Conf Item Type', 't');
insert into im_categories(category_id, category, category_type, enabled_p)
values (11984, 'Host Screen', 'Intranet Conf Item Type', 't');


create or replace view im_conf_item_type as
select category_id as conf_item_type_id, category as conf_item_type
from im_categories
where category_type = 'Intranet Conf Item Type';


-----------------------------------------------------------
-- Permissions & Privileges
-----------------------------------------------------------

select acs_privilege__create_privilege('view_conf_items','View Conf Items','');
select acs_privilege__view_child('admin', 'view_conf_items');

select acs_privilege__create_privilege('view_conf_items_all','View all Conf Items','');
select acs_privilege__add_child('admin', 'view_conf_items_all');

select acs_privilege__create_privilege('add_conf_items','Add new Conf Items','');
select acs_privilege__add_child('admin', 'add_conf_items');


select im_priv_create('view_conf_items', 'P/O Admins');
select im_priv_create('view_conf_items', 'Senior Managers');
select im_priv_create('view_conf_items', 'Project Managers');
select im_priv_create('view_conf_items', 'Employees');

select im_priv_create('view_conf_items_all', 'P/O Admins');
select im_priv_create('view_conf_items_all', 'Senior Managers');
select im_priv_create('view_conf_items_all', 'Project Managers');
select im_priv_create('view_conf_items_all', 'Employees');

select im_priv_create('add_conf_items', 'P/O Admins');
select im_priv_create('add_conf_items', 'Senior Managers');
select im_priv_create('add_conf_items', 'Project Managers');
select im_priv_create('add_conf_items', 'Employees');



--------------------------------------------------------------
-- Business Object Roles

-- Setup the list of roles that a user can take with
-- respect to a company:
--      Full Member (1300) and
--      ToDo: Rename: Key Account Manager (1302)
--
insert into im_biz_object_role_map values ('im_conf_item',85,1300);
-- insert into im_biz_object_role_map values ('im_company',85,1302);



-------------------------------------------------------------
-- Business Object URLs

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_conf_item','view','/intranet-confdb/new?form_mode=display&conf_item_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_conf_item','edit','/intranet-configuration_items/new?form_mode=edit&conf_item_id=');




-----------------------------------------------------------
-- Relationship with projects
-----------------------------------------------------------



-- --------------------------------------------------------
-- Conf Item - Relationship between projects and Conf Items
--
-- This relationship connects Projects with "Conf Item"s


create table im_conf_item_project_rels (
	rel_id			integer
				constraint im_conf_item_project_rels_rel_fk
				references acs_rels (rel_id)
				constraint im_conf_item_project_rels_rel_pk
				primary key,
	sort_order		integer
);

select acs_rel_type__create_type (
   'im_conf_item_project_rel',	-- relationship (object) name
   'Conf Item Project Rel',	-- pretty name
   'Conf Item Project Rels',	-- pretty plural
   'relationship',		-- supertype
   'im_conf_item_project_rels',	-- table_name
   'rel_id',			-- id_column
   'intranet-conf-item-rel',	-- package_name
   'im_project',		-- object_type_one
   'member',			-- role_one
    0,				-- min_n_rels_one
    null,			-- max_n_rels_one
   'im_conf_item',		-- object_type_two
   'member',			-- role_two
   0,				-- min_n_rels_two
   null				-- max_n_rels_two
);


create or replace function im_conf_item_project_rel__new (
integer, varchar, integer, integer, integer, integer, varchar, integer)
returns integer as '
DECLARE
	p_rel_id		alias for $1;	-- null
	p_rel_type		alias for $2;	-- im_conf_item_project_rel
	p_project_id		alias for $3;
	p_conf_item_id		alias for $4;
	p_context_id		alias for $5;
	p_creation_user		alias for $6;	-- null
	p_creation_ip		alias for $7;	-- null
	p_sort_order		alias for $8;

	v_rel_id	integer;
BEGIN
	v_rel_id := acs_rel__new (
		p_rel_id,
		p_rel_type,
		p_project_id,
		p_conf_item_id,
		p_context_id,
		p_creation_user,
		p_creation_ip
	);

	insert into im_conf_item_project_rels (
	       rel_id, sort_order
	) values (
	       v_rel_id, p_sort_order
	);

	return v_rel_id;
end;' language 'plpgsql';


create or replace function im_conf_item_project_rel__delete (integer)
returns integer as '
DECLARE
	p_rel_id	alias for $1;
BEGIN
	delete	from im_conf_item_project_rels
	where	rel_id = p_rel_id;

	PERFORM acs_rel__delete(p_rel_id);
	return 0;
end;' language 'plpgsql';


create or replace function im_conf_item_project_rel__delete (integer, integer)
returns integer as '
DECLARE
        p_project_id	alias for $1;
	p_conf_item_id	alias for $2;

	v_rel_id	integer;
BEGIN
	select	rel_id into v_rel_id
	from	acs_rels
	where	object_id_one = p_project_id
		and object_id_two = p_conf_item_id;

	PERFORM im_conf_item_project_rel__delete(v_rel_id);
	return 0;
end;' language 'plpgsql';







-----------------------------------------------------------
-- Components & Menus
-----------------------------------------------------------

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Configuration Items',	-- plugin_name
	'intranet-confdb',	-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	190,				-- sort_order
	'im_conf_item_list_component -object_id $project_id'	-- component_tcl
);

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'User Configuration Items',	-- plugin_name
	'intranet-confdb',	-- package_name
	'right',			-- location
	'/intranet/users/view',		-- page_url
	null,				-- view_name
	190,				-- sort_order
	'im_conf_item_list_component -object_id $user_id'	-- component_tcl
);



-----------------------------------------------------------
-- Menu for Conf Items
--
-- Create a menu item and set some default permissions
-- for various groups who whould be able to see the menu.


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_companies		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
	v_reg_users		integer;
BEGIN
	-- Get some group IDs
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_companies from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';
	select group_id into v_reg_users from groups where group_name = ''Registered Users'';

	-- Determine the main menu. "Label" is used to identify menus.
	select menu_id into v_main_menu 
	from im_menus where label=''main'';

	-- Create the menu.
	v_menu := im_menu__new (
		null,			-- p_menu_id
		''acs_object'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-confdb'',	-- package_name
		''conf_items'',		-- label
		''Conf Items'',		-- name
		''/intranet-confdb/index'',   -- url
		95,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	-- Grant read permissions to most of the system
	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





-----------------------------------------------------------
-- Member component for CIs
-----------------------------------------------------------

SELECT  im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
	'Conf Item Members',		-- plugin_name
	'intranet',			-- package_name
	'right',			-- location
	'/intranet-confdb/new',	-- page_url
	null,				-- view_name	
	20,				-- sort_order
	'im_group_member_component $conf_item_id $current_user_id $user_admin_p $return_url "" "" 1'
);

