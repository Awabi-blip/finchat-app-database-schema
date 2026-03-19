CREATE OR REPLACE FUNCTION get_user_servers(f_user_id INT)
RETURNS TABLE (
    servers_name VARCHAR(24),
    role_in_server role_name,
    permissions TEXT[]
)
AS $$
BEGIN
    RETURN QUERY
    SELECT servers.display_name as server_name, roles.name as role_name, roles.permissions FROM users
    JOIN users_in_servers ON users.id = users_in_servers.user_id
    JOIN servers ON servers.id = users_in_servers.server_id
    JOIN roles ON roles.id = users_in_servers.role_id
    WHERE users_in_servers.user_id = f_user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_server_members(f_server_id INT)
RETURNS TABLE(
    user_id INT,
    username VARCHAR(24),
    has_role role_name
)
AS $$
BEGIN
    RETURN QUERY
    SELECT  users_in_servers.user_id, users.username, roles.name
    FROM users
    JOIN users_in_servers
    ON users.id = users_in_servers.user_id
    JOIN roles
    ON users_in_servers.role_id = roles.id
    WHERE users_in_servers.server_id = f_server_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION find_deleted_message(
f_message_id INT,
f_deleter_id INT,
f_server_id INT,
OUT o_deleted_of_id INT
)
AS $$
DECLARE
    v_role_check role_name;
    v_deleted_of_id INT;
BEGIN
    v_role_check := (SELECT roles.name FROM roles JOIN
                    users_in_servers ON roles.id = users_in_servers.role_id
                    WHERE users_in_servers.user_id = f_deleter_id
                    AND users_in_servers.server_id = f_server_id
                    );

    v_deleted_of_id := (SELECT user_id FROM messages_in_servers WHERE id = f_message_id);

    IF v_role_check = 'Muted' THEN
            RAISE EXCEPTION 'muted';
    ELSEIF v_role_check =  'Member' AND f_deleter_id <> v_deleted_of_id THEN
            RAISE EXCEPTION 'cant delete';
    END IF;
    o_deleted_of_id := v_deleted_of_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE delete_messages(p_message_id INT, p_deleter_id INT, p_server_id INT)
AS $$
DECLARE
    v_deleted_of_id INT;
BEGIN
    SELECT o_deleted_of_id INTO v_deleted_of_id
    FROM find_deleted_message(p_message_id, p_deleter_id, p_server_id);

    UPDATE messages_in_servers
    SET is_deleted = TRUE
    WHERE id = p_message_id;

    INSERT INTO audit_logs
    (deleted_of_id, deleted_by_id, message_id, server_id)
    VALUES
    (v_deleted_of_id, p_deleter_id, p_message_id, p_server_id);

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION "show_audit_logs"(f_server_id INT)
RETURNS TABLE(
victim VARCHAR(24),
deleter VARCHAR(24),
message_deleted VARCHAR(2000)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
    victim.username AS "vic",
    deleter.username AS "del",
    messages_in_servers.message
    FROM audit_logs
    JOIN messages_in_servers
        ON audit_logs.message_id = messages_in_servers.id
    JOIN users AS deleter
        ON audit_logs.deleted_by_id = deleter.id
    JOIN users AS victim
        ON audit_logs.deleted_of_id = victim.id
    WHERE messages_in_servers.server_id = f_server_id
;
END;
$$ LANGUAGE plpgsql;


-- Learned: Procedures maintain scope. Don't return inputs.
-- Previously i was returning the same inputs to outputs without any change
-- That was a problem because the arguments that already were passed into the main procedure,
-- I was just getting them back again for no reason, which was an issue, so I fixed that.

