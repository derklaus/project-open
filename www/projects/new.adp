<master src="../master">
<property name="title">#intranet-core.Projects#</property>
<property name="main_navbar_label">projects</property>

<form action=new-2.tcl method=POST>
<%= [export_form_vars return_url project_id creation_ip_address creation_user] %>
  <table border=0>
    <tr> 
      <td colspan=2 class=rowtitle>
        #intranet-core.Project_Base_Data#
	<%= [im_gif help "To avoid duplicate projects and to determine where the project data are stored on the local file server"] %>
      </td>
    </tr>
    <tr> 
      <td>#intranet-core.Project_Name#</td>
      <td> 
	<input type=text size=40 name=project_name value="@project_name@">
	<%= [im_gif help "Please enter any suitable name for the project. The name must be unique."] %>
      </td>
    </tr>
    <tr> 
      <td>#intranet-core.Project_# @required_field;noquote@ &nbsp;</td>
      <td> 
	<input type=text size="@project_nr_field_size@" name=project_nr value="@project_nr@" maxlength="@project_nr_field_size@" >
	<%= [im_gif help "A project number is composed by 4 digits for the year plus 4 digits for current identification"] %> &nbsp; 
      </td>
    </tr>

<if @enable_nested_projects_p@>
    <tr> 
      <td>#intranet-core.Parent_Project# &nbsp;</td>
      <td> 
	<%= [im_project_select "parent_id" $parent_id [_ intranet-core.Open]] %>
	<%= [im_gif help "Do you want to create a subproject (a project that is part of an other project)? Leave the field blank (-- Please Select --) if you are unsure."] %> &nbsp; 
      </td>
    </tr>
</if>

    <tr>
      <td>#intranet-core.Client# @required_field;noquote@ </td>
      <td> 
	<%= [im_company_select "company_id" $company_id "" "Customer" [list "Deleted" "Past" "Declined" "Inactive"]] %>

<if @user_admin_p@>
	<A HREF='/intranet/companies/new'>
	<%= [im_gif new "Add a new client"] %></A>
</if>

	<font size=-1><%= [im_gif help "There is a difference between &quot;Paying Client&quot; and &quot;Final Client&quot;. Here we want to know from whom we are going to receive the money..."] %></font> 
      </td>
    </tr>
    <tr> 
      <td>#intranet-core.Project_Manager#</td>
      <td> 
	<%= [im_employee_select_multiple "project_lead_id" $project_lead_id "" ""] %>
      </td>
    </tr>
    <tr> 
      <td>#intranet-core.Project_Type#  @required_field;noquote@ </td>
      <td> <font size=-1> 
	<%= [im_project_type_select "project_type_id" $project_type_id] %>

<if @user_admin_p@>
	<A HREF='/intranet/admin/categories/?select_category_type=Intranet+Project+Type'>
	<%= [im_gif new "Add a new project type"] %></A>
</if>

	<%= [im_gif help "General type of project. This allows us to create a suitable folder structure."] %></font></td>
    </tr>
    <tr> 
      <td>#intranet-core.Project_Status# @required_field;noquote@ </td>
      <td>
	<%= [im_project_status_select "project_status_id" $project_status_id] %>

<if @user_admin_p@>
	<A HREF='/intranet/admin/categories/?select_category_type=Intranet+Project+Status'>
	<%= [im_gif new "Add a new project status"] %></A>
</if>


	<%= [im_gif help "In Process: Work is starting immediately, Potential Project: May become a project later, Not Started Yet: We are waiting to start working on it, Finished: Finished already..."] %>
      </td>

    <tr> 
      <td>#intranet-core.Start_Date# @required_field;noquote@ </td>
      <td> 
	<%= [philg_dateentrywidget start $start_date] %>
      </td>
    </tr>

    <tr> 
      <td>#intranet-core.Delivery_Date# @required_field;noquote@ </td>
      <td> 
	<%= [philg_dateentrywidget end $end_date] %>, &nbsp;
        <INPUT NAME=end_time.time TYPE=text SIZE=8 MAXLENGTH=8 value="@end_time@">
      </td>
    </tr>
    <tr> 
      <td>#intranet-core.Description#<br>(#intranet-core.publicly_searchable#) </td>
      <td> 
        <textarea NAME=description rows=5 cols=50 wrap=soft>@description@</textarea>
      </td>
    </tr>

    <tr> 
      <td valign=top> 
	<div align=right>&nbsp; </div>
      </td>
      <td> 
	  <p> 
	    <input type=submit value="@button_text@" name=submit2>
	    <%= [im_gif help "Create the new folder structure"] %>
	  </p>
      </td>
    </tr>
  </table>
</form>
