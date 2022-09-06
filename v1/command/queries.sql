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
DO
$$
BEGIN

/*
 this function is used by the authentication logic to retrieve a list of the roles
 the logged user is in
 */
CREATE OR REPLACE FUNCTION link_get_user_roles_list(
    user_key_param character varying
)
    RETURNS TABLE(role_key character varying)
    LANGUAGE 'plpgsql'
    COST 100
    STABLE
AS $BODY$
BEGIN
    RETURN QUERY
        SELECT r.key as role_key
        FROM role r
            INNER JOIN membership m ON r.id = m.role_id
            INNER JOIN "user" u ON m.user_id = u.id
        WHERE u.key = user_key_param;
END;
$BODY$;

/*
  link_find_items: find items that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION link_find_items(
    tag_param text[], -- zero (null) or more tags
    attribute_param hstore, -- zero (null) or more key->regex pair attributes
    status_param smallint, -- zero (null) or one status
    item_type_key_param character varying, -- zero (null) or one item type
    date_created_from_param timestamp(6) with time zone, -- none (null) or created from date
    date_created_to_param timestamp(6) with time zone, -- none (null) or created to date
    date_updated_from_param timestamp(6) with time zone, -- none (null) or updated from date
    date_updated_to_param timestamp(6) with time zone, -- none (null) or updated to date
    model_key_param character varying, -- the meta model key the item is for
    enc_key_ix_param smallint, -- the encryption key index
    max_items integer, -- the maximum number of items to return
    role_key_param character varying[]
  )
  RETURNS TABLE(
    id bigint,
    key character varying,
    name character varying,
    description text,
    status smallint,
    item_type_key character varying,
    meta jsonb,
    meta_enc boolean,
    txt text,
    txt_enc boolean,
    enc_key_ix smallint,
    tag text[],
    attribute hstore,
    version bigint,
    created timestamp(6) with time zone,
    updated timestamp(6) with time zone,
    changed_by character varying,
    model_key character varying,
    partition_key character varying
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  IF (max_items IS NULL) THEN
    max_items = 20;
  END IF;

  RETURN QUERY SELECT
    i.id,
    i.key,
    i.name,
    i.description,
    i.status,
    it.key as item_type_key,
    i.meta,
    i.meta_enc,
    i.txt,
    i.txt_enc,
    i.enc_key_ix,
    i.tag,
    i.attribute,
    i.version,
    i.created,
    i.updated,
    i.changed_by,
    m.key as model_key,
    p.key as partition_key
  FROM item i
  INNER JOIN item_type it ON i.item_type_id = it.id
  INNER JOIN model m ON m.id = it.model_id
  INNER JOIN partition p on i.partition_id = p.id
  INNER JOIN privilege pr on p.id = pr.partition_id
  INNER JOIN role r on pr.role_id = r.id
  WHERE
  -- by item type
      (it.key = item_type_key_param OR item_type_key_param IS NULL)
  -- by status
  AND (i.status = status_param OR status_param IS NULL)
  -- by encryption key index
  AND (i.enc_key_ix = enc_key_ix_param OR enc_key_ix_param IS NULL)
  -- by tags
  AND (i.tag @> tag_param OR tag_param IS NULL)
  -- by attributes (hstore)
  AND (i.attribute @> attribute_param OR attribute_param IS NULL)
  -- by created date range
  AND ((date_created_from_param <= i.created AND date_created_to_param > i.created) OR
      (date_created_from_param IS NULL AND date_created_to_param IS NULL) OR
      (date_created_from_param IS NULL AND date_created_to_param > i.created) OR
      (date_created_from_param <= i.created AND date_created_to_param IS NULL))
  -- by updated date range
  AND ((date_updated_from_param <= i.updated AND date_updated_to_param > i.updated) OR
      (date_updated_from_param IS NULL AND date_updated_to_param IS NULL) OR
      (date_updated_from_param IS NULL AND date_updated_to_param > i.updated) OR
      (date_updated_from_param <= i.updated AND date_updated_to_param IS NULL))
  -- by model
  AND (m.key = model_key_param OR model_key_param IS NULL)
  AND pr.can_read = TRUE
  AND r.key = ANY(role_key_param)
  LIMIT max_items;
END
$BODY$;

ALTER FUNCTION link_find_items(
    text[],
    hstore,
    smallint,
    character varying,
    timestamp(6) with time zone, -- created from
    timestamp(6) with time zone, -- created to
    timestamp(6) with time zone, -- updated from
    timestamp(6) with time zone, -- updated to
    character varying, -- model key
    smallint, -- enc key index
    integer, -- max_items
    character varying[] -- role_key_param
  )
  OWNER TO interlink;

/*
  link_find_links: find links that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION link_find_links(
  start_item_key_param character varying, -- zero (null) or one start item
  end_item_key_param character varying, -- zero (null) or one end item
  tag_param text[], -- zero (null) or more tags
  attribute_param hstore, -- zero (null) or more key->regex pair attributes
  link_type_key_param character varying, -- zero (null) or one link type
  date_created_from_param timestamp(6) with time zone, -- none (null) or created from date
  date_created_to_param timestamp(6) with time zone, -- none (null) or created to date
  date_updated_from_param timestamp(6) with time zone, -- none (null) or updated from date
  date_updated_to_param timestamp(6) with time zone, -- none (null) or updated to date
  model_key_param character varying, -- the meta model key the link is for
  enc_key_ix_param smallint, -- the index of the encryotion key used
  max_items integer, -- the maximum number of items to return
  role_key_param character varying[]
)
RETURNS TABLE(
    id bigint,
    key character varying,
    link_type_key character varying,
    start_item_key character varying,
    end_item_key character varying,
    description text,
    meta jsonb,
    meta_enc boolean,
    txt text,
    txt_enc boolean,
    enc_key_ix smallint,
    tag text[],
    attribute hstore,
    version bigint,
    created TIMESTAMP(6) WITH TIME ZONE,
    updated timestamp(6) WITH TIME ZONE,
    changed_by CHARACTER VARYING,
    encrypt_txt boolean,
    encrypt_meta boolean
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  RETURN QUERY SELECT
    l.id,
    l.key,
    lt.key as link_type_key,
    start_item.key AS start_item_key,
    end_item.key AS end_item_key,
    l.description,
    l.meta,
    l.meta_enc,
    l.txt,
    l.txt_enc,
    l.enc_key_ix,
    l.tag,
    l.attribute,
    l.version,
    l.created,
    l.updated,
    l.changed_by,
    lt.encrypt_txt,
    lt.encrypt_meta
  FROM link l
    INNER JOIN item start_item ON l.start_item_id = start_item.id
    INNER JOIN item end_item ON l.end_item_id = end_item.id
    INNER JOIN link_type lt ON l.link_type_id = lt.id
    INNER JOIN model m ON m.id = lt.model_id
    INNER JOIN partition p on m.partition_id = p.id
    INNER JOIN privilege pr on p.id = pr.partition_id
    INNER JOIN role r on pr.role_id = r.id
  WHERE
   -- by link type
   (lt.key = link_type_key_param OR link_type_key_param IS NULL)
   -- by start item
   AND (start_item.key = start_item_key_param OR start_item_key_param IS NULL)
   -- by end item
   AND (end_item.key = end_item_key_param OR end_item_key_param IS NULL)
   -- by tags
   AND (l.tag @> tag_param OR tag_param IS NULL)
   -- by attributes (hstore)
   AND (l.attribute @> attribute_param OR attribute_param IS NULL)
   -- by created date range
   AND ((date_created_from_param <= l.created AND date_created_to_param > l.created) OR
        (date_created_from_param IS NULL AND date_created_to_param IS NULL) OR
        (date_created_from_param IS NULL AND date_created_to_param > l.created) OR
        (date_created_from_param <= l.created AND date_created_to_param IS NULL))
   -- by updated date range
   AND ((date_updated_from_param <= l.updated AND date_updated_to_param > l.updated) OR
        (date_updated_from_param IS NULL AND date_updated_to_param IS NULL) OR
        (date_updated_from_param IS NULL AND date_updated_to_param > l.updated) OR
        (date_updated_from_param <= l.updated AND date_updated_to_param IS NULL))
    -- by model
   AND (m.key = model_key_param OR model_key_param IS NULL)
   -- by encryption key
   AND (l.enc_key_ix = enc_key_ix_param OR enc_key_ix_param IS NULL)
   AND pr.can_read = TRUE
   AND r.key = ANY(role_key_param)
   LIMIT max_items;
END
$BODY$;

ALTER FUNCTION link_find_links(
  character varying,
  character varying,
  text[],
  hstore,
  character varying,
  timestamp(6) with time zone, -- created from
  timestamp(6) with time zone, -- created to
  timestamp(6) with time zone, -- updated from
  timestamp(6) with time zone, -- updated to,
  character varying, -- model key
  smallint, -- enc_key_ix_param
  integer, -- max_items
  character varying[] -- role_key_param
)
OWNER TO interlink;

/*
  link_find_item_types: find item types that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION link_find_item_types(
    date_created_from_param timestamp(6) with time zone, -- none (null) or created from date
    date_created_to_param timestamp(6) with time zone, -- none (null) or created to date
    date_updated_from_param timestamp(6) with time zone, -- none (null) or updated from date
    date_updated_to_param timestamp(6) with time zone, -- none (null) or updated to date
    model_key_param character varying, -- the meta model the item type is for
    role_key_param character varying[] -- the role of the requesting user
  )
  RETURNS TABLE(
    id integer,
    key character varying,
    name character varying,
    description text,
    filter jsonb,
    meta_schema jsonb,
    version bigint,
    created timestamp(6) with time zone,
    updated timestamp(6) with time zone,
    changed_by character varying,
    model_key character varying,
    root boolean,
    notify_change char,
    tag text[],
    encrypt_meta boolean,
    encrypt_txt boolean,
    style jsonb
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  RETURN QUERY SELECT
     i.id,
     i.key,
     i.name,
     i.description,
     i.filter,
     i.meta_schema,
     i.version,
     i.created,
     i.updated,
     i.changed_by,
     m.key as model_key,
     k.root,
     i.notify_change,
     i.tag,
     i.encrypt_meta,
     i.encrypt_txt,
     i.style
  FROM item_type i
  INNER JOIN model m ON i.model_id = m.id
  INNER JOIN partition p ON m.partition_id = p.id
  INNER JOIN privilege pr on p.id = pr.partition_id
  INNER JOIN role r on pr.role_id = r.id
  -- works out if it is a root item below
  LEFT OUTER JOIN (
    SELECT t.id, (t.id IS NOT NULL) AS root
    FROM (
           SELECT it.*
           FROM item_type it
             EXCEPT
           SELECT it.*
           FROM item_type it
              INNER JOIN link_rule r
                  ON it.id = r.end_item_type_id
         ) AS t
  ) AS k
  ON  k.id = i.id
  WHERE
  -- by created date range
     ((date_created_from_param <= i.created AND date_created_to_param > i.created) OR
      (date_created_from_param IS NULL AND date_created_to_param IS NULL) OR
      (date_created_from_param IS NULL AND date_created_to_param > i.created) OR
      (date_created_from_param <= i.created AND date_created_to_param IS NULL))
  -- by updated date range
  AND ((date_updated_from_param <= i.updated AND date_updated_to_param > i.updated) OR
      (date_updated_from_param IS NULL AND date_updated_to_param IS NULL) OR
      (date_updated_from_param IS NULL AND date_updated_to_param > i.updated) OR
      (date_updated_from_param <= i.updated AND date_updated_to_param IS NULL))
  -- by model
  AND (m.key = model_key_param OR model_key_param IS NULL)
  AND pr.can_read = TRUE
  AND r.key = ANY(role_key_param);
END
$BODY$;

ALTER FUNCTION link_find_item_types(
  timestamp(6) with time zone, -- created from
  timestamp(6) with time zone, -- created to
  timestamp(6) with time zone, -- updated from
  timestamp(6) with time zone, -- updated to
  character varying, -- meta model key
  character varying[] -- role_key_param
)
OWNER TO interlink;

/*
  link_find_link_types: find link types that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION link_find_link_types(
    date_created_from_param timestamp(6) with time zone, -- none (null) or created from date
    date_created_to_param timestamp(6) with time zone, -- none (null) or created to date
    date_updated_from_param timestamp(6) with time zone, -- none (null) or updated from date
    date_updated_to_param timestamp(6) with time zone, -- none (null) or updated to date
    model_key_param character varying, -- meta model key the link is for
    role_key_param character varying[] -- the role is executing the query
  )
  RETURNS TABLE(
       id           integer,
       key          character varying,
       name         character varying,
       description  text,
       meta_schema  jsonb,
       tag          text[],
       encrypt_meta boolean,
       encrypt_txt  boolean,
       style        jsonb,
       version      bigint,
       created      timestamp(6) with time zone,
       updated      timestamp(6) with time zone,
       changed_by   character varying,
       model_key    character varying
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  RETURN QUERY SELECT
     l.id,
     l.key,
     l.name,
     l.description,
     l.meta_schema,
     l.tag,
     l.encrypt_meta,
     l.encrypt_txt,
     l.style,
     l.version,
     l.created,
     l.updated,
     l.changed_by,
     m.key as model_key
  FROM link_type l
  INNER JOIN model m ON m.id = l.model_id
  INNER JOIN partition p on m.partition_id = p.id
  INNER JOIN privilege pr on p.id = pr.partition_id
  INNER JOIN role r on pr.role_id = r.id
  WHERE
  -- by created date range
     ((date_created_from_param <= l.created AND date_created_to_param > l.created) OR
      (date_created_from_param IS NULL AND date_created_to_param IS NULL) OR
      (date_created_from_param IS NULL AND date_created_to_param > l.created) OR
      (date_created_from_param <= l.created AND date_created_to_param IS NULL))
  -- by updated date range
  AND ((date_updated_from_param <= l.updated AND date_updated_to_param > l.updated) OR
      (date_updated_from_param IS NULL AND date_updated_to_param IS NULL) OR
      (date_updated_from_param IS NULL AND date_updated_to_param > l.updated) OR
      (date_updated_from_param <= l.updated AND date_updated_to_param IS NULL))
  -- by model
  AND (m.key = model_key_param OR model_key_param IS NULL)
  AND pr.can_read = TRUE
  AND r.key = ANY(role_key_param);
END
$BODY$;

ALTER FUNCTION link_find_link_types(
  timestamp(6) with time zone, -- created from
  timestamp(6) with time zone, -- created to
  timestamp(6) with time zone, -- updated from
  timestamp(6) with time zone, -- updated to
  character varying, -- meta model key
  character varying[] -- role_key_param
)
OWNER TO interlink;

/*
  link_find_items_change: find change records for items that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION link_find_items_change(
  item_key_param character varying,
  date_changed_from_param timestamp(6) with time zone, -- none (null) or updated from date
  date_changed_to_param timestamp(6) with time zone -- none (null) or updated to date
)
RETURNS TABLE(
    operation char,
    changed timestamp(6) with time zone,
    id bigint,
    key character varying,
    name character varying,
    description text,
    status smallint,
    item_type_id integer,
    meta jsonb,
    tag text[],
    attribute hstore,
    version bigint,
    created timestamp(6) with time zone,
    updated timestamp(6) with time zone,
    changed_by character varying
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  RETURN QUERY SELECT
    i.operation,
    i.changed,
    i.id,
    i.key,
    i.name,
    i.description,
    i.status,
    i.item_type_id,
    i.meta,
    i.tag,
    i.attribute,
    i.version,
    i.created,
    i.updated,
    i.changed_by
  FROM item_change i
  WHERE i.key = item_key_param
  -- by change date range
  AND ((date_changed_from_param <= i.changed AND date_changed_to_param > i.changed) OR
      (date_changed_from_param IS NULL AND date_changed_to_param IS NULL) OR
      (date_changed_from_param IS NULL AND date_changed_to_param > i.changed) OR
      (date_changed_from_param <= i.changed AND date_changed_to_param IS NULL));
END
$BODY$;

ALTER FUNCTION link_find_items_change(
  character varying, -- item natural key
  timestamp(6) with time zone, -- change date from
  timestamp(6) with time zone -- change date to
)
OWNER TO interlink;

/*
  link_find_links_change: find change records for links that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION link_find_links_change(
    link_key_param character varying,
    date_changed_from_param timestamp(6) with time zone, -- none (null) or updated from date
    date_changed_to_param timestamp(6) with time zone -- none (null) or updated to date
  )
  RETURNS TABLE(
    operation char,
    changed timestamp(6) with time zone,
    id bigint,
    key character varying,
    description text,
    link_type_key character varying,
    start_item_key character varying,
    end_item_key character varying,
    meta jsonb,
    tag text[],
    attribute hstore,
    version bigint,
    created timestamp(6) with time zone,
    updated timestamp(6) with time zone,
    changed_by character varying
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  RETURN QUERY SELECT
     l.operation,
     l.changed,
     l.id,
     l.key,
     l.description,
     lt.key as link_type_key,
     start_item.key AS start_item_key,
     end_item.key AS end_item_key,
     l.meta,
     l.tag,
     l.attribute,
     l.version,
     l.created,
     l.updated,
     l.changed_by
  FROM link_change l
    INNER JOIN item start_item
      ON l.start_item_id = start_item.id
    INNER JOIN item end_item
      ON l.end_item_id = end_item.id
    INNER JOIN link_type lt
      ON l.link_type_id = lt.id
  WHERE l.key = link_key_param
  -- by changed range
  AND ((date_changed_from_param <= l.changed AND date_changed_to_param > l.changed) OR
      (date_changed_from_param IS NULL AND date_changed_to_param IS NULL) OR
      (date_changed_from_param IS NULL AND date_changed_to_param > l.changed) OR
      (date_changed_from_param <= l.changed AND date_changed_to_param IS NULL));
END
$BODY$;

ALTER FUNCTION link_find_links_change(
  character varying, -- item natural key
  timestamp(6) with time zone, -- change date from
  timestamp(6) with time zone -- change date to
)
OWNER TO interlink;

/*
  link_get_links_from_item_count: find the number of links of a particular type that are associated with an start item.
     Can use the link attributes to filter the result.
 */
