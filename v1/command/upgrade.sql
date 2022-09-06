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
/*
   Upgrade from database version 3 to 4
 */
DO
$$
    BEGIN
        -- disable all triggers
        SET session_replication_role = replica;

        CREATE SEQUENCE membership_id_seq
            START WITH 10
            INCREMENT BY 1
            NO MAXVALUE
            MINVALUE 10
            CACHE 1;

        CREATE SEQUENCE type_attribute_id_seq
            START WITH 1
            INCREMENT BY 1
            NO MAXVALUE
            NO MINVALUE
            CACHE 1;

        CREATE SEQUENCE user_id_seq
            START WITH 100
            INCREMENT BY 1
            NO MAXVALUE
            MINVALUE 100
            CACHE 1;

        CREATE TABLE "user" (
            id         BIGINT                 NOT NULL DEFAULT nextval('user_id_seq'::regclass),
            key        CHARACTER VARYING(100) NOT NULL,
            name       CHARACTER VARYING(200) NOT NULL,
            email      CHARACTER VARYING(200),
            pwd        CHARACTER VARYING(300),
            salt       CHARACTER VARYING(300),
            expires    TIMESTAMP(6) WITH TIME ZONE,
            service    BOOLEAN                         DEFAULT FALSE,
            -- an access control list for UI or API operations following the syntax
            -- realm:uri:method, realm:uri:method, ... => my-app:/items/*/data:GET, ..., ...
            acl        TEXT,
            version    BIGINT                 NOT NULL DEFAULT 1,
            created    TIMESTAMP(6) WITH TIME ZONE     DEFAULT CURRENT_TIMESTAMP(6),
            updated    TIMESTAMP(6) WITH TIME ZONE     DEFAULT CURRENT_TIMESTAMP(6),
            changed_by CHARACTER VARYING(100) NOT NULL
        );

        -- generic users - should change passwords after first login
        INSERT INTO "user"(id, key, name, email, pwd, salt, version, changed_by)
        VALUES (1, 'admin', 'Administrator', 'admin@ilink.com', 'E2BgmQs4vH4rYvj5Fe0p9DbZUKU=', '8DZMiAR+XGA=', 1, 'ilink');
        INSERT INTO "user"(id, key, name, email, pwd, salt, version, changed_by)
        VALUES (2, 'reader', 'Reader', 'reader@ilink.com', '/EvDpP8kHkfd30mXk+Ne9aA4h5o=', 'B0zo+y0Keiw=', 1, 'ilink');
        INSERT INTO "user"(id, key, name, email, pwd, salt, version, changed_by)
        VALUES (3, 'writer', 'Writer', 'writer@ilink.com', 'DkV3uMWjAjHSTZnW9TkJNI6XOzU=', 'yWJm38+RPtc=', 1, 'ilink');

        CREATE TABLE user_change (
             "operation" character(1) NOT NULL,
             changed timestamp without time zone NOT NULL,
             id         BIGINT,
             key        CHARACTER VARYING(100),
             name       CHARACTER VARYING(200),
             email      CHARACTER VARYING(200),
             pwd        CHARACTER VARYING(300),
             salt       CHARACTER VARYING(300),
             expires    TIMESTAMP(6) WITH TIME ZONE,
             service    BOOLEAN,
             -- an access control list for UI or API operations following the syntax
             -- realm:uri:method, realm:uri:method, ... => my-app:/items/*/data:GET, ..., ...
             acl        TEXT,
             version    BIGINT,
             created    TIMESTAMP(6) WITH TIME ZONE,
             updated    TIMESTAMP(6) WITH TIME ZONE,
             changed_by CHARACTER VARYING(100) NOT NULL
        );

        CREATE TABLE membership (
            id bigint DEFAULT nextval('public.membership_id_seq'::regclass) NOT NULL,
            "key" character varying(100) NOT NULL,
            user_id bigint NOT NULL,
            role_id bigint NOT NULL,
            version bigint,
            created timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP(6),
            updated timestamp(6) with time zone,
            changed_by character varying(100) NOT NULL
        );

        INSERT INTO membership(id, key, user_id, role_id, changed_by, version)
        VALUES (1, 'ADMIN-MEMBER', 1, 1, 'interlink', 1);
        INSERT INTO membership(id, key, user_id, role_id, changed_by, version)
        VALUES (1, 'READER-MEMBER', 2, 2, 'interlink', 1);
        INSERT INTO membership(id, key, user_id, role_id, changed_by, version)
        VALUES (1, 'WRITER-MEMBER', 3, 3, 'interlink', 1);

        CREATE TABLE membership_change (
            "operation" character(1) NOT NULL,
            changed timestamp without time zone NOT NULL,
            id integer NOT NULL,
            "key" character varying(100),
            user_id bigint,
            role_id bigint,
            version bigint,
            created timestamp(6) with time zone,
            updated timestamp(6) with time zone,
            changed_by character varying(100)
        );

        CREATE TABLE type_attribute (
            id integer DEFAULT nextval('public.type_attribute_id_seq'::regclass) NOT NULL,
            "key" character varying(100) NOT NULL,
            name character varying(200),
            description text,
            type character varying(100) NOT NULL,
            def_value character varying(200),
            required boolean DEFAULT false NOT NULL,
            regex character varying(300),
            item_type_id integer,
            link_type_id integer,
            version bigint DEFAULT 1 NOT NULL,
            created timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP(6),
            updated timestamp(6) with time zone,
            changed_by character varying(100) NOT NULL
        );

        CREATE TABLE type_attribute_change (
            "operation" character(1) NOT NULL,
            changed timestamp(6) with time zone NOT NULL,
            id integer NOT NULL,
            "key" character varying(100) NOT NULL,
            name character varying(200),
            description text,
            type character varying(100) NOT NULL,
            def_value character varying(300),
            required boolean DEFAULT false NOT NULL,
            regex character varying(300),
            item_type_id integer,
            link_type_id integer,
            version bigint DEFAULT 1 NOT NULL,
            created timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP(6),
            updated timestamp(6) with time zone,
            changed_by character varying(100) NOT NULL
        );

        ALTER TABLE item
            ADD COLUMN meta_enc boolean,
            ADD COLUMN txt text,
            ADD COLUMN txt_enc boolean,
            ADD COLUMN enc_key_ix smallint;

        ALTER TABLE item_change
            ADD COLUMN meta_enc boolean,
            ADD COLUMN txt text,
            ADD COLUMN txt_enc boolean,
            ADD COLUMN enc_key_ix smallint;

        ALTER TABLE item_type
            DROP COLUMN attr_valid,
            ADD COLUMN notify_change character(1) DEFAULT 'N'::bpchar NOT NULL,
            ADD COLUMN tag text[],
            ADD COLUMN encrypt_meta boolean DEFAULT false NOT NULL,
            ADD COLUMN encrypt_txt boolean DEFAULT false NOT NULL,
            ADD COLUMN style jsonb;

        ALTER TABLE item_type_change
            DROP COLUMN attr_valid,
            ADD COLUMN notify_change character(1),
            ADD COLUMN tag text[],
            ADD COLUMN encrypt_meta boolean,
            ADD COLUMN encrypt_txt boolean,
            ADD COLUMN style jsonb;

        ALTER TABLE link
            ADD COLUMN meta_enc boolean DEFAULT false NOT NULL,
            ADD COLUMN txt text,
            ADD COLUMN txt_enc boolean DEFAULT false NOT NULL,
            ADD COLUMN enc_key_ix smallint;

        ALTER TABLE link_change
            ADD COLUMN meta_enc boolean,
            ADD COLUMN txt text,
            ADD COLUMN txt_enc boolean,
            ADD COLUMN enc_key_ix smallint;

        ALTER TABLE link_type
            DROP COLUMN attr_valid,
            ADD COLUMN tag text[],
            ADD COLUMN encrypt_meta boolean DEFAULT false NOT NULL,
            ADD COLUMN encrypt_txt boolean DEFAULT false NOT NULL,
            ADD COLUMN style jsonb;

        ALTER TABLE link_type_change
            DROP COLUMN attr_valid,
            ADD COLUMN tag text[],
            ADD COLUMN encrypt_meta boolean,
            ADD COLUMN encrypt_txt boolean,
            ADD COLUMN style jsonb;

        ALTER TABLE model
            ADD COLUMN managed boolean DEFAULT false NOT NULL;

        ALTER TABLE model_change
            ADD COLUMN managed boolean;

        ALTER TABLE privilege
            ADD COLUMN "key" character varying(100),
            ADD COLUMN version bigint,
            ADD COLUMN updated timestamp(6) with time zone,
            ADD CONSTRAINT privilege_key_uc UNIQUE (key);

        -- populate auto-generated key and version
        UPDATE privilege
        SET key=sub.key, version=sub.version
        FROM (SELECT id, 'P_' || id AS key, 1 AS version FROM privilege) AS sub
        WHERE sub.id = privilege.id;

        -- set key to NOT NULL
        ALTER TABLE privilege
            ALTER COLUMN key SET NOT NULL;

        ALTER TABLE privilege_change
            ADD COLUMN "key" character varying(100),
            ADD COLUMN version bigint,
            ADD COLUMN updated timestamp(6) with time zone;

        -- populate auto-generated key and version
        UPDATE privilege_change
        SET key=sub.key, version=sub.version
        FROM (SELECT id, 'P_' || id AS key, 1 AS version FROM privilege_change) AS sub
        WHERE sub.id = privilege_change.id;

        ALTER TABLE membership
            ADD CONSTRAINT membership_id_pk PRIMARY KEY (id, user_id, role_id);

        ALTER TABLE "user"
            ADD CONSTRAINT user_id_pk PRIMARY KEY (id);

        ALTER TABLE item_type
            ADD CONSTRAINT item_type_notify_change_check CHECK ((notify_change = ANY (ARRAY['N'::bpchar, 'T'::bpchar, 'I'::bpchar])));

        ALTER TABLE membership
            ADD CONSTRAINT membership_role_id_fk FOREIGN KEY (role_id) REFERENCES public.role(id) ON DELETE CASCADE;

        ALTER TABLE membership
            ADD CONSTRAINT membership_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;

        ALTER TABLE type_attribute
            ADD CONSTRAINT item_type_attribute_id_fk FOREIGN KEY (item_type_id) REFERENCES public.item_type(id) ON DELETE CASCADE;

        ALTER TABLE type_attribute
            ADD CONSTRAINT link_type_attribute_id_fk FOREIGN KEY (link_type_id) REFERENCES public.link_type(id) ON DELETE CASCADE;

        ALTER TABLE "user"
            ADD CONSTRAINT valid_email CHECK (((email)::text ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'::text));

        ALTER TABLE "user"
            ADD CONSTRAINT user_email_uc UNIQUE (email);

        ALTER TABLE "user"
            ADD CONSTRAINT user_key_uc UNIQUE (key);

        ALTER TABLE "user"
            ADD CONSTRAINT user_name_uc UNIQUE (name);

        CREATE INDEX item_type_tag_ix ON item_type USING gin (tag);

        CREATE INDEX link_type_tag_ix ON link_type USING gin (tag);

        CREATE INDEX fki_type_attribute_item_type_id_fk ON type_attribute USING btree (item_type_id);

        CREATE INDEX fki_type_attribute_link_type_id_fk ON type_attribute USING btree (link_type_id);

        -- enable all triggers
        SET session_replication_role = default;
    END;
$$
