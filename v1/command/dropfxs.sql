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
    DECLARE
        rec RECORD;
        DROP_STATEMENT VARCHAR(200);
    BEGIN
        -- drops all functions that start with the FX_PATTERN prefix
        FOR rec IN
            SELECT routines.routine_name as fx_name
            FROM information_schema.routines
            WHERE routines.specific_schema='public'
            AND routines.routine_name SIMILAR TO 'link_*'
            ORDER BY routines.routine_name
        LOOP
            DROP_STATEMENT = 'DROP FUNCTION IF EXISTS ' || rec.fx_name || ' CASCADE;';
            EXECUTE DROP_STATEMENT;
        END LOOP;
    END;
$$