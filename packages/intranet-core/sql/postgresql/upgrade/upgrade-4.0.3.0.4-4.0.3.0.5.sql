-- 
-- packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.3.0.4-4.0.3.0.5.sql
-- 
-- Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2012-03-02
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.3.0.4-4.0.3.0.5.sql','');

-- Fix the acs_attributes missing table_name for im_project object_type
create or replace function inline_0() 
returns integer as '
BEGIN
       update acs_attributes set table_name = ''im_projects'' 
       where object_type = ''im_project'' and table_name is null;

       return 0;
END;' language 'plpgsql';

SELECT inline_0();

DROP FUNCTION inline_0();


-- Project Hierarchy Component.
-- Update sort order
CREATE OR REPLACE FUNCTION inline_0 () 
RETURNS integer AS '
DECLARE
	v_component_id integer;
BEGIN
	SELECT plugin_id INTO v_component_id 
	FROM im_component_plugins 
	WHERE plugin_name = ''Project Hierarchy''
	AND package_name = ''intranet-core''
	AND page_url = ''/intranet/projects/view'';

	UPDATE im_component_plugins 
	SET location = ''right'', menu_sort_order = 0
	WHERE plugin_id = v_component_id;

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();



create or replace function im_dynfield_widget__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, varchar, integer, varchar, varchar, 
	varchar, varchar, varchar
) returns integer as '
DECLARE
	p_widget_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date 	alias for $3;
	p_creation_user 	alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_widget_name		alias for $7;
	p_pretty_name		alias for $8;
	p_pretty_plural		alias for $9;
	p_storage_type_id	alias for $10;
	p_acs_datatype		alias for $11;
	p_widget		alias for $12;
	p_sql_datatype		alias for $13;
	p_parameters		alias for $14;
	p_deref_plpgsql_function alias for $15;

	v_widget_id		integer;
BEGIN
	select widget_id into v_widget_id from im_dynfield_widgets
	where widget_name = p_widget_name;
	if v_widget_id is not null then return v_widget_id; end if;

	v_widget_id := acs_object__new (
		p_widget_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_dynfield_widgets (
		widget_id, widget_name, pretty_name, pretty_plural,
		storage_type_id, acs_datatype, widget, sql_datatype, parameters, deref_plpgsql_function
	) values (
		v_widget_id, p_widget_name, p_pretty_name, p_pretty_plural,
		p_storage_type_id, p_acs_datatype, p_widget, p_sql_datatype, p_parameters, p_deref_plpgsql_function
	);
	return v_widget_id;
end;' language 'plpgsql';

create or replace function im_dynfield_widget__del (integer) returns integer as '
DECLARE
	p_widget_id		alias for $1;
BEGIN
	-- Erase the im_dynfield_widgets item associated with the id
	delete from im_dynfield_widgets
	where widget_id = p_widget_id;

	-- Erase all the privileges
	delete from acs_permissions
	where object_id = p_widget_id;

	PERFORM acs_object__delete(p_widget_id);
	return 0;
end;' language 'plpgsql';

SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'customers',		-- widget_name
		'#intranet-core.Customer#',	-- pretty_name
		'#intranet-core.Customers#',	-- pretty_plural
		10007,			-- storage_type_id
		'integer',		-- acs_datatype
		'generic_tcl',		-- widget
		'integer',		-- sql_datatype
		'{custom {tcl {im_company_options -include_empty_p 0 -status "Active or Potential" -type "CustOrIntl"} switch_p 1}}', 
		'im_name_from_id'
);


SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'project_leads',		-- widget_name
		'#intranet-core.Project_Manager#',	-- pretty_name
		'#intranet-core.Project_Managers#',	-- pretty_plural
		10007,			-- storage_type_id
		'integer',		-- acs_datatype
		'generic_tcl',		-- widget
		'integer',		-- sql_datatype
		'{custom {tcl {im_project_manager_options -include_empty 0} switch_p 1}}', -- -
		'im_name_from_id'
);

SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'project_parent_options',		-- widget_name
		'Parent Project List',	-- pretty_name
		'Parent Project List',	-- pretty_plural
		10007,			-- storage_type_id
		'integer',		-- acs_datatype
		'generic_tcl',		-- widget
		'integer',		-- sql_datatype
		'{custom {tcl {im_project_options -exclude_subprojects_p 0 -exclude_status_id [im_project_status_closed] -project_id $super_project_id} switch_p 1 global_var super_project_id}}', -- -
		'im_name_from_id'
);

SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'timestamp',		-- widget_name
		'#intranet-core.Timestamp#',	-- pretty_name
		'#intranet-core.Timestamps#',	-- pretty_plural
		10007,			-- storage_type_id
		'date',		-- acs_datatype
		'date',		-- widget
		'date',		-- sql_datatype
		'{format "YYYY-MM-DD HH24:MM"}', 
		'im_name_from_id'
);

SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'on_track_status',		-- widget_name
		'#intranet-core.On_Track_Status#',	-- pretty_name
		'#intranet-core.On_Track_Status#',	-- pretty_plural
		10007,			-- storage_type_id
		'integer',		-- acs_datatype
		'im_category_tree',		-- widget
		'integer',		-- sql_datatype
		'{custom {category_type "Intranet Project On Track Status"}}', 
		'im_name_from_id'
);

SELECT im_dynfield_widget__new (
		null,			-- widget_id
		'im_dynfield_widget',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		'percent',		-- widget_name
		'#intranet-core.percent_complete#',	-- pretty_name
		'#intranet-core.percent_complete#',	-- pretty_plural
		10007,			-- storage_type_id
		'float',		-- acs_datatype
		'text',		-- widget
		'float',		-- sql_datatype
		'', 
		'im_percent_from_number'
);


-- project_name
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_name'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''textbox_medium'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_name'',			-- column_name
		 ''#intranet-core.Project_Name#'',	-- pretty_name
		 ''textbox_medium'',			-- widget_name
		 ''string'',				-- acs_datatype
		 ''t'',					-- required_p   
		 1,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''Please enter any suitable name for the project. The name must be unique.'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

-- project_nr
CREATE OR REPLACE FUNCTION inline_1 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_nr'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''textbox_medium'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_nr'',			-- column_name
		 ''#intranet-core.Project_Nr#'',	-- pretty_name
		 ''textbox_medium'',			-- widget_name
		 ''string'',				-- acs_datatype
		 ''t'',					-- required_p   
		 2,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''A project number is composed by 4 digits for the year plus 4 digits for current identification'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_1 ();
DROP FUNCTION inline_1 ();


-- parent_id
CREATE OR REPLACE FUNCTION inline_2 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''parent_id'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''project_parent_options'',		-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''parent_id'',				-- column_name
		 ''#intranet-core.Parent_Project#'',	-- pretty_name
		 ''project_parent_options'',		-- widget_name
		 ''integer'',				-- acs_datatype
		 ''f'',					-- required_p   
		 3,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''Do you want to create a subproject (a project that is part of an other project)? Leave the field blank (-- Please Select --) if you are unsure.'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_2 ();
DROP FUNCTION inline_2 ();

-- project_path
CREATE OR REPLACE FUNCTION inline_3 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_path'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''textbox_medium'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_path'',			-- column_name
		 ''#intranet-core.Project_Path#'',	-- pretty_name
		 ''textbox_medium'',			-- widget_name
		 ''string'',				-- acs_datatype
		 ''t'',					-- required_p   
		 4,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''An optional full path to the project filestorage'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_3 ();
DROP FUNCTION inline_3 ();



-- company_id
CREATE OR REPLACE FUNCTION inline_4 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''company_id'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''customers'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''company_id'',			-- column_name
		 ''#intranet-core.Company#'',		-- pretty_name
		 ''customers'',				-- widget_name
		 ''integer'',				-- acs_datatype
		 ''t'',					-- required_p   
		 5,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''There is a difference between &quot;Paying Client&quot; and &quot;Final Client&quot;. Here we want to know from whom we are going to receive the money...'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_4 ();
DROP FUNCTION inline_4 ();

