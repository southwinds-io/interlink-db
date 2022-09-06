-- universal model definition
INSERT INTO model(id, key, name, description, managed, changed_by, version)
VALUES (1, 'U', 'UNIVERSAL MODEL', 'Generic model to capture and IT landscape', true, 'interlink', 1);

-- item types
INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change)
VALUES (1, 'U_PLATFORM', 'PLATFORM', 'A container or virtual machine platform', 1, 'interlink', 1, 'N');

INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change)
VALUES (2, 'U_ZONE', 'ZONE',
        'A collection of one or more network segments requiring the regulation of inbound and outbound traffic through policies',
        1, 'interlink', 1, 'N');

INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change)
VALUES (3, 'U_HOST', 'HOST', 'A a computer or other device connected to a computer network', 1, 'interlink', 1, 'N');

INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change, encrypt_txt)
VALUES (4, 'U_APPLICATION', 'APPLICATION', 'The logical representation of a computer software', 1, 'interlink', 1, 'I',
        true);

INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change)
VALUES (5, 'U_WORKLOAD', 'WORKLOAD',
        'A process running on a the platform, which represents an instance of an application', 1, 'interlink', 1, 'N');

INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change)
VALUES (6, 'U_ENVIRONMENT', 'ENVIRONMENT', 'A logical group of applications and their underlying IT infrastructure', 1,
        'interlink', 1, 'N');

INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change)
VALUES (7, 'U_ORG_GROUP', 'ORGANIZATION GROUP', 'A group of organisations or a parent organisation.', 1, 'interlink', 1, 'N');

INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change)
VALUES (8, 'U_ORG', 'ORGANIZATION', 'A specific organisation.', 1, 'interlink', 1, 'N');

INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change)
VALUES (9, 'U_AREA', 'AREA', 'An area, either geographical or organisational, within which a host can exist.', 1, 'interlink', 1, 'N');

INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change)
VALUES (10, 'U_LOCATION', 'LOCATION', 'A specific location, either physical or logical, that is in an area where a host is deployed.', 1, 'interlink', 1, 'N');

-- dictionary item for storing encrypted properties using key-value pair json schema validation
INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change, encrypt_meta, meta_schema)
VALUES (11, 'U_DICTIONARY', 'DICTIONARY', 'A list of key value pairs storing a set of variables for a particular purpose.', 1, 'interlink', 1, 'N', true,
'{
  "title": "Force every property to have a string value",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "additionalProperties": {"type": "string"}
}');

INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change, encrypt_meta)
VALUES (12, 'U_CATALOGUE', 'CATALOGUE', 'A catalogue item representing an artisan release specification', 1, 'interlink', 1, 'N', false);

-- link types
INSERT INTO link_type(id, key, name, description, version, changed_by, model_id)
VALUES (1, 'U_RELATIONSHIP', 'U Model Relation Link', 'Connects items in the U model defining their relations.', 1,
        'interlink', 1);

INSERT INTO link_type(id, key, name, description, version, changed_by, model_id)
VALUES (2, 'U_DEPENDENCY', 'U Model Dependency Link', 'Define runtime dependencies between items in the model.', 1,
        'interlink', 1);

-- link rules
INSERT INTO link_rule(id, key, name, description, link_type_id, start_item_type_id, end_item_type_id, version,
                      changed_by)
VALUES (1, 'U_PLATFORM_TO_ZONE', 'Platform -> Zone Rule', 'Connects Platforms with Zones', 1, 1, 2, 1, 'interlink');

INSERT INTO link_rule(id, key, name, description, link_type_id, start_item_type_id, end_item_type_id, version,
                      changed_by)
VALUES (2, 'U_ZONE_TO_HOST', 'Zone -> Host Rule', 'Connects Zones with Hosts', 1, 2, 3, 1, 'interlink');

-- Workload -> Host
INSERT INTO link_rule(id, key, name, description, link_type_id, start_item_type_id, end_item_type_id, version,
                      changed_by)
VALUES (3, 'U_HOST_TO_WORKLOAD', 'Host -> Workload Rule', 'Connects Hosts with Application Workloads', 1, 3, 5, 1,
        'interlink');

-- App -> Workload
INSERT INTO link_rule(id, key, name, description, link_type_id, start_item_type_id, end_item_type_id, version,
                      changed_by)