CREATE OR REPLACE FUNCTION link_get_links_from_item_count(
    item_key_param character varying, -- item natural key
    attribute_param hstore -- filter for links
  )
  RETURNS INTEGER
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
DECLARE
  link_count integer;
BEGIN
  RETURN (
    SELECT COUNT(*) INTO link_count
    FROM link l
    INNER JOIN item i
       ON l.start_item_id = i.id
    WHERE i.key = item_key_param
    -- by attributes (hstore)
    AND (l.attribute @> attribute_param OR attribute_param IS NULL)
  );
END
$BODY$;

ALTER FUNCTION link_get_links_from_item_count(
  character varying, -- item natural key
  hstore -- filter for links
)
OWNER TO interlink;

/*
  link_get_links_to_item_count: find the number of links of a particular type that are associated with an end item.
     Can use the link attributes to filter the result.
 */
CREATE OR REPLACE FUNCTION link_get_links_to_item_count(
    item_key_param character varying, -- item natural key
    attribute_param hstore -- filter for links
  )
  RETURNS INTEGER
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
DECLARE
  link_count integer;
BEGIN
  RETURN (
    SELECT COUNT(*) INTO link_count
    FROM link l
      INNER JOIN item i
        ON l.end_item_id = i.id
    WHERE i.key = item_key_param
    -- by attributes (hstore)
    AND (l.attribute @> attribute_param OR attribute_param IS NULL)
  );
