# /www/admin/categories/one-type.tcl
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
  
  Displays all categories of one category type, if category_type
  form var is supplied.  Otherwise, display all categories
  whose category_type is set to NULL.

  @param category_type

  @author sskracic@arsdigita.com
  @author michael@yoon.org
  @creation-date October 31, 1999
} {
  category_type:optional
}

if { [info exists category_type] && ![empty_string_p $category_type]} {
    set category_type_criterion "c.category_type = :category_type"
    set page_title $category_type
} else {
    set category_type ""
    set category_type_criterion "c.category_type is null"
    set page_title "None"
}

set category_list_html ""

db_foreach all_categories_of_type "
select c.category, c.category_id, count(ui.user_id) as n_interested_users
from users_interests ui, categories c
where ui.category_id (+) = c.category_id
and $category_type_criterion
group by c.category, c.category_id
order by n_interested_users desc" {

    append category_list_html "<li><a href=\"one?[export_url_vars category_id]\">$category</a>\n"

    if {$n_interested_users > 0} {
	append category_list_html " (number of interested users: <a href=\"/admin/users/action-choose?[export_url_vars category_id]\">$n_interested_users</a>)\n"
    }
}




doc_return  200 text/html "[ad_admin_header $page_title]

<H2>$page_title</H2>

[ad_admin_context_bar [list "index" "Categories"] "One category type"]

<hr>

<ul>

$category_list_html

<p>
<li><a href=\"category-add?[export_url_vars category_type]\">Add a category of this type</a>
</ul>

[ad_admin_footer]
"
