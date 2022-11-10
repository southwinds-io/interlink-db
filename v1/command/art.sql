-- artisan flow model definition
INSERT INTO model(id, key, name, description, managed, changed_by, version)
VALUES (2, 'ART', 'ARTISAN MODEL', 'Configure Artisan automation', true, 'interlink', 1);

-- item types
INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change)
VALUES (100, 'ART_FLOW', 'ARTISAN FLOW', 'The definition of a sequence of steps executing Artisan functions.', 1, 'interlink', 2, 'N');

INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change, meta_schema)
VALUES (101, 'ART_FX', 'ARTISAN FUNCTION', 'The definition of a function in an Artisan package.', 1, 'interlink', 2, 'N',
'{
  "definitions": {},
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://example.com/object1625873455.json",
  "title": "Root",
  "type": "object",
  "required": [
  ],
  "properties": {
    "input": {
      "$id": "#root/input",
      "title": "Input",
      "type": "object",
      "required": [
      ],
      "properties": {
        "file": {
          "$id": "#root/input/file",
          "title": "File",
          "type": "array",
          "default": [],
          "items":{
            "$id": "#root/input/file/items",
            "title": "Items",
            "type": "object",
            "required": [
              "name",
              "description",
              "path"
            ],
            "properties": {
              "name": {
                "$id": "#root/input/file/items/name",
                "title": "Name",
                "type": "string",
                "default": "",
                "examples": [
                  "TEST_FILE"
                ],
                "pattern": "^.*$"
              },
              "description": {
                "$id": "#root/input/file/items/description",
                "title": "Description",
                "type": "string",
                "default": "",
                "examples": [
                  "my test file"
                ],
                "pattern": "^.*$"
              },
              "path": {
                "$id": "#root/input/file/items/path",
                "title": "Path",
                "type": "string",
                "default": "",
                "examples": [
                  "test.txt"
                ],
                "pattern": "^.*$"
              }
            }
          }

        },
        "var": {
          "$id": "#root/input/var",
          "title": "Var",
          "type": "array",
          "default": [],
          "items":{
            "$id": "#root/input/var/items",
            "title": "Items",
            "type": "object",
            "required": [
              "name",
              "required",
              "type",
              "description"
            ],
            "properties": {
              "name": {
                "$id": "#root/input/var/items/name",
                "title": "Name",
                "type": "string",
                "default": "",
                "examples": [
                  "GIT_URI"
                ],
                "pattern": "^.*$"
              },
              "required": {
                "$id": "#root/input/var/items/required",
                "title": "Required",
                "type": "boolean",
                "examples": [
                  true
                ],
                "default": true
              },
              "type": {
                "$id": "#root/input/var/items/type",
                "title": "Type",
                "type": "string",
                "default": "",
                "examples": [
                  "uri"
                ],
                "pattern": "^.*$"
              },
              "description": {
                "$id": "#root/input/var/items/description",
                "title": "Description",
                "type": "string",
                "default": "",
                "examples": [
                  "the URI of the project git repository. create empty git project and pass that uri here\neg. https://gitlab.com/<group-name>/<project-name>.git"
                ],
                "pattern": "^.*$"
              }
            }
          }

        },
        "secret": {
          "$id": "#root/input/secret",
          "title": "Secret",
          "type": "array",
          "default": [],
          "items":{
            "$id": "#root/input/secret/items",
            "title": "Items",
            "type": "object",
            "required": [
              "name",
              "description"
            ],
            "properties": {
              "name": {
                "$id": "#root/input/secret/items/name",
                "title": "Name",
                "type": "string",
                "default": "",
                "examples": [
                  "SONAR_TOKEN"
                ],
                "pattern": "^.*$"
              },
              "description": {
                "$id": "#root/input/secret/items/description",
                "title": "Description",
                "type": "string",
                "default": "",
                "examples": [
                  "the token to access the sonar server\nopen sonar dashboard -> click on My Account -> Security -> Genearte new token"
                ],
                "pattern": "^.*$"
              }
            }
          }

        },
        "key": {
          "$id": "#root/input/key",
          "title": "Key",
          "type": "array",
          "default": [],
          "items":{
            "$id": "#root/input/key/items",
            "title": "Items",
            "type": "object",
            "required": [
              "name",
              "description",
              "private",
              "path"
            ],
            "properties": {
              "name": {
                "$id": "#root/input/key/items/name",
                "title": "Name",
                "type": "string",
                "default": "",
                "examples": [
                  "SIGNING_KEY"
                ],
                "pattern": "^.*$"
              },
              "description": {
                "$id": "#root/input/key/items/description",
                "title": "Description",
                "type": "string",
                "default": "",
                "examples": [
                  "the private PGP key required to digitally sign the application package"
                ],
                "pattern": "^.*$"
              },
              "private": {
                "$id": "#root/input/key/items/private",
                "title": "Private",
                "type": "boolean",
                "examples": [
                  true
                ],
                "default": true
              },
              "path": {
                "$id": "#root/input/key/items/path",
                "title": "Path",
                "type": "string",
                "default": "",
                "examples": [
                  "/"
                ],
                "pattern": "^.*$"
              }
            }
          }

        }
      }
    }

  }
}');