END
$BODY$;

ALTER FUNCTION link_get_links_to_item_count(
  character varying, -- item natural key
  hstore -- filter for links
)
OWNER TO interlink;

/*
  link_find_link_rules: find link rules that comply with the passed-in query parameters
 */
CREATE OR REPLACE FUNCTION link_find_link_rules(
  link_type_key_param character varying, -- none (null) or link type key
  start_item_type_key_param character varying, -- none (null) or start item type key
  end_item_type_key_param character varying, -- none (null) or end item type key
  date_created_from_param timestamp(6) with time zone, -- none (null) or created from date
  date_created_to_param timestamp(6) with time zone, -- none (null) or created to date
  date_updated_from_param timestamp(6) with time zone, -- none (null) or updated from date
  date_updated_to_param timestamp(6) with time zone, -- none (null) or updated to date
  role_key_param character varying[]
)
RETURNS TABLE(
  id bigint,
  key character varying,
  name character varying,
  description text,
  link_type_key character varying,
  start_item_type_key character varying,
  end_item_type_key character varying,
  version bigint,
  created timestamp(6) with time zone,
  updated timestamp(6) with time zone,
  changed_by character varying
)
LANGUAGE 'plpgsql'
COST 100
STABLE
AS $BODY$
BEGIN
  RETURN QUERY SELECT
      l.id,
      l.key,
      l.name,
      l.description,
      link_type.key as link_type_key,
      start_item_type.key as start_item_type_key,
      end_item_type.key as end_item_type_key,
      l.version,
      l.created,
      l.updated,
      l.changed_by
  FROM link_rule l
    INNER JOIN link_type link_type ON link_type.id = l.link_type_id
    INNER JOIN item_type start_item_type ON start_item_type.id = l.start_item_type_id
    INNER JOIN item_type end_item_type ON end_item_type.id = l.end_item_type_id
    INNER JOIN model m ON link_type.model_id = m.id
    INNER JOIN partition p ON m.partition_id = p.id
    INNER JOIN privilege pr ON p.id = pr.partition_id
    INNER JOIN role r ON pr.role_id = r.id
  WHERE
  -- by link type
     (link_type.key = link_type_key_param OR link_type_key_param IS NULL)
  -- by start item_type key
  AND (start_item_type.key = start_item_type_key_param OR start_item_type_key_param IS NULL)
  -- by end item_type key
  AND (end_item_type.key = end_item_type_key_param OR end_item_type_key_param IS NULL)
  -- by created date range
  AND ((date_created_from_param <= l.created AND date_created_to_param > l.created) OR
      (date_created_from_param IS NULL AND date_created_to_param IS NULL) OR
      (date_created_from_param IS NULL AND date_created_to_param > l.created) OR
      (date_created_from_param <= l.created AND date_created_to_param IS NULL))
  -- by updated date range
  AND ((date_updated_from_param <= l.updated AND date_updated_to_param > l.updated) OR
      (date_updated_from_param IS NULL AND date_updated_to_param IS NULL) OR
      (date_updated_from_param IS NULL AND date_updated_to_param > l.updated) OR
      (date_updated_from_param <= l.updated AND date_updated_to_param IS NULL))
  AND r.key = ANY(role_key_param)
  AND pr.can_read = TRUE;