VALUES (4, 'U_APP_TO_WORKLOAD', 'App -> Workload Rule', 'Connects Applications with their Workloads', 1, 4, 5, 1,
        'interlink');

-- Environment -> App
INSERT INTO link_rule(id, key, name, description, link_type_id, start_item_type_id, end_item_type_id, version,
                      changed_by)
VALUES (5, 'U_ENVIRONMENT_TO_APP', 'Environment -> App Rule',
        'Connects Environments to the Applications running on them', 1, 6, 4, 1, 'interlink');

-- Org Group -> Org
INSERT INTO link_rule(id, key, name, description, link_type_id, start_item_type_id, end_item_type_id, version,
                      changed_by)
VALUES (6, 'U_ORG_GROUP_TO_ORG', 'Organization Group -> Group Rule',
        'Connects Organizations to the Areas they comprise.', 1, 7, 8, 1, 'interlink');

-- Org Group -> Area
INSERT INTO link_rule(id, key, name, description, link_type_id, start_item_type_id, end_item_type_id, version,
                      changed_by)
VALUES (7, 'U_ORG_GROUP_TO_AREA', 'Organization Group -> Area Rule',
        'Connects Organization Groups to the areas under which they operate.', 1, 7, 9, 1, 'interlink');

-- Area -> Location
INSERT INTO link_rule(id, key, name, description, link_type_id, start_item_type_id, end_item_type_id, version,
                      changed_by)
VALUES (8, 'U_AREA_TO_LOCATION', 'Area -> Location Rule',
        'Connects an area to a location within it.', 1, 9, 10, 1, 'interlink');

-- Org -> Location
INSERT INTO link_rule(id, key, name, description, link_type_id, start_item_type_id, end_item_type_id, version,
                      changed_by)
VALUES (9, 'U_ORG_TO_LOCATION', 'Organisation -> Location Rule',
        'Connects an organisation to a location within it.', 1, 8, 10, 1, 'interlink');

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('U_HOST_ATTR_OS', -- key
        'OS', -- name
        'The operating system installed in the host', -- description
        'string', -- type
        true, -- required
        3, -- item_type_id (U_HOST)
        'interlink' -- changed_by
       );

-- U_HOST type attributes
INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('U_HOST_ATTR_CPU', -- key
        'CPU', -- name
        'The number of CPUs installed in the host', -- description
        'int', -- type
        true, -- required
        3, -- item_type_id (U_HOST)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('U_HOST_ATTR_MEMORY', -- key
        'MEMORY', -- name
        'The total memory installed in the host in Gb', -- description
        'int', -- type
        true, -- required
        3, -- item_type_id (U_HOST)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('U_HOST_ATTR_PLATFORM', -- key
        'PLATFORM', -- name
        'The host platform', -- description
        'string', -- type
        true, -- required
        3, -- item_type_id (U_HOST)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('U_HOST_ATTR_VIRTUAL', -- key
        'VIRTUAL', -- name
        'Is the host virtual or physical?', -- description
        'bool', -- type
        true, -- required
        3, -- item_type_id (U_HOST)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('U_HOST_ATTR_IP', -- key
        'IP', -- name
        'The host IP address', -- description
        'string', -- type
        true, -- required
        3, -- item_type_id (U_HOST)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('U_HOST_ATTR_MACHINE_ID', -- key
        'MACHINE-ID', -- name
        'The host machine Id', -- description
        'string', -- type
        true, -- required
        3, -- item_type_id (U_HOST)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('U_HOST_ATTR_HOSTNAME', -- key
        'HOSTNAME', -- name
        'The host name', -- description
        'string', -- type
        true, -- required
        3, -- item_type_id (U_HOST)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('U_CATALOGUE_ATTR_VERSION', -- key
        'VERSION', -- name
        'The version of the release.', -- description
        'string', -- type
        true, -- required
        12, -- item_type_id (U_CATALOGUE)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('U_CATALOGUE_ATTR_LICENSE', -- key
        'LICENSE', -- name
        'The license of the release.', -- description
        'string', -- type
        false, -- required
        12, -- item_type_id (U_CATALOGUE)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('U_CATALOGUE_ATTR_AUTHOR', -- key
        'AUTHOR', -- name
        'The author of the release.', -- description
        'string', -- type
        false, -- required
        12, -- item_type_id (U_CATALOGUE)
        'interlink' -- changed_by
       );