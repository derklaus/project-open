-- packages/search/sql/postgresql/upgrade/upgrade-4.2-4.5.sql
--
-- @author jon@jongriffi.com
-- @creation-date 2002-08-02
-- @cvs-id $Id: upgrade-4.2-4.5.1.sql,v 1.1 2002/08/03 00:39:53 jong Exp $
--

-- search-packages-create.sql

drop function search_observer__dequeue(integer,timestamp,varchar);

create function search_observer__dequeue(integer,timestamp,varchar)
returns integer as '
declare
    p_object_id                 alias for $1;
    p_event_date                alias for $2;
    p_event                     alias for $3;
begin

    delete from search_observer_queue
    where object_id = p_object_id
    and event = p_event
    and event_date = p_event_date;

    return 0;

end;' language 'plpgsql';

-- 

alter table search_observer_queue rename column date to event_date;