END
$BODY$;

ALTER FUNCTION link_find_link_rules(
  character varying, -- link_type key
  character varying, -- start item_type key
  character varying, -- end item_type key
  timestamp(6) with time zone, -- created from
  timestamp(6) with time zone, -- created to
  timestamp(6) with time zone, -- updated from
  timestamp(6) with time zone, -- updated to
  character varying[] -- role_key_param
)
OWNER TO interlink;

/*
  link_find_child_items: returns a list of child items which are linked to the specified item.
 */
CREATE OR REPLACE FUNCTION link_find_child_items(
  parent_item_key_param character varying,
  link_type_key_param character varying
)
RETURNS TABLE(
  id bigint, -- id
  key character varying, -- key
  name character varying, -- name
  description text, -- description
  meta jsonb, -- meta
  tag text[], -- tag
  attribute hstore, -- attribute
  status smallint, -- status
  item_type_id integer,
  item_type_key character varying,
  version bigint,
  created timestamp(6) with time zone,
  updated timestamp(6) with time zone,
  changed_by character varying
)
LANGUAGE 'plpgsql'
COST 100
STABLE
AS $BODY$
BEGIN
  RETURN QUERY SELECT
     i.id,
     i.key,
     i.name,
     i.description,
     i.meta,
     i.tag,
     i.attribute,
     i.status,
     i.item_type_id,
     it.key AS item_type_key,
     i.version,
     i.created,
     i.updated,
     i.changed_by
  FROM item i
  INNER JOIN link l
    ON i.id = l.end_item_id
  INNER JOIN item_type it
    ON it.id = i.item_type_id
  INNER JOIN item i2
    ON i2.id = l.start_item_id
  INNER JOIN link_type lt
    ON lt.id = l.link_type_id
  WHERE i2.key = parent_item_key_param
  AND (lt.key = link_type_key_param OR link_type_key_param IS NULL)
  ORDER BY it.key DESC;