-- project_lead_id
CREATE OR REPLACE FUNCTION inline_5 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_lead_id'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''project_leads'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_lead_id'',			-- column_name
		 ''#intranet-core.Project_Manager#'',	-- pretty_name
		 ''project_leads'',			-- widget_name
		 ''integer'',				-- acs_datatype
		 ''t'',					-- required_p   
		 6,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_5 ();
DROP FUNCTION inline_5 ();


-- project_type_id
CREATE OR REPLACE FUNCTION inline_6 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_type_id'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''project_type'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_type_id'',			-- column_name
		 ''#intranet-core.Project_Type#'',	-- pretty_name
		 ''project_type'',			-- widget_name
		 ''integer'',				-- acs_datatype
		 ''t'',					-- required_p   
		 7,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''General type of project. This allows us to create a suitable folder structure.'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_6 ();
DROP FUNCTION inline_6 ();


-- project_status_id
CREATE OR REPLACE FUNCTION inline_7 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_status_id'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''project_status'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_status_id'',			-- column_name
		 ''#intranet-core.Project_Status#'',	-- pretty_name
		 ''project_status'',			-- widget_name
		 ''integer'',				-- acs_datatype
		 ''t'',					-- required_p   
		 8,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''In Process: Work is starting immediately, Potential Project: May become a project later, Not Started Yet: We are waiting to start working on it, Finished: Finished already...'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_7 ();
DROP FUNCTION inline_7 ();

-- start_date
CREATE OR REPLACE FUNCTION inline_8 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''start_date'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''date'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''start_date'',			-- column_name
		 ''#intranet-core.Start_Date#'',	-- pretty_name
		 ''date'',				-- widget_name
		 ''date'',				-- acs_datatype
		 ''t'',					-- required_p   
		 9,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_8 ();
DROP FUNCTION inline_8 ();

-- Add javascript calendar buton on date widget
UPDATE im_dynfield_widgets set parameters = '{format "YYYY-MM-DD"} {after_html {<input type="button" style="height:23px; width:23px; background: url(''/resources/acs-templating/calendar.gif'');" onclick ="return showCalendarWithDateWidget(''$attribute_name'', ''y-m-d'');" ></b>}}' where widget_name = 'date';

-- end_date
CREATE OR REPLACE FUNCTION inline_9 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''end_date'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''date'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''end_date'',				-- column_name
		 ''#intranet-core.End_Date#'',		-- pretty_name
		 ''timestamp'',				-- widget_name
		 ''timestamp'',				-- acs_datatype
		 ''t'',					-- required_p   
		 10,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_9 ();
DROP FUNCTION inline_9 ();


-- on_track_status_id
CREATE OR REPLACE FUNCTION inline_10 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''on_track_status_id'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''on_track_status'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''on_track_status_id'',		-- column_name
		 ''#intranet-core.On_Track_Status#'',	-- pretty_name
		 ''on_track_status'',			-- widget_name
		 ''integer'',				-- acs_datatype
		 ''t'',					-- required_p   
		 11,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''Is the project going to be in time and budget (green), does it need attention (yellow) or is it doomed (red)?'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_10 ();
DROP FUNCTION inline_10 ();

-- percent_completed
CREATE OR REPLACE FUNCTION inline_11 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''percent_completed'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''numeric'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''percent_completed'',			-- column_name
		 ''#intranet-core.Percent_Completed#'',	-- pretty_name
		 ''numeric'',				-- widget_name
		 ''float'',				-- acs_datatype
		 ''f'',					-- required_p   
		 12,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_11 ();
DROP FUNCTION inline_11 ();


-- project_budget_hours
CREATE OR REPLACE FUNCTION inline_12 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_budget_hours'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''numeric'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',				-- object_type
		 ''project_budget_hours'',		   	-- column_name
		 ''#intranet-core.Project_Budget_Hours#'', 	-- pretty_name
		 ''numeric'',					-- widget_name
		 ''float'',					-- acs_datatype
		 ''f'',						-- required_p   
		 13,					   	-- pos y
		 ''f'',						-- also_hard_coded
		 ''im_projects''				-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''How many hours can be logged on this project (both internal and external resource)?'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_12 ();
