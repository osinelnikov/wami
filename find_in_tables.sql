create type search_results as
(
    table_name  text,
    column_name text,
    value       text
);


create function find_in_tables(search_string text) returns SETOF search_results language plpgsql as
$$
DECLARE
    _table record;
    _column record;
    query text;
    result record;
BEGIN
    search_string := concat('%', search_string, '%');
    FOR _table IN (SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE') LOOP
      FOR _column IN (SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = _table.table_name) LOOP
        IF _column.data_type = 'jsonb' THEN
           query := format('SELECT %I::text as value FROM %I WHERE %I::text LIKE %L', _column.column_name, _table.table_name, _column.column_name, search_string);
        ELSE
           query := format('SELECT %I::text as value FROM %I WHERE %I::text LIKE %L', _column.column_name, _table.table_name, _column.column_name, search_string);
        END IF;
        FOR result IN EXECUTE query LOOP
          RETURN NEXT (_table.table_name, _column.column_name, result.value)::search_results;
        END LOOP;
      END LOOP;
    END LOOP;
    RETURN;
END;
$$;
 