INSERT INTO item_type(id, key, name, description, version, changed_by, model_id, notify_change, meta_schema)
VALUES (102, 'ART_SPEC_FX', 'ARTISAN SPEC FUNCTION', 'The definition of a function in an Artisan release specification.', 1, 'interlink', 2, 'T',
        '{
          "definitions": {},
          "$schema": "http://json-schema.org/draft-07/schema#",
          "$id": "https://example.com/object1625873455.json",
          "title": "Root",
          "type": "object",
          "required": [
          ],
          "properties": {
            "input": {
              "$id": "#root/input",
              "title": "Input",
              "type": "object",
              "required": [
              ],
              "properties": {
                "file": {
                  "$id": "#root/input/file",
                  "title": "File",
                  "type": "array",
                  "default": [],
                  "items":{
                    "$id": "#root/input/file/items",
                    "title": "Items",
                    "type": "object",
                    "required": [
                      "name",
                      "description",
                      "path"
                    ],
                    "properties": {
                      "name": {
                        "$id": "#root/input/file/items/name",
                        "title": "Name",
                        "type": "string",
                        "default": "",
                        "examples": [
                          "TEST_FILE"
                        ],
                        "pattern": "^.*$"
                      },
                      "description": {
                        "$id": "#root/input/file/items/description",
                        "title": "Description",
                        "type": "string",
                        "default": "",
                        "examples": [
                          "my test file"
                        ],
                        "pattern": "^.*$"
                      },
                      "path": {
                        "$id": "#root/input/file/items/path",
                        "title": "Path",
                        "type": "string",
                        "default": "",
                        "examples": [
                          "test.txt"
                        ],
                        "pattern": "^.*$"
                      }
                    }
                  }

                },
                "var": {
                  "$id": "#root/input/var",
                  "title": "Var",
                  "type": "array",
                  "default": [],
                  "items":{
                    "$id": "#root/input/var/items",
                    "title": "Items",
                    "type": "object",
                    "required": [
                      "name",
                      "required",
                      "type",
                      "description"
                    ],
                    "properties": {
                      "name": {
                        "$id": "#root/input/var/items/name",
                        "title": "Name",
                        "type": "string",
                        "default": "",
                        "examples": [
                          "GIT_URI"
                        ],
                        "pattern": "^.*$"
                      },
                      "required": {
                        "$id": "#root/input/var/items/required",
                        "title": "Required",
                        "type": "boolean",
                        "examples": [
                          true
                        ],
                        "default": true
                      },
                      "type": {
                        "$id": "#root/input/var/items/type",
                        "title": "Type",
                        "type": "string",
                        "default": "",
                        "examples": [
                          "uri"
                        ],
                        "pattern": "^.*$"
                      },
                      "description": {
                        "$id": "#root/input/var/items/description",
                        "title": "Description",
                        "type": "string",
                        "default": "",
                        "examples": [
                          "the URI of the project git repository. create empty git project and pass that uri here\neg. https://gitlab.com/<group-name>/<project-name>.git"
                        ],
                        "pattern": "^.*$"
                      }
                    }
                  }

                },
                "secret": {
                  "$id": "#root/input/secret",
                  "title": "Secret",
                  "type": "array",
                  "default": [],
                  "items":{
                    "$id": "#root/input/secret/items",
                    "title": "Items",
                    "type": "object",
                    "required": [
                      "name",
                      "description"
                    ],
                    "properties": {
                      "name": {
                        "$id": "#root/input/secret/items/name",
                        "title": "Name",
                        "type": "string",
                        "default": "",
                        "examples": [
                          "SONAR_TOKEN"
                        ],
                        "pattern": "^.*$"
                      },
                      "description": {
                        "$id": "#root/input/secret/items/description",
                        "title": "Description",
                        "type": "string",
                        "default": "",
                        "examples": [
                          "the token to access the sonar server\nopen sonar dashboard -> click on My Account -> Security -> Genearte new token"
                        ],
                        "pattern": "^.*$"
                      }
                    }
                  }

                },
                "key": {
                  "$id": "#root/input/key",
                  "title": "Key",
                  "type": "array",
                  "default": [],
                  "items":{
                    "$id": "#root/input/key/items",
                    "title": "Items",
                    "type": "object",
                    "required": [
                      "name",
                      "description",
                      "private",
                      "path"
                    ],
                    "properties": {
                      "name": {
                        "$id": "#root/input/key/items/name",
                        "title": "Name",
                        "type": "string",
                        "default": "",
                        "examples": [
                          "SIGNING_KEY"
                        ],
                        "pattern": "^.*$"
                      },
                      "description": {
                        "$id": "#root/input/key/items/description",
                        "title": "Description",
                        "type": "string",
                        "default": "",
                        "examples": [
                          "the private PGP key required to digitally sign the application package"
                        ],
                        "pattern": "^.*$"
                      },
                      "private": {
                        "$id": "#root/input/key/items/private",
                        "title": "Private",
                        "type": "boolean",
                        "examples": [
                          true
                        ],
                        "default": true
                      },
                      "path": {
                        "$id": "#root/input/key/items/path",
                        "title": "Path",
                        "type": "string",
                        "default": "",
                        "examples": [
                          "/"
                        ],
                        "pattern": "^.*$"
                      }
                    }
                  }

                }
              }
            }

          }
        }');

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('ART_FX_ATTR_PACKAGE', -- key
        'PACKAGE', -- name
        'The name of the artisan package holding the function to execute.', -- description
        'string', -- type
        true, -- required
        101, -- item_type_id (ART_FX)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('ART_FX_ATTR_FX', -- key
        'FX', -- name
        'The name of the function in the Artisan package that defines a specific API.', -- description
        'string', -- type
        true, -- required
        101, -- item_type_id (ART_FX)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('ART_FX_ATTR_USER', -- key
        'USER', -- name
        'The user name required to retrieve the package storing the Artisan registry.', -- description
        'string', -- type
        false, -- required
        101, -- item_type_id (ART_FX)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('ART_FX_ATTR_PWD', -- key
        'PWD', -- name
        'The password required to retrieve the package storing the Artisan registry.', -- description
        'string', -- type
        false, -- required
        101, -- item_type_id (ART_FX)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('ART_FX_ATTR_VERBOSE', -- key
        'VERBOSE', -- name
        'A flag indicating if the execution log should be verbose.', -- description
        'boolean', -- type
        false, -- required
        101, -- item_type_id (ART_FX)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('ART_FX_ATTR_CONTAINERISED', -- key
        'CONTAINERISED', -- name
        'A flag indicating if the execution should occur in a runtime container.', -- description
        'boolean', -- type
        false, -- required
        101, -- item_type_id (ART_FX)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('ART_SPEC_FX_ATTR_PACKAGE', -- key
        'PACKAGE', -- name
        'The name of the artisan package holding the function to execute.', -- description
        'string', -- type
        true, -- required
        102, -- item_type_id (ART_SPEC_FX)
        'interlink' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('ART_SPEC_FX_ATTR_FX', -- key
        'FX', -- name
        'The name of the function in the Artisan package that defines a specific API.', -- description
        'string', -- type
        true, -- required
        102, -- item_type_id (ART_FX)
        'onix' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('ART_SPEC_FX_ATTR_USER', -- key
        'USER', -- name
        'The user name required to retrieve the package storing the Artisan registry.', -- description
        'string', -- type
        false, -- required
        102, -- item_type_id (ART_FX)
        'onix' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('ART_SPEC_FX_ATTR_PWD', -- key
        'PWD', -- name
        'The password required to retrieve the package storing the Artisan registry.', -- description
        'string', -- type
        false, -- required
        102, -- item_type_id (ART_FX)
        'onix' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('ART_SPEC_FX_ATTR_VERBOSE', -- key
        'VERBOSE', -- name
        'A flag indicating if the execution log should be verbose.', -- description
        'boolean', -- type
        false, -- required
        102, -- item_type_id (ART_FX)
        'onix' -- changed_by
       );

INSERT INTO type_attribute(key, name, description, type, required, item_type_id, changed_by)
VALUES ('ART_SPEC_FX_ATTR_CONTAINERISED', -- key
        'CONTAINERISED', -- name
        'A flag indicating if the execution should occur in a runtime container.', -- description
        'boolean', -- type
        false, -- required
        102, -- item_type_id (ART_FX)
        'onix' -- changed_by
       );