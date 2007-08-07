<master src="../../intranet-core/www/master">

<h1>@page_title@</h1>

<%= [lang::message::lookup "" intranet-ganttproject.Delete_Tasks_Msg "
<p>
The following tasks are not contained in the specified GanttProject '.gan' <br>
file anymore, so we are going to delete them.
</p>
<p>
However, we could not delete these tasks yet, because they are associated<br>
with resources such as timesheet hours, expenses, forum discussions, files <br>
etc.
</p>
<p>
<b>Reassign Resources</b>: Please select the tasks to be deleted and choose<br>
where to reassign its resources.
</p>
<p>
<b>Or</b>: Just <a href='@return_url;noquote@'>Return to the previous page</a> in order to keep these task and their <br>
resources.
</p>

"] %>


<br>
<listtemplate name="delete_tasks"></listtemplate>