END
$BODY$;

ALTER FUNCTION link_find_child_items(character varying, character varying) OWNER TO interlink;

/*
  link_get_table_count:
    returns the number of tables in the database.
    this function is used to test readiness of the database service.
 */
CREATE OR REPLACE FUNCTION link_get_table_count()
RETURNS TABLE(count bigint)
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  RETURN QUERY
    SELECT count(table_name)
    FROM information_schema.tables
    WHERE table_catalog = 'interlink'
      AND table_schema = 'public';
END
$BODY$;

ALTER FUNCTION link_get_table_count() OWNER TO interlink;

/*
  link_get_model_item_types(model_key_param): get all item types in a model
 */
CREATE OR REPLACE FUNCTION link_get_model_item_types(
  model_key_param character varying, -- model natural key
  role_key_param character varying[]
)
  RETURNS TABLE(
    id integer,
    key character varying,
    name character varying,
    description text,
    filter jsonb,
    meta_schema jsonb,
    version bigint,
    created timestamp(6) with time zone,
    updated timestamp(6) with time zone,
    changed_by character varying,
    model_key character varying,
    root boolean -- true if the item type has all its links departing from it (a root node)
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  RETURN QUERY
    SELECT it.id,
           it.key,
           it.name,
           it.description,
           it.filter,
           it.meta_schema,
           it.version,
           it.created,
           it.updated,
           it.changed_by,
           m.key as model_key,
           k.root is not null as root
    FROM item_type it
    INNER JOIN model m ON m.id = it.model_id
    INNER JOIN partition p ON m.partition_id = p.id
    INNER JOIN privilege pr ON p.id = pr.partition_id
    INNER JOIN role r ON pr.role_id = r.id
    -- works out if it is a root item below
    LEFT OUTER JOIN (
      SELECT t.id, (t.id IS NOT NULL) AS root
      FROM (
         SELECT it.*
         FROM item_type it
        EXCEPT
         SELECT it.*
         FROM item_type it
            INNER JOIN link_rule r
               ON it.id = r.end_item_type_id
       ) AS t
    ) AS k
    ON  k.id = it.id
    WHERE m.key = model_key_param
    -- ensure RBAC
    AND pr.can_read = TRUE
    AND r.key = ANY(role_key_param);
END;
$BODY$;

ALTER FUNCTION link_get_model_item_types(character varying, character varying[]) OWNER TO interlink;

/*
  link_get_model_link_types(model_key_param): get all link types in a model
 */
CREATE OR REPLACE FUNCTION link_get_model_link_types(
  model_key_param character varying, -- model natural key
  role_key_param character varying[] -- roles
)
  RETURNS TABLE(
     id integer,
     key character varying,
     name character varying,
     description text,
     meta_schema jsonb,
     version bigint,
     created timestamp(6) with time zone,
     updated timestamp(6) with time zone,
     changed_by character varying,
     model_key character varying
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  RETURN QUERY
    SELECT
      lt.id,
      lt.key,
      lt.name,
      lt.description,
      lt.meta_schema,
      lt.version,
      lt.created,
      lt.updated,
      lt.changed_by,
      m.key as model_key
    FROM link_type lt
    INNER JOIN model m ON m.id = lt.model_id
    INNER JOIN partition p ON m.partition_id = p.id
    INNER JOIN privilege pr ON p.id = pr.partition_id
    INNER JOIN role r ON pr.role_id = r.id
    WHERE m.key = model_key_param
    -- ensure RBAC
    AND pr.can_read = TRUE
    AND r.key = ANY(role_key_param);
END;
$BODY$;

ALTER FUNCTION link_get_model_link_types(character varying, character varying[]) OWNER TO interlink;

/*
  link_get_model_link_rules(model_key_param): get all link rules in a model
 */
CREATE OR REPLACE FUNCTION link_get_model_link_rules(
  model_key_param character varying, -- model natural key
  role_key_param character varying[] -- roles
)
  RETURNS TABLE(
     id bigint,
     key character varying,
     name character varying,
     description text,
     link_type_key character varying,
     start_item_type_key character varying,
     end_item_type_key character varying,
     version bigint,
     created timestamp(6) with time zone,
     updated timestamp(6) with time zone,
     changed_by character varying
  )
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    r.key,
    r.name,
    r.description,
    lt.key as link_type_key,
    start_item_type.key as start_item_type_key,
    end_item_type.key as end_item_type_key,
    r.version,
    r.created,
    r.updated,
    r.changed_by
  FROM link_rule r
  INNER JOIN item_type start_item_type ON r.start_item_type_id = start_item_type.id
  INNER JOIN item_type end_item_type ON r.end_item_type_id = end_item_type.id
  INNER JOIN model start_item_type_model ON start_item_type_model.id = start_item_type.model_id
  INNER JOIN model end_item_type_model ON end_item_type_model.id = end_item_type.model_id
  INNER JOIN link_type lt ON lt.id = r.link_type_id
  INNER JOIN partition p ON start_item_type_model.partition_id = p.id
  INNER JOIN privilege pr ON p.id = pr.partition_id
  INNER JOIN role ro ON pr.role_id = ro.id
  WHERE start_item_type_model.key = end_item_type_model.key
    AND start_item_type_model.key = model_key_param
    -- ensure RBAC
    AND pr.can_read = TRUE
    AND ro.key = ANY(role_key_param);
END;
$BODY$;

ALTER FUNCTION link_get_model_link_rules(character varying, character varying[]) OWNER TO interlink;

/*
    link_get_item_children: get all child items of the specified item.
 */
CREATE OR REPLACE FUNCTION link_get_item_children(
  item_id_key character varying,
  role_key_param character varying[]
)
  RETURNS TABLE(
     id bigint,
     key character varying,
     name character varying,
     description text,
     status smallint,
     item_type_key character varying,
     item_type_name character varying,
     meta jsonb,
     meta_enc boolean,
     txt text,
     txt_enc boolean,
     enc_key_ix smallint,
     tag text[],
     attribute hstore,
     version bigint,
     created timestamp(6) with time zone,
     updated timestamp(6) with time zone,
     changed_by character varying,
     model_key character varying,
     partition_key character varying
)
  LANGUAGE 'plpgsql'
  COST 100
  STABLE
AS $BODY$
DECLARE
  item_id bigint;
BEGIN
  SELECT i.id FROM item i WHERE i.key = item_id_key INTO item_id;

  RETURN QUERY SELECT
    i.id,
    i.key,
    i.name,
    i.description,
    i.status,
    it.key as item_type_key,
    it.name as item_type_name,
    i.meta,
    i.meta_enc,
    i.txt,
    i.txt_enc,
    i.enc_key_ix,
    i.tag,
    i.attribute,
    i.version,
    i.created,
    i.updated,
    i.changed_by,
    m.key as model_key,
    p.key as partition_key
    FROM item i
      INNER JOIN item_type it ON i.item_type_id = it.id
      INNER JOIN model m ON m.id = it.model_id
      INNER JOIN partition p on i.partition_id = p.id
      INNER JOIN privilege pr on p.id = pr.partition_id
      INNER JOIN role r on pr.role_id = r.id
      WHERE i.id IN (
        SELECT unnest((
            SELECT *
            FROM link_get_child_items(item_id)
          )::bigint[]
        )
      )
      AND pr.can_read = TRUE
      AND r.key = ANY(role_key_param);
END;
$BODY$;

ALTER FUNCTION link_get_item_children(character varying, character varying[])
  OWNER TO interlink;

/*
    link_get_item_first_level_children: get all first level child items of the specified item filtered by item type.
 */
CREATE OR REPLACE FUNCTION link_get_item_first_level_children(
    item_key_param CHARACTER VARYING,
    child_item_type_key_param CHARACTER VARYING,
    role_key_param CHARACTER VARYING[]
)
    RETURNS TABLE(
         id bigint,
         key character varying,
         name character varying,
         description text,
         status smallint,
         item_type_key character varying,
         item_type_name character varying,
         meta jsonb,
         meta_enc boolean,
         txt text,
         txt_enc boolean,
         enc_key_ix smallint,
         tag text[],
         attribute hstore,
         version bigint,
         created timestamp(6) with time zone,
         updated timestamp(6) with time zone,
         changed_by character varying,
         model_key character varying,
         partition_key character varying
     )
    LANGUAGE 'plpgsql'
    COST 100
    STABLE
AS $BODY$
BEGIN
    RETURN QUERY SELECT child.id,
                        child.key,
                        child.name,
                        child.description,
                        child.status,
                        it.key  as item_type_key,
                        it.name as item_type_name,
                        child.meta,
                        child.meta_enc,
                        child.txt,
                        child.txt_enc,
                        child.enc_key_ix,
                        child.tag,
                        child.attribute,
                        child.version,
                        child.created,
                        child.updated,
                        child.changed_by,
                        m.key   as model_key,
                        p.key   as partition_key
         FROM item i
              INNER JOIN link l ON l.start_item_id = i.id
              INNER JOIN item child ON child.id = l.end_item_id
              INNER JOIN item_type it ON child.item_type_id = it.id
              INNER JOIN model m ON m.id = it.model_id
              INNER JOIN partition p on i.partition_id = p.id
              INNER JOIN privilege pr on p.id = pr.partition_id
              INNER JOIN role r on pr.role_id = r.id
         WHERE i.key = item_key_param
           AND it.key = COALESCE(child_item_type_key_param, it.key)
           AND pr.can_read = TRUE
           AND r.key = ANY(role_key_param);
END;
$BODY$;

ALTER FUNCTION link_get_item_first_level_children(character varying, character varying, character varying[])
   OWNER to interlink;

/*
    link_get_item_type_attributes: get all attributes for the specified item type.
 */
CREATE OR REPLACE FUNCTION link_get_item_type_attributes(
    item_type_key_param character varying,
    role_key_param character varying[]
)
    RETURNS TABLE(
     id          integer,
     key         character varying,
     name        character varying,
     description text,
     type        character varying,
     item_type_key character varying,
     def_value   character varying,
     required    boolean,
     regex       varchar,
     version     bigint,
     created     timestamp(6) with time zone,
     updated     timestamp(6) with time zone,
     changed_by  character varying
    )
    LANGUAGE 'plpgsql'
    COST 100
    STABLE
AS $BODY$
BEGIN
    RETURN QUERY
    SELECT ta.id,
           ta.key,
           ta.name,
           ta.description,
           ta.type,
           it.key as item_type_key,
           ta.def_value,
           ta.required,
           ta.regex,
           ta.version,
           ta.created,
           ta.updated,
           ta.changed_by
    FROM type_attribute ta
        INNER JOIN item_type it ON ta.item_type_id = it.id
        INNER JOIN model m ON it.model_id = m.id
        INNER JOIN partition p ON m.partition_id = p.id
        INNER JOIN privilege pr on p.id = pr.partition_id
        INNER JOIN role r on pr.role_id = r.id
    WHERE it.key = item_type_key_param
      AND pr.can_read = TRUE
      AND r.key = ANY(role_key_param);
END;
$BODY$;

ALTER FUNCTION link_get_item_type_attributes(character varying, character varying[])
   OWNER to interlink;

/*
    link_get_link_type_attributes: get all attributes for the specified link type.
 */
CREATE OR REPLACE FUNCTION link_get_link_type_attributes(
    link_type_key_param character varying,
    role_key_param character varying[]
)
    RETURNS TABLE(
         id          integer,
         key         character varying,
         name        character varying,
         description text,
         type        character varying,
         link_type_key character varying,
         def_value   character varying,
         required    boolean,
         regex       varchar,
         version     bigint,
         created     timestamp(6) with time zone,
         updated     timestamp(6) with time zone,
         changed_by  character varying
     )
    LANGUAGE 'plpgsql'
    COST 100
    STABLE
AS $BODY$
BEGIN
    RETURN QUERY
        SELECT ta.id,
               ta.key,
               ta.name,
               ta.description,
               ta.type,
               lt.key as link_type_key,
               ta.def_value,
               ta.required,
               ta.regex,
               ta.version,
               ta.created,
               ta.updated,
               ta.changed_by
        FROM type_attribute ta
                 INNER JOIN link_type lt ON ta.link_type_id = lt.id
                 INNER JOIN model m ON lt.model_id = m.id
                 INNER JOIN partition p ON m.partition_id = p.id
                 INNER JOIN privilege pr on p.id = pr.partition_id
                 INNER JOIN role r on pr.role_id = r.id
        WHERE lt.key = link_type_key_param
          AND pr.can_read = TRUE
          AND r.key = ANY(role_key_param);
END;
$BODY$;

ALTER FUNCTION link_get_link_type_attributes(character varying, character varying[])
   OWNER to interlink;

/*
  link_items: return all items that a role(s) can see
 */
CREATE OR REPLACE FUNCTION link_items(
    role_key_param character varying[]
)
    RETURNS TABLE(
         id bigint,
         key character varying,
         name character varying,
         description text,
         status smallint,
         item_type_key character varying,
         meta jsonb,
         meta_enc boolean,
         txt text,
         txt_enc boolean,
         enc_key_ix smallint,
         tag text[],
         attribute hstore,
         version bigint,
         created timestamp(6) with time zone,
         updated timestamp(6) with time zone,
         changed_by character varying,
         model_key character varying,
         partition_key character varying
     )
    LANGUAGE 'plpgsql'
    COST 100
    STABLE
AS $BODY$
BEGIN
    RETURN QUERY SELECT
         i.id,
         i.key,
         i.name,
         i.description,
         i.status,
         it.key as item_type_key,
         i.meta,
         i.meta_enc,
         i.txt,
         i.txt_enc,
         i.enc_key_ix,
         i.tag,
         i.attribute,
         i.version,
         i.created,
         i.updated,
         i.changed_by,
         m.key as model_key,
         p.key as partition_key
     FROM item i
      INNER JOIN item_type it ON i.item_type_id = it.id
      INNER JOIN model m ON m.id = it.model_id
      INNER JOIN partition p on i.partition_id = p.id
      INNER JOIN privilege pr on p.id = pr.partition_id
      INNER JOIN role r on pr.role_id = r.id
     WHERE pr.can_read = TRUE
       AND r.key = ANY(role_key_param);
END
$BODY$;

ALTER FUNCTION link_items(character varying[])OWNER to interlink;

END
$$;