DROP FUNCTION inline_12 ();


-- project_budget
CREATE OR REPLACE FUNCTION inline_13 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_budget'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''numeric'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''project_budget'',			-- column_name
		 ''#intranet-core.Project_Budget#'',	-- pretty_name
		 ''numeric'',				-- widget_name
		 ''float'',				-- acs_datatype
		 ''f'',					-- required_p   
		 14,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''What is the financial budget of this project? Includes both external (invoices) and internal (timesheet) costs.'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_13 ();
DROP FUNCTION inline_13 ();

--project_budget_currency
CREATE OR REPLACE FUNCTION inline_14 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''project_budget_currency'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''currencies'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',				-- object_type
		 ''project_budget_currency'',			-- column_name
		 ''#intranet-core.Project_Budget_Currency#'',	-- pretty_name
		 ''currencies'',				-- widget_name
		 ''string'',					-- acs_datatype
		 ''f'',						-- required_p   
		 15,						-- pos y
		 ''f'',						-- also_hard_coded
		 ''im_projects''				-- table_name
	  );
	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_14 ();
DROP FUNCTION inline_14 ();

-- company_project_nr
CREATE OR REPLACE FUNCTION inline_15 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''company_project_nr'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''textbox_medium'',			-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',				-- object_type
		 ''company_project_nr'',			-- column_name
		 ''#intranet-core.Company_Project_Nr#'',	-- pretty_name
		 ''textbox_medium'',				-- widget_name
		 ''string'',					-- acs_datatype
		 ''f'',						-- required_p   
		 16,						-- pos y
		 ''f'',						-- also_hard_coded
		 ''im_projects''				-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',''The customers reference to this project. This number will appear in invoices of this project.'',null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_15 ();
DROP FUNCTION inline_15 ();

-- description
CREATE OR REPLACE FUNCTION inline_16 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN


	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_project'' AND attribute_name = ''description'';
	
	IF v_acs_attribute_id IS NOT NULL THEN
	   v_attribute_id := im_dynfield_attribute__new_only_dynfield (
	       null,					-- attribute_id
	       ''im_dynfield_attribute'',		-- object_type
	       now(),					-- creation_date
	       null,					-- creation_user
	       null,					-- creation_ip
	       null,					-- context_id	
	       v_acs_attribute_id,			-- acs_attribute_id
	       ''richtext'',				-- widget
	       ''f'',					-- deprecated_p
	       ''t'',					-- already_existed_p
	       null,					-- pos_y
	       ''plain'',				-- label_style
	       ''f'',					-- also_hard_coded_p   
	       ''t''					-- include_in_search_p
	  );
	ELSE
	  v_attribute_id := im_dynfield_attribute_new (
	  	 ''im_project'',			-- object_type
		 ''description'',			-- column_name
		 ''#intranet-core.Description#'',	-- pretty_name
		 ''richtext'',				-- widget_name
		 ''text'',				-- acs_datatype
		 ''f'',					-- required_p   
		 17,					-- pos y
		 ''f'',					-- also_hard_coded
		 ''im_projects''			-- table_name
	  );

	END IF;


	FOR row IN 
		SELECT category_id FROM im_categories WHERE category_id NOT IN (100,101) AND category_type = ''Intranet Project Type''
	LOOP
			
		SELECT count(*) INTO v_count FROM im_dynfield_type_attribute_map WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		IF v_count = 0 THEN
		   INSERT INTO im_dynfield_type_attribute_map
		   	  (attribute_id, object_type_id, display_mode, help_text,section_heading,default_value,required_p)
		   VALUES
			  (v_attribute_id, row.category_id,''edit'',null,null,null,''f'');
		ELSE
		   UPDATE im_dynfield_type_attribute_map SET display_mode = ''edit'', required_p = ''f'' WHERE attribute_id = v_attribute_id AND object_type_id = row.category_id;
		END IF;

	END LOOP;


	RETURN 0;
END;' language 'plpgsql';

SELECT inline_16 ();
DROP FUNCTION inline_16 ();