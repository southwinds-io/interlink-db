/*
    Interlink Configuration Management Database - (c) 2018-Present - SouthWinds Tech Ltd - www.southwinds.io

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software distributed under
    the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
    either express or implied.
    See the License for the specific language governing permissions and limitations under the License.

    Contributors to this project, hereby assign copyright in this code to the project,
    to be licensed under the same terms as the rest of the code.

*/
DO $$
BEGIN

  /*
    select link_array_dedup(array_param):
      de-duplicates the elements in the passed-in array.
    */
  CREATE OR REPLACE FUNCTION link_array_dedup(array_param anyarray)
    RETURNS anyarray
    LANGUAGE 'plpgsql'
    STABLE
  AS $BODY$
    DECLARE
    offset_point INTEGER;
    result_array array_param%TYPE := '{}';
  BEGIN
    IF array_param IS NULL THEN
      RETURN NULL;
    ELSEIF array_param = '{}' THEN
      RETURN result_array;
    END IF;

    FOR offset_point IN ARRAY_LOWER(array_param, 1)..ARRAY_UPPER(array_param, 1) LOOP
      IF array_param[offset_point] IS NULL THEN
        IF NOT EXISTS(SELECT 1 FROM UNNEST(result_array) AS s(a) WHERE a IS NULL) THEN
          result_array = ARRAY_APPEND(result_array, array_param[offset_point]);
        END IF;
      ELSEIF NOT(array_param[offset_point] = ANY(result_array)) OR NOT(NULL IS DISTINCT FROM (array_param[offset_point] = ANY(result_array))) THEN
        result_array = ARRAY_APPEND(result_array, array_param[offset_point]);
      END IF;
    END LOOP;
    RETURN result_array;
  END;
  $BODY$;

  ALTER FUNCTION link_array_dedup(anyarray)
    OWNER TO interlink;

  /*
      select link_get_child_link_ids(parent_link_ids):
        gets an array of Ids of all child links of the specified parent items.
    */
  CREATE OR REPLACE FUNCTION link_get_child_link_ids(parent_item_ids BIGINT[])
    RETURNS TABLE(ids BIGINT[])
    LANGUAGE 'plpgsql'
    STABLE
  AS $BODY$
  BEGIN
    RETURN QUERY
      SELECT array_agg(DISTINCT id)
      FROM link
      WHERE start_item_id = ANY(parent_item_ids::BIGINT[]);
  END;
  $BODY$;

  ALTER FUNCTION link_get_child_link_ids(BIGINT[])
    OWNER TO interlink;

  /*
      select link_get_child_link_rule_ids(parent_item_type_ids):
        gets an array of Ids of all child link rules of the specified parent item types.
    */
    CREATE OR REPLACE FUNCTION link_get_child_link_rule_ids(parent_item_type_ids BIGINT[])
    RETURNS TABLE(ids BIGINT[])
    LANGUAGE 'plpgsql'
    STABLE
  AS $BODY$
  BEGIN
    RETURN QUERY
      SELECT array_agg(DISTINCT id)
      FROM link_rule
      WHERE start_item_type_id = ANY(parent_item_type_ids::BIGINT[]);
  END;
  $BODY$;

  ALTER FUNCTION link_get_child_link_rule_ids(BIGINT[])
    OWNER TO interlink;

  /*
    select link_get_child_item_ids(parent_item_ids):
      gets an array of Ids of all child items of the specified parent items.
  */
  CREATE OR REPLACE FUNCTION link_get_child_item_ids(parent_item_ids bigint[])
    RETURNS TABLE(ids bigint[])
    LANGUAGE 'plpgsql'
    STABLE
    AS $BODY$
  BEGIN
    RETURN QUERY
      SELECT array_agg(DISTINCT end_item_id) AS child_item_ids
      FROM link
      WHERE start_item_id = ANY(parent_item_ids::BIGINT[]);
  END;
  $BODY$;

  ALTER FUNCTION link_get_child_item_ids(bigint[])
    OWNER TO interlink;

  /*
      select link_get_child_item_type_ids(parent_item_type_ids):
        gets an array of Ids of all child item types of the specified parent item types.
    */
  CREATE OR REPLACE FUNCTION link_get_child_item_type_ids(parent_item_type_ids INT[])
    RETURNS TABLE(ids INT[])
    LANGUAGE 'plpgsql'
    STABLE
  AS $BODY$
  BEGIN
    RETURN QUERY
      SELECT array_agg(DISTINCT end_item_type_id) AS child_item_type_ids
      FROM link_rule
      WHERE start_item_type_id = ANY(parent_item_type_ids::INT[]);
  END;
  $BODY$;

  ALTER FUNCTION link_get_child_item_type_ids(INT[])
    OWNER TO interlink;

  /*
    select link_get_parent_item_ids(child_item_ids):
      gets an array of Ids of all parent items of the specified child items.
  */
  CREATE OR REPLACE FUNCTION link_get_parent_item_ids(child_item_ids BIGINT[])
    RETURNS TABLE(ids BIGINT[])
    LANGUAGE 'plpgsql'
    STABLE
  AS $BODY$
  BEGIN
    RETURN QUERY
      SELECT array_agg(DISTINCT start_item_id) AS parent_item_ids
      FROM link
      WHERE end_item_id = ANY(child_item_ids::BIGINT[]);
  END;
  $BODY$;

  ALTER FUNCTION link_get_parent_item_ids(BIGINT[])
    OWNER TO interlink;

  /*
    select link_get_child_item_records(parent_item_ids):
      gets set of records containing array of Ids of all child items in the tree for all tree levels.
  */
  CREATE OR REPLACE FUNCTION link_get_child_item_records(parent_item_ids BIGINT[])
    RETURNS TABLE(ids BIGINT[])
    LANGUAGE 'plpgsql'
    STABLE
  AS $BODY$
    DECLARE child_item_ids BIGINT[];
  BEGIN
      child_item_ids := (SELECT link_get_child_item_ids(parent_item_ids::BIGINT[]))::BIGINT[];
    -- recurse
    IF (child_item_ids IS NOT NULL) THEN
      RETURN QUERY SELECT child_item_ids;
      RETURN QUERY SELECT link_get_child_item_records(child_item_ids::BIGINT[]);
    END IF;
  END;
  $BODY$;

  ALTER FUNCTION link_get_child_item_records(BIGINT[])
    OWNER TO interlink;

  /*
      select link_get_child_item_type_records(parent_item_type_ids):
        gets set of records containing array of Ids of all child item types in the tree for all tree levels.
    */
  CREATE OR REPLACE FUNCTION link_get_child_item_type_records(parent_item_type_ids INT[])
    RETURNS TABLE(ids INT[])
    LANGUAGE 'plpgsql'
    STABLE
  AS $BODY$
  DECLARE child_item_type_ids INT[];
  BEGIN
    child_item_type_ids := (SELECT link_get_child_item_type_ids(parent_item_type_ids::INT[]))::INT[];
    -- recurse
    IF (child_item_type_ids IS NOT NULL) THEN
      RETURN QUERY SELECT child_item_type_ids;
      RETURN QUERY SELECT link_get_child_item_type_records(child_item_type_ids::INT[]);
    END IF;
  END;
  $BODY$;

  ALTER FUNCTION link_get_child_item_type_records(INT[])
    OWNER TO interlink;

  /*
    select link_get_child_link_records(parent_item_ids):
      gets set of records containing array of Ids of all child links in the tree for all tree levels.
  */
  CREATE OR REPLACE FUNCTION link_get_child_link_records(parent_item_ids BIGINT[])
    RETURNS TABLE(ids BIGINT[])
    LANGUAGE 'plpgsql'
    STABLE
  AS $BODY$
  DECLARE
    child_item_ids BIGINT[];
    child_link_ids BIGINT[];
  BEGIN
    child_item_ids := (SELECT link_get_child_item_ids(parent_item_ids::BIGINT[]))::BIGINT[];
    child_link_ids := (SELECT link_get_child_link_ids(parent_item_ids::BIGINT[]))::BIGINT[];
    -- recurse
    IF (child_link_ids IS NOT NULL) THEN
      RETURN QUERY SELECT child_link_ids;
      RETURN QUERY SELECT link_get_child_link_records(child_item_ids::BIGINT[]);
    END IF;
  END;
  $BODY$;

  ALTER FUNCTION link_get_child_link_records(BIGINT[])
    OWNER TO interlink;

  /*
      select link_get_child_link_rule_records(parent_item_ids):
        gets set of records containing an array of Ids of all child link rules in the tree for all tree levels.
    */
  CREATE OR REPLACE FUNCTION link_get_child_link_rule_records(parent_item_ids BIGINT[])
    RETURNS TABLE(ids BIGINT[])
    LANGUAGE 'plpgsql'
    STABLE
  AS $BODY$
  DECLARE
    child_item_type_ids INT[];
    child_link_rule_ids BIGINT[];
  BEGIN
    child_item_type_ids := (SELECT link_get_child_item_type_ids(parent_item_ids::INT[]))::INT[];
    child_link_rule_ids := (SELECT link_get_child_link_rule_ids(parent_item_ids::BIGINT[]))::BIGINT[];
    -- recurse
    IF (child_link_rule_ids IS NOT NULL) THEN
      RETURN QUERY SELECT child_link_rule_ids;
      RETURN QUERY SELECT link_get_child_link_rule_records(child_item_type_ids::BIGINT[]);
    END IF;
  END;
  $BODY$;

  ALTER FUNCTION link_get_child_link_rule_records(bigint[])
    OWNER TO interlink;

  /*
    link_get_child_items(parent_id bigint):
      returns an array of the Ids of the child items of a specified item in a tree.
   */
  CREATE OR REPLACE FUNCTION link_get_child_items(parent_id bigint)
    RETURNS BIGINT[]
    LANGUAGE 'plpgsql'
    STABLE
  AS $BODY$
  DECLARE
    children BIGINT[];
    item RECORD;
  BEGIN
    FOR item IN
      SELECT link_get_child_item_records(ARRAY[parent_id]) AS ids
      LOOP
        children := children || item.ids;
      END LOOP;
    children := link_array_dedup(children);
    RETURN SORT(children::INT[]);
  END;
  $BODY$;

  ALTER FUNCTION link_get_child_items(bigint)
    OWNER TO interlink;

  /*
    link_get_child_links(parent_id bigint):
      returns an array of the Ids of the child links of a specified item in a tree.
   */
  CREATE OR REPLACE FUNCTION link_get_child_links(parent_id bigint)
    RETURNS BIGINT[]
    LANGUAGE 'plpgsql'
    STABLE
  AS $BODY$
  DECLARE
    children BIGINT[];
    item RECORD;
  BEGIN
    FOR item IN
    SELECT link_get_child_link_records(ARRAY[parent_id]) AS ids
       LOOP
         children := children || item.ids;
    END LOOP;
    children := link_array_dedup(children);
    RETURN SORT(children::INT[]);
  END;
  $BODY$;

  ALTER FUNCTION link_get_child_links(bigint)
    OWNER TO interlink;

  /*
    link_delete_tree(bigint): deletes all items and links under a specified parent item in an item tree.
   */
  CREATE OR REPLACE FUNCTION link_delete_tree(root_item_key character varying)
    RETURNS TABLE(links_affected INTEGER, items_affected INTEGER)
    LANGUAGE 'plpgsql'
    VOLATILE
  AS $BODY$
  DECLARE
    links_affected INTEGER := 0;
    items_affected INTEGER := 0;
    root_item_id BIGINT := (SELECT id FROM item WHERE key = root_item_key);
    child_item_ids BIGINT[] := link_get_child_items(root_item_id);
  BEGIN
    DELETE FROM link WHERE start_item_id = ANY(child_item_ids::BIGINT[]) OR end_item_id = ANY(child_item_ids::BIGINT[]);
    GET DIAGNOSTICS links_affected := ROW_COUNT;
    DELETE FROM item WHERE id = ANY((child_item_ids || root_item_id)::BIGINT[]);
    GET DIAGNOSTICS items_affected := ROW_COUNT;
    RETURN QUERY SELECT links_affected AS links_deleted, (items_affected + 1) as items_deleted;
  END;
  $BODY$;

  ALTER FUNCTION link_delete_tree(character varying)
    OWNER TO interlink;

END
$